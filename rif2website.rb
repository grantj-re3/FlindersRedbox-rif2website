#!/usr/bin/env ruby
#--
# Usage: rif2website.rb  --mint | --redbox
#
# Copyright (c) 2013, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
##############################################################################
# Purpose:
#   To read ReDBox-Mint RIF-CS (XML) via a network connection & generate a
#   static web page for each registryObject element. The static web page is
#   generated by extracting XML information from rules specified in a
#   configuration file. See README for further details.
#
#++
##############################################################################
# Load standard library files
require 'logger'
require 'getoptlong'
require 'fileutils'
require 'rexml/document'
require 'rexml/xpath'

# Load application library files
$: << 'lib'			# Add lib subdir to the load/require-path.
require 'inrifpagemanager'
require 'object_extra'
require 'outwebpage'

##############################################################################
# A class for converting RIF-CS XML records into a website. One RIF-CS
# record will result in one static web page if conversion rules have 
# been supplied for the particular record and subtype. Since it is common
# for multiple (eg. 10) RIF-CS records to be present on a single RIF-CS
# page, it is also common for a RIF-CS page to generate multiple static
# web pages.
class RifToWebsite
  # Version of this program
  VERSION = '0.2rc1'
  # Web client user-agent header
  USER_AGENT = "#{File.basename(__FILE__)}/#{VERSION} (ruby)"

  # Logger will write to this filename. (Can also set to STDOUT).
  LOG_FILENAME = "#{File.dirname(__FILE__)}/#{self}.log"

  # We will load/require config files first, then rule files.
  REQUIRE_CONFIG_FILES = {
    'config' => 'etc/conf*.rb',
    'rule' => 'etc/rule*.rb'
  }

  # RIF-CS record types
  RIF_RECORD_TYPES = %w(party activity service collection)

  # The main method for this program
  def self.main
    $LOG = Logger.new(LOG_FILENAME)
    # Default log level (can be overridden in config file with Config[:log_level])
    $LOG.level = Logger::INFO  # Filter levels: DEBUG, INFO, WARN, ERROR, FATAL
    $LOG.info '-' * 30
    $LOG.info "Starting #{File.basename(__FILE__)} :: v#{VERSION} :: #{self}.#{__method__}"

    REQUIRE_CONFIG_FILES.sort.each{|file_type, rel_file_path_glob|
      config_paths = "#{File.dirname(__FILE__)}/#{rel_file_path_glob}"
      Dir.glob(config_paths).sort.each{|fpath|
        $LOG.info "Loading #{file_type} file: #{fpath}"
        begin
          require fpath
        rescue Exception => ex
          $LOG.fatal "Config file error: #{fpath}; #{ex}"
          exit 1
        end
      }
    }
    $LOG.level = Config[:log_level] if defined?(Config[:log_level]) && Config[:log_level].class == Fixnum

    process = do_redbox_or_mint
    if process
      hash_name = "Config#{process.to_s.capitalize}"

      if Module.constants.include?(hash_name)
        $LOG.info "Reading and merging #{hash_name}[] into Config[]"
        Config.merge!(eval hash_name)
      else
        $LOG.warn "Cannot find Hash #{hash_name}[], so cannot merge into Config[]"
      end

      OutWebPage.repo_name = process.to_s
    else
      OutWebPage.repo_name = nil
    end

    tpl_fname = Config[:html_template_filename]
    if tpl_fname && File.readable?(tpl_fname)
      $LOG.info "Using HTML template file '#{tpl_fname}'"
      create_root_dir
      process_rif_records
    else
      $LOG.fatal "Config[:html_template_filename] is not set or file '#{tpl_fname}' is not readable. Cannot create web pages without an HTML template!"
    end
    $LOG.info "Ending #{File.basename(__FILE__)}"
  end

  # This method determines if this program has been instructed
  # via the command line interface to process either the
  # ReDBox or Mint RIF-CS portal. The method will return
  # "mint" or "redbox" if invoked with:
  #   --mint
  # or
  #   --redbox
  # switches respectively. If invoked with some other switch or without
  # any switch, the method will display a usage error message in the
  # log then exit the program.
  def self.do_redbox_or_mint
    opts = GetoptLong.new(
      ["--mint", GetoptLong::NO_ARGUMENT],
      ["--redbox", GetoptLong::NO_ARGUMENT]
    )
    process = nil  # :mint or :redbox
    begin
      opts.each{|opt, arg|
        $LOG.info "Script invoked with option: #{opt}"
        process = opt.sub(/^--/, '').to_sym
      }
    rescue Exception => ex
      exit 1
    end
    unless process
      $LOG.fatal "Usage: #{File.basename($0)}  --mint | --redbox"
      exit 1
    end
    process
  end

  # This method creates a path to the web root directory, making
  # parent directories as needed.
  def self.create_root_dir
    unless File.directory?(Config[:dest_root_dir])
      $LOG.info "Creating path to directory #{Config[:dest_root_dir]}"
      begin
        FileUtils.mkdir_p(Config[:dest_root_dir])
      rescue Exception => ex
        $LOG.fatal "Error creating directory #{Config[:dest_root_dir]}; #{ex}"
        exit 1
      end
    end
  end

##############################################################################
  # Process all of the RIF-CS records as follows.
  # * Iterate through all OAI-PMH pages
  #   * Iterate through each RIF-CS record on each of those pages and
  #     convert each such record to a web page according to specified rules
  #   * Iterate through each OAI-PMH header searching for retired records
  #     (ie. status="deleted") for which there is no longer a RIF-CS
  #     record. Extract the (little) information available from the header
  #     and write it to a web page.
  # OAI-PMH pages are structured as below.
  #
  #   <OAI-PMH ...>
  #       ...
  #       <ListRecords>
  #           <record>
  #               <header>
  #                 ...
  #               </header>
  #               <metadata>
  #                   ...RIF-CS info...
  #               </metadata>
  #           </record>
  #		
  #             ...more records within <record>...</record> elements...
  #		
  #           <resumptionToken>...</resumptionToken>
  #       </ListRecords>
  #   </OAI-PMH>
  # Notes:
  # 1. A <header> with a status of "deleted" does not have a <metadata>
  #    section, hence no RIF-CS information.
  # 2. The last OAI-PMH page does not have a <resumptionToken> section.
  def self.process_rif_records
    $LOG.info "Action-methods available for rules: #{OutWebPage.new(nil, nil).action_methods.join(', ')}"


    summary_fields = []
    rec_regex_str = "^(#{RIF_RECORD_TYPES.join('|')})$"
    mgr = InRifPageManager.new
    while mgr.next_page
      # XPath points to the node where xmlns ("rif") is defined.
      xpath_ns = "ListRecords/record/metadata/#{Config[:ns_prefix_rif]}registryObjects"
      String.xpath_prefix = Config[:ns_prefix_rif]

      # For non-retired (ie. OAI-PMH non-deleted) records
      mgr.doc.root.elements.each(xpath_ns){|e|	# Each rifcs record
        doc_record = REXML::Document.new(e.to_s)
        doc_record.elements.each("registryObjects/registryObject/*".to_s_xpath){|e2|
          if e2.name.match(rec_regex_str)
            rec_type = "#{e2.name},#{e2.attributes['type']}"
            #puts "$$$ #{e2.name}-#{e2.attributes['type']} = #{e2.inspect}\n\n"
            #3.times{puts '=' *78}
            out = OutWebPage.new(rec_type, doc_record)
            out.write_to_file
            summary_fields << out.get_summary
          end
        }
      }

      # OAI-PMH does not provide RIF-CS metadata for retired/deleted
      # records. But we can find some info in the header.
      xpath_ns = "ListRecords/record/header"
      String.xpath_prefix = ''

      mgr.doc.root.elements.each("ListRecords/record/header"){|e|	# Each header element
        next unless e.attributes['status'] == 'deleted'

        doc_record = REXML::Document.new(e.to_s)
        out = OutWebPage.new(OutWebPage::REC_TYPE_DELETED, doc_record)
        out.write_to_file
        summary_fields << out.get_summary
      }
    end
    $LOG.info "Writing summary html text to file #{OutWebPage.output_summary_file_path}"
    File.write_string(OutWebPage.output_summary_file_path, to_s_html(summary_fields))
  end

  # Return a summary html string based on information in the summary_fields
  # array.
  # * Argument _summary_fields_: An array of hashes. Each hash gives
  #   information about a single RIF-CS record and is displayed as
  #   a single table-row on the summary web page.
  def self.to_s_html(summary_fields)
    offset = summary_fields.length
    lines = {}
    summary_fields.sort{|a,b|
      if a[:Type] != b[:Type]
        a[:Type] <=> b[:Type]
      elsif a[:Subtype] != b[:Subtype]
        a[:Subtype] <=> b[:Subtype]
      elsif a[:Name] != b[:Name]
        a[:Name] <=> b[:Name]
      else
        a[:Key] <=> b[:Key]
      end
    }.each_with_index{|rec,i|
      index = "#{rec[:Type]},#{rec[:Subtype]}".downcase == OutWebPage::REC_TYPE_DELETED ? offset + i : i  # Put deleted records at end
      lines[index] = HtmlHelper.tr( [ rec[:Type], rec[:Subtype], rec[:Key], rec[:Name] ] )
    }

    # Define vars needed for html-template text-substitution
    tpl_tag_repl_strs = {
      :tag_page_title		=> 'List of metadata records',
      :tag_page_heading		=> 'Summary',
      :tag_table_row_header	=> ( OutWebPage::HTML_LINES_INDENT + HtmlHelper.tr(['Type', 'Subtype', 'Key', 'Name'], false, {:class => nil}) ),

      # Build replacement-string from lines
      :tag_table_row_content	=> ( lines.sort.inject(''){|s,(sort,line)| s + OutWebPage::HTML_LINES_INDENT + line} ),

      # Last updated: Omit time so that pages which have no content changes do not change each run during a given day
      :tag_last_updated		=> Time.now.strftime("%d %b %Y %T %Z"),
      #:tag_last_updated		=> Time.now.strftime("%d %b %Y"),
    }
    OutWebPage.to_string_html(:html_summary_template_filename, tpl_tag_repl_strs)
  end

end  # class RifToWebsite

##############################################################################
# Main
##############################################################################
RifToWebsite.main
exit 0

