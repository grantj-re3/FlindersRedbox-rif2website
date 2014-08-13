#--
# Copyright (c) 2013-2014, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 

# Load standard library files
require 'logger'
require 'rexml/document'
require 'rexml/xpath'
require 'cgi'

# Load application library files
require 'htmlhelper'
require 'inwebpage'
require 'object_extra'

##############################################################################
# This class creates an object from a RIF-CS record-type and record (ie. XML
# document) and applies rules to transform the information into html
# content. The html content can then be substituted into an html-template
# and written to a file. The rules, template file and destination file
# characteristics (root directory and file extension) are configurable.
# The destination file basename is not configurable but is derived from
# the RIF-CS record key. Eg. If the key is a handle, it will use the 
# handle redirection URL basename (eg. ReDBox or Mint OID) as the destination
# file basename. 
class OutWebPage
  HTML_REPLACEMENT_TAG_REGEX1 = "<!-- \[\["
  HTML_REPLACEMENT_TAG_REGEX2 = "\]\] -->"
  HTML_LINES_INDENT = "\t" * 8

  # XPaths given in the configuration may contain this tag. Before
  # such XPaths are processed, this string will be replaced with the
  # primary record-type of the RIF-CS record ie. 'party', 'activity',
  # 'service' or 'collection'.
  XPATH_PRIMARY_RECORD_TYPE_TAG = '[[PRIMARY_RECORD_TYPE_TAG]]'

  # A special record-type used by this program to identify RIF-CS records which
  # have been deleted (as indicated in the OAI-PMH <header>). Unlike other
  # record-types, this one never appears in the RIF-CS record (since the
  # <metadata> section containing the RIF-CS information will no longer exist).
  REC_TYPE_DELETED = 'any,deleted'

  # Hash of RIF-CS record types (or primary types represented by hash
  # keys) & subtypes (or secondary types represented by hash values
  # ie. arrays)
  CAP_RIF_RECORD_TYPES2 = {
    'Activity' =>
      %w(Award Course Event Program Project),
    'Collection' =>
      %w(CatalogueOrIndex Collection Dataset Registry Repository),
    'Party' =>
      %w(AdministrativePosition Group Person),
    'Service' =>
      %w(Annotate Assemble Create Generate Report Transform 
      Harvest-oaipmh Search-http Search-opensearch Search-sru Search-srw
      Search-z3950 Syndicate-atom Syndicate-rss),
    REC_TYPE_DELETED.split(',')[0].capitalize =>
      REC_TYPE_DELETED.split(',')[1].capitalize
  }

  # List of RIF-CS record types
  CAP_RIF_RECORD_TYPES = CAP_RIF_RECORD_TYPES2.keys.sort

  # List of valid rulenames (for hashes).
  # Will we ever have a hyphen in Mint Service subtype? If so, the
  # hash name for the rules should have an underscore instead of the
  # hyphen. eg. ServiceHarvest_oaipmhRules
  VALID_RULENAMES = CAP_RIF_RECORD_TYPES2.inject([]){|accum,(t1,subtypes)|
    subtypes.each{|t2| accum << "#{t1}#{t2}Rules".gsub('-', '_')}
    accum
  }.sort

  # If any strings in the array LABELS_TO_HIGHLIGHT match labels given in
  # the config file, all text in the corresponding output html-table-row
  # shall be highlighted. Html highlighting shall be performed with the
  # html tags (written as ruby symbols) listed in HTML_HIGHLIGHTING_TAGS.
  LABELS_TO_HIGHLIGHT = [ 'Name', ]
  HTML_HIGHLIGHTING_TAGS = [:strong, :em]

  VALID_RECORD_TYPE_CONVERSIONS = [:none, :hyphen2underscore, :underscore2hyphen]

##############################################################################
  @@object_count = 0
  @@record_types_with_rules = nil  # Do not access directly, except within record_types_with_rulesets()
  @@repo_name = nil			# 'redbox' or 'mint' or nil

  attr_reader :out_file_path

  # Create an OutWebPage object. If processing rules have been defined for
  # this record-type, then:
  # * determine the destination file path
  # * process the record according to the rules
  # otherwise return with @rec_type = nil
  # * Argument _rec_type_: One of the record types defined in
  #   CAP_RIF_RECORD_TYPES2 & for which rules have been defined in 
  #   appropriately named nested arrays. (eg. rec_type of 
  #   "collection,dataset", "party,person", "activity,project" & "any,deleted"
  #   would require corresponding arrays of CollectionDatasetRules, 
  #   PartyPersonRules, ActivityProjectRules & AnyDeletedRules)
  # * Argument _doc_: An object of class REXML::Document with an XPath of
  #   ListRecords/record/metadata/registryObjects within the OAI-PMH feed
  def initialize(rec_type, doc)
    unless rec_type
      # Invalid or dummy rec_type. We will not bother to increment @@object_count.
      @rec_type = nil
      return
    end

    @@object_count += 1
    if self.class.record_types_with_rulesets.include?(rec_type)
      $LOG.info "[#{@@object_count}] RIF-CS record '#{rec_type}' -- processing"
      @rec_type = rec_type
    else
      $LOG.warn "[#{@@object_count}] RIF-CS record '#{rec_type}' -- bypass processing (no rules found)"
      @rec_type = nil
      return
    end
    @doc = doc
    @repo_oid_cached = nil	# Cached ReDBox-Mint OID. Only use in repo_oid()
    @is_repo_oid_calc = false	# Is @repo_oid_cached calculated yet? Only use in repo_oid()

    @out_file_path = output_file_path
    return unless @out_file_path

    # Process elements of this record to create lines (for writing to a web page)
    @lines = {}
    process_record
  end

  # Is this object valid?
  def valid?
    @rec_type != nil
  end

  # Return @rec_type in different string formats. The first argument
  # specifies the string separator between items. The optional second
  # argument specifies whether to capitalize the first letter of each item
  # (default is to leave as lower case). Eg. For @rec_type = "party,person"
  # * rec_type_str('-') returns "party-person"
  # * rec_type_str('', true) returns "PartyPerson"
  def rec_type_str(separator, is_cap=nil, convert=:none)
    unless VALID_RECORD_TYPE_CONVERSIONS.include?(convert)
      STDERR.puts "ERROR: Invalid conversion type '#{convert}' in method #{__method__}"
      exit 2
    end
    rec_types = @rec_type.split(',')
    rec_types.each{|w| w.upcase_chars!} if is_cap

    case convert
    when :hyphen2underscore
      rec_types.each{|w| w.gsub!('-', '_')}
    when :underscore2hyphen
      rec_types.each{|w| w.gsub!('_', '-')}
    end
    rec_types.join(separator)
  end

  # Return a record description string based on @rec_type. The first argument
  # specifies the string separator between items. The optional second
  # argument specifies whether to capitalize the first letter of each item
  # (default is to leave as lower case).
  def rec_description_str(separator, is_cap=nil)
    if @rec_type == REC_TYPE_DELETED
      if @@repo_name == 'redbox'
        "This record is no longer active and the dataset is no longer available"
      else
        "This record is no longer active"
      end
    else
      rec_type_str(separator, is_cap)
    end
  end

  # Find any primary record-type tags in the specified XPath
  # (eg. "registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/..."
  # from a rule) and replace them with the primary record-type of the
  # RIF-CS record ie. 'party', 'activity', 'service' or 'collection'.
  # * Argument _xpath_str_: The XPath string potentially containing
  #   primary record-type tags
  def to_s_with_primary_record_type(xpath_str)
    primary_rec_type, secondary_rec_type = @rec_type.split(',')
    xpath_str.gsub(XPATH_PRIMARY_RECORD_TYPE_TAG, primary_rec_type)
  end

  # Assign a repository name (ie. 'redbox' or 'mint')
  # * Argument _repo_name_: The <em>repository name</em> string
  def self.repo_name=(repo_name)
    @@repo_name = repo_name
  end

  # Builds an array of record-type strings from '*Rules' arrays which
  # exist (and which are expected to be in etc/rules*.rb files).
  # Elements of this array can be directly compared with @rec_type.
  # Eg. Will return
  # * ["collection,catalogueOrIndex", "collection,dataset"]
  # if the following rules (ie. non-empty array of arrays) exist:
  # * CollectionCatalogueOrIndexRules
  # * CollectionDatasetRules
  def self.record_types_with_rulesets
    return @@record_types_with_rules if @@record_types_with_rules  # Return cached result

    @@record_types_with_rules = []

    Module.constants.each{|cname|
      if VALID_RULENAMES.include?(cname)  # Security check for eval()
        rules = eval(cname)
        if rules.class == Array && !rules.empty? && rules.first.class == Array && !rules.first.empty?
          # This seems to be a non-empty array of arrays with const name Type1Type2Rules where:
          # * Type1 is in CAP_RIF_RECORD_TYPES
          # * Type2 is yet to be determined (RIF-CS subtype is expected)
          # * Rules is the text 'Rules'
          # Hence, lets assume it contains a set of RIF-CS record processing-rules
          $LOG.debug "RIF-CS processing rules assumed in array #{cname}"
          CAP_RIF_RECORD_TYPES.each{|type1|
            if cname.match(/^#{type1}/)
              type2 = cname.sub(/^#{type1}(.+)Rules$/, '\1')
              @@record_types_with_rules << "#{type1.downcase_chars},#{type2.downcase_chars.gsub('_', '-')}"
            end
          }
        end
      end
    }
    @@record_types_with_rules.sort!
    $LOG.info "Rules are defined for RIF-CS record types: #{@@record_types_with_rules.inspect}"
    @@record_types_with_rules
  end

  # Action methods (which are invoked via rules) are methods in this class with
  # names conforming to one of the following patterns:
  # * "show*"
  # Returns a sorted array of all such action methods
  def action_methods
    actions = methods.inject([]){|a,m| a << m if m.match(/^show\w+$/); a}
    actions.sort!
  end

  # Iterate through the processing rules; for each rule, invoke the method specified by 'action'
  def process_record
    rules_str = "#{rec_type_str('', true, :hyphen2underscore)}Rules"
    # Security check for eval() on @rec_type already done for this object
    rules = eval(rules_str)  # Eg. PartyPersonConfig or CollectionDatasetConfig
    rules.each{|order, action, label, xpath|
      xpath_with_replacement = to_s_with_primary_record_type(xpath)
      begin
        @lines[order] = self.send(action, order, action, label, xpath_with_replacement)
      rescue NoMethodError => ex
        $LOG.fatal "Problem during execution of #{self.class}.#{__method__}() or child! @rec_type=#{@rec_type};"
        $LOG.fatal "  order=#{order}; action=#{action}; label=#{label}; xpath=#{xpath_with_replacement}"
        $LOG.fatal "#{ex}"
        exit 1
      end
    }
  end

  # Determine the destination file path based on the ReDBox-Mint OID and
  # Config[] parameters. This is the path to an individual web page
  # for a single ReDBox-Mint RIF-CS record.
  def output_file_path
    repo_oid ? "#{Config[:dest_root_dir]}/#{repo_oid}#{Config[:dest_filename_suffix]}" : nil

  end

  # Return the destination summary-file path based on Config[] parameters.
  # Eg. /vrtualhost/web/path/index.html. The summary-file is a web page
  # which contains links to other web pages created by this program.
  def self.output_summary_file_path
    "#{Config[:dest_root_dir]}/#{Config[:dest_summary_filename_prefix]}#{Config[:dest_filename_suffix]}" 
  end

  # Determine the ReDBox-Mint OID based on the RIF-CS key
  def repo_oid
    return @repo_oid_cached if @is_repo_oid_calc

    # Determine the ReDBox-Mint OID
    rec_key = nil
    xpath_sym = @rec_type == REC_TYPE_DELETED ? :xpath_header_id_del : :xpath_key
    @doc.elements.each(Config[xpath_sym].to_s_xpath){|e| rec_key = e.text}
    unless rec_key
      $LOG.warn "No key found for record #{@rec_type}; cannot determine OID for this record"
      return nil
    end
    $LOG.info "Record key is #{rec_key}"

    is_handle = rec_key.match('^http://hdl.handle.net/.+/.+')
    is_url = rec_key.match('^http://.+/.+/.+')
    if is_handle
      hdl_page = InWebPage.new(rec_key)
      if hdl_page.http_redirect?
        oid = hdl_page.redirect_location
      else
        $LOG.warn "Handle #{rec_key} does not redirect to a URI; cannot determine OID for this record"
        @is_repo_oid_calc = true
        @repo_oid_cached = nil
        return @repo_oid_cached
      end
    elsif is_url
      oid = rec_key
    else
      $LOG.warn "Key #{rec_key} is not a URI; cannot write this record"
      @is_repo_oid_calc = true
      @repo_oid_cached = nil
      return @repo_oid_cached
    end
    oid.gsub!(/^.*\//, '').gsub!(/\..*$/, '')
    @is_repo_oid_calc = true
    @repo_oid_cached = oid
  end

  # Return an html string
  def to_s_html
    return '' unless @rec_type

    # Define vars needed for html-template text-substitution
    tpl_tag_repl_strs = {
      :tag_page_title		=> 'Research metadata record',
      :tag_page_heading		=> rec_description_str(' - ', true),
      :tag_table_row_header	=> ( HTML_LINES_INDENT + HtmlHelper.tr(['Field', 'Aux. Field', 'Value', ''], false, {:class => nil}) ),

      # Build replacement-string from @lines
      :tag_table_row_content	=> ( @lines.sort.inject(''){|s,(sort,line)| s + HTML_LINES_INDENT + line} ),

      # Last updated: Omit time so that pages which have no content changes do not change each run during a given day
      :tag_last_updated		=> Time.now.strftime("%d %b %Y %T %Z"),
      #:tag_last_updated		=> Time.now.strftime("%d %b %Y"),
    }
    self.class.to_string_html(:html_template_filename, tpl_tag_repl_strs)
  end

  # Return an html string based on substituting content (produced
  # by processing rules) into an html-template file.
  # * Argument _tpl_fname_key_: The key of the Config[] hash which points
  #   to the html template filename. An html template file is an ordinary 
  #   html file but with special tags (ie. strings) which shall be 
  #   replaced with other text when this program runs.
  # * Argument _tpl_tag_repl_strs_: A hash where a key is associated 
  #   with the tag to be replaced (via
  #   Config[:html_template_replacement_tag_var_pairs]) and the hash value
  #   is the replacement text.
  def self.to_string_html(tpl_fname_key, tpl_tag_repl_strs)
    # Determine the replacement value of each tag (only once per config-tag)
    tag_var_pairs = {}
    Config[:html_template_replacement_tag_var_pairs].each{|tag,repl_key|
      tag_var_pairs[tag] = tpl_tag_repl_strs[repl_key]
    }

    # For each line in template, replace tag with replacement-string if required
    $LOG.debug "Template=#{Config[tpl_fname_key]}. Tag-var pairs=Config[:html_template_replacement_tag_var_pairs]"
    html_str = ''
    File.foreach(Config[tpl_fname_key]){|line|
      tag_var_pairs.each{|tag,repl_str|
          line.sub!("#{HTML_REPLACEMENT_TAG_REGEX1}#{tag}#{HTML_REPLACEMENT_TAG_REGEX2}", repl_str)
      }
      html_str << line
    }
    html_str
  end

  # Write the html page to the calculated destination file
  def write_to_file
    html_str = to_s_html
    if @out_file_path && !html_str.empty?
      $LOG.info "Writing html text to file #{@out_file_path}"
      File.write_string(@out_file_path, html_str)
    end
  end

  ############################################################################
  # Return a few fields to represent this record on a summary page.
  # Return fields for:
  # * Type ie. primary record type
  # * Subtype ie. secondary record type
  # * Key
  # * Name
  def get_summary
    unless valid?
      return {
        :Type    => '',
        :Subtype => '',
        :Key     => '',
        :Name    => '',
      }
    end
    fields = {}
    fields[:Type], fields[:Subtype] = rec_type_str(',', true).split(',')
    type = fields[:Type].downcase

    fields_xpath = [
      # [:HASH_KEY, [XPATH_FOR_OBJECT, XPATH_FOR_DELETED_OBJECT] ]
      [ :Key,
        ["registryObjects/registryObject/key", "header/identifier" ],
      ],
      [ :Name,
        ["registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/name/namePart", "" ],
      ],
    ]

    is_deleted_index = @rec_type == REC_TYPE_DELETED ? 1 : 0

    fields_xpath.each{|ref, xpaths|
      text_elements = []
      xpath_str = xpaths[is_deleted_index].gsub(XPATH_PRIMARY_RECORD_TYPE_TAG, type)
      @doc.elements.each(xpath_str.to_s_xpath){|e| text_elements << e.text}
      fields[ref] = text_elements.join(', ')
    }
    fields
  end

  ############################################################################
  # All action methods below should have names starting with 'show'.
  # Other method names within this class should not. See action_methods().
  ############################################################################

  # A rule-action:
  # Show label, this-attr-values, this-elem-values
  def show_tavalues_tevalues(order, action, label, xpath)
    highlighting_tags = LABELS_TO_HIGHLIGHT.include?(label) ? HTML_HIGHLIGHTING_TAGS : []
    str = ''
    @doc.elements.each(xpath.to_s_xpath){|e|
      str += HtmlHelper.tr( [label, e.attributes.to_a.map{|v| v.to_s}.sort.join(','), e.text], true, {}, highlighting_tags )
    }
    str
  end

  # A rule-action:
  # Show label, this-attr-names, this-attr-values
  def show_tanames_tavalues(order, action, label, xpath)
    str = ''
    @doc.elements.each(xpath.to_s_xpath){|e|
      attr_names = e.attributes.inject([]){|a,(aname,avalue)| a << aname; a}
      str += HtmlHelper.tr( [label, attr_names.join(','), e.attributes.to_a.join(',')] )
    }
    str
  end

  # A rule-action:
  # Show label, this-attr-values, child-elem-values
  def show_tavalues_cevalues(order, action, label, xpath)
    str = ''
    @doc.elements.each(xpath.to_s_xpath){|e|
      values = []
      e.each_element{|e2| values << e2.text}
      str += HtmlHelper.tr( [label, e.attributes.to_a.join(','), values.join(',')] )
    }
    str
  end

  # A rule-action:
  # Show line for <relatedObject> element. Show label, relation-type, key.
  def showelement_related_object(order, action, label, xpath)
    str = ''
    @doc.elements.each(xpath.to_s_xpath){|e|
      fields = {}
      e.each_element{|e2|
        fields[:key] = e2.text if e2.name == 'key'
        if e2.name == 'relation'
          fields[:relation_type] = e2.attributes['type']
          e2.each_element{|e3| fields[:description] = e3.text if e3.name == 'description' }
        end
      }
      aux = fields[:description] ? "#{fields[:relation_type]} (#{fields[:description]})" : fields[:relation_type]
      str += HtmlHelper.tr( [label, aux, fields[:key]] )
    }
    str
  end

  # A rule-action:
  # Show multiple lines for each <relatedInfo> element.
  # * label, relatedInfo-attrs, ''
  # * '', 'Title', title
  # * '', 'Identifier' + identifier-type, identifier
  # * '', 'Notes', notes
  def showelement_related_info(order, action, label, xpath)
    str = ''
    @doc.elements.each(xpath.to_s_xpath){|e|
      fields = {}
      e.each_element{|e2|
        fields[e2.name.to_sym] = e2.text
        fields[:identifier_type] = e2.attributes['type'] if e2.name == 'identifier'
      }
      str += HtmlHelper.tr( [label, e.attributes.to_a.join(','), ''] )

      str += HtmlHelper.tr( ['', 'Title', fields[:title] ] ) if fields[:title]
      str += HtmlHelper.tr( ['', "Identifier (#{fields[:identifier_type]})", fields[:identifier] ] ) if fields[:identifier]
      str += HtmlHelper.tr( ['', 'Notes', fields[:notes] ] ) if fields[:notes]
    }
    str
  end

  # A rule-action:
  # Show line for repo object ID. Show label, nil, OID
  def showinfo_repo_oid(order, action, label, xpath)
    HtmlHelper.tr( [label, '', "#{repo_oid}"] )
  end

  # A rule-action:
  # Show label, nil, ANDS-Collections-Registry-URL
  def showinfo_url_ands_reg(order, action, label, xpath)
    args = nil
    @doc.elements.each(xpath.to_s_xpath){|e| args = e.text}
    args = "?key=#{CGI.escape(args)}#{Config[:ands_reg_url_suffix]}" if args
    HtmlHelper.tr( [label, '', "#{Config[:ands_reg_url_prefix]}#{args}"] )
  end

  # A rule-action:
  # Show label, nil, ANDS-ResearchDataAustralia-URL
  def showinfo_url_ands_rda(order, action, label, xpath)
    args = nil
    @doc.elements.each(xpath.to_s_xpath){|e| args = e.text}
    args = "?key=#{CGI.escape(args)}#{Config[:ands_rda_url_suffix]}" if args
    HtmlHelper.tr( [label, '', "#{Config[:ands_rda_url_prefix]}#{args}"] )
  end


  # A rule-action:
  # Show line for repo name (ie. 'redbox' or 'mint'). Show label, nil, @@repo_name
  def showinfo_repo_name(order, action, label, xpath)
    HtmlHelper.tr( [label, '', "#{@@repo_name}" ] )
  end

  # A rule-action:
  # Show label, nil, value-of-status-attr
  def showhdr_status(order, action, label, xpath)
    @doc.elements.each("header[@status]".to_s_xpath){|e|
      return HtmlHelper.tr( [label, '', e.attributes['status']] )
    }
    ''
  end

  # A rule-action:
  # Show label, nil, datestamp-with-local-timezone
  def showhdr_datestamp_local(order, action, label, xpath)
    datestamp_utc_str = ''		# Eg. datestamp_utc_str = "2013-01-30T07:08:57Z"
    @doc.elements.each(xpath.to_s_xpath){|e| datestamp_utc_str = e.text}
    begin
      y,m,d, hr,min,sec = datestamp_utc_str.split(/[\-T:Z]/)
      time_local = Time.utc(y,m,d, hr,min,sec).localtime	# Time object in local timezone
      # Build datestamp_local_str Eg. "2013-01-30 17:38:57 CST(+10:30)"
      tz_sign = time_local.utc_offset < 0 ? '-' : '+'
      tz_offset_str = "#{tz_sign}#{Time.at(time_local.utc_offset.abs).utc.strftime('%H:%M')}"
      datestamp_local_str = "#{time_local.strftime('%Y-%m-%d %X %Z')}(#{tz_offset_str})"
    rescue
      datestamp_local_str = ''
    end
    HtmlHelper.tr( [label, '', datestamp_local_str] )
  end

end  # class OutWebPage

