# Main config for rif2website.rb
# All assignments within this file are ruby script commands
#--
# Copyright (c) 2013, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 
##############################################################################

Config = {
  # Logger-class filter-level order: DEBUG, INFO, WARN, ERROR, FATAL
  # Logger will only emit messages at or above the level specified below
  #:log_level => Logger::DEBUG,

  # XPath for the RIF-CS record key. If the key is a handle we expect it to
  # redirect to a page ending with OID.html (where OID is the ReDBox-Mint
  # object ID).
  :xpath_key => "registryObjects/registryObject/key",

  # Xpath for the RIF-CS identifier for records which have been
  # deleted/retired.
  :xpath_header_id_del => "header/identifier",

  # An html page suitable for all output-record pages but with blank
  # content. Content created by this script shall replace the text:
  #   <!-- [[TAG_NAME]] -->
  # within the template.
  # It is expected that this template will contain styles plus header,
  # footer & navigation content suitable for your organisation.
  :html_template_filename => "#{ENV['HOME']}/opt/rif2website/etc/metadata_record.tpl.html",

  # As above but this template is used to generate a summary page
  # (ie. a page which lists all the records for ReDBox and/or Mint).

  :html_summary_template_filename => "#{ENV['HOME']}/opt/rif2website/etc/metadata_record.tpl.html",

  # Destination filename suffix (including any dots before an extension name)
  # Eg. '.htm' or '.html'
  :dest_filename_suffix => '.html',

  # Destination summary-filename prefix (excluding the extension name and
  # any dots before the extension name). Eg. If this parameter is set to
  # 'summary' and :dest_filename_suffix is set to '.htm', the resulting
  # filename would be 'summary.htm'. The file would be written to the
  # directory specified by :dest_root_dir.
  :dest_summary_filename_prefix => 'index',

  # A hash of tag-replacementString pairs. Each key in this hash corresponds
  # to a tag in the html-template file. The associated value corresponds
  # to a hash-key, the (string) hash-value of which will replace the tag.
  :html_template_replacement_tag_var_pairs => {
    'TAG_PAGE_TITLE'		=> :tag_page_title,
    'TAG_PAGE_HEADING'		=> :tag_page_heading,

    'TAG_TABLE_ROW_HEADER'	=> :tag_table_row_header,
    'TAG_TABLE_ROW_CONTENT'	=> :tag_table_row_content,

    'TAG_LAST_UPDATED'		=> :tag_last_updated,
  },

  # ModSecurity or other web server rules may have minimum requirements for
  # the HTTP GET-request header (eg. may need to specify 'User-Agent'). The
  # header must be a hash as required by Net::HTTP get2()
  :http_get_header => {
    'User-Agent' => RifToWebsite::USER_AGENT,
  },

  # Using the XPATH "registryObjects/registryObject/key"
  # (or "header/identifier" for deleted OAI-PMH records)
  # we can 'calculate' the corresponding URL for this record at the ANDS
  # Collections registry (if it exists). The Demo environment URLs are:
  #   https://demo.ands.org.au/registry/orca/view.php?key=ARG
  # and the production environment URLs are:
  #   https://researchdata.ands.org.au/registry/orca/view.php?key=ARG
  # where ARG is an html-encoded version of the key (or identifier for
  # deleted OAI-PMH records).
  # - The prefix string below represents everything to the left of "?key=ARG".
  # - The suffix string below represents everything to the right of "?key=ARG".
  # - The OutWebPage.showinfo_url_ands_reg method (ie. rule) will calculate
  #   the "?key=ARG" portion.
  :ands_reg_url_suffix => '',
  :ands_reg_url_prefix => 'https://demo.ands.org.au/registry/orca/view.php',		# Demo env
  #:ands_reg_url_prefix => 'https://researchdata.ands.org.au/registry/orca/view.php',	# Prod env

  # As above, but for Research Data Australia (RDA)
  :ands_rda_url_suffix => '',
  :ands_rda_url_prefix => 'http://demo.ands.org.au/view/',		# Demo env
  #:ands_rda_url_prefix => 'http://researchdata.ands.org.au/view/',	# Prod env

} # Config[]

##############################################################################
# If script invoked with --mint option, ConfigMint[] will be merged into
# Config[] hash (overwriting entries with duplicate keys with those from
# ConfigMint[]).

ConfigMint = {
  # Destination root directory. Web pages (records) which are created by this
  # script will be written here.
  #
  # This value must be identical to INTERMED_WEBSITE_DIR (derived from
  # WWW_PARENT) in script rif2website_wrap.sh. For the 'mint' iteration
  # of the loop, the value must be identical to ConfigMint[:dest_root_dir]
  # & the right-most directory must be 'm_temp'. For the 'redbox'
  # iteration of the loop, the value must be identical to
  # ConfigRedbox[:dest_root_dir] & the right-most directory must be 'r_temp'.
  :dest_root_dir => '/var/www/andsdevpub/md/m_temp',

  # The base-URL string (ie. without the query string) for the ReDBox or
  # Mint RIF-CS portal.
  # Eg1. If running rif2website.rb on the same host as ReDBox-Mint:
  # - 'http://localhost:9000/redbox/published/feed/oai'
  # - 'http://localhost:9001/mint/published/feed/oai'
  # Eg2. If running rif2website.rb on a different host to ReDBox-Mint:
  # - 'https://YOUR_REMOTE_SERVER/redbox/published/feed/oai'
  # - 'https://YOUR_REMOTE_SERVER/mint/published/feed/oai'
  :url_str_rifcs => 'http://localhost:9001/mint/published/feed/oai',
  
  # RIF-CS namespace prefix for all elements (ie. at <registryObjects>
  # and below). The namespace prefix must include the trailing colon.
  # Eg1. For Mint 1.5.1 & earlier, assign empty string '' to
  # match <registryObjects>, etc.
  # Eg2. For Redbox 1.5.1 & earlier, assign string 'rif:' to
  # match <rif:registryObjects>, etc.
  :ns_prefix_rif => '',

} # ConfigMint[]

##############################################################################
# If script invoked with --redbox option, ConfigRedbox[] will be merged into
# Config[] hash (overwriting entries with duplicate keys with those from
# ConfigRedbox[]).

# The description of the key-values below are identical to those for ConfigMint above.
ConfigRedbox = {
  :dest_root_dir => '/var/www/andsdevpub/md/r_temp',
  :url_str_rifcs => 'http://localhost:9000/redbox/published/feed/oai',
  :ns_prefix_rif => 'rif:',
} # ConfigRedbox[]

