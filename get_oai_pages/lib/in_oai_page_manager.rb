#--
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 
##############################################################################
# Load standard library files
require 'rexml/document'

# Load application library files
require 'in_web_page'
require 'get_oai_pages_common'

##############################################################################
# OAI-PMH XML pages are usually paginated such that a maximum of N (eg. 10)
# records are displayed on a given page. This class manages the fetching
# of initial and subsequent OAI-PMH pages. Another page follows if the
# current page has a resumption token. Typical usage:
#
#   mgr = InOaiPageManager.new
#   while mgr.next_page
#     # Access xml elements with 'rexml/document' & 'rexml/xpath' methods via mgr.doc
#     mgr.doc.root.elements.each(SOME_XPATH){|e| ... }
#     ...
#   end
##############################################################################
class InOaiPageManager
  include GetOaiPagesCommon

  attr_reader :url_base_str, :url_str, :page_count, :page, :doc

  ############################################################################
  # Create a new InOaiPageManager object.
  # * Argument _url_str_without_query_: This optional argument is the base-URL
  #   string (ie. without the query string) for the OAI-PMH interface.
  ############################################################################
  def initialize(url_str_without_query=OAI_URL_BASE_STRING)
    @url_base_str = url_str_without_query
    @query_str_verb = QUERY_STRING_PART1
    @query_str_next_page = QUERY_STRING_PART2_INITIAL
    @is_next_url_str_valid = true

    # Vars below correspond to the current page
    @page_count = 0
    @url_str = nil
    @page = nil
    @doc = nil
  end

  ############################################################################
  # Allows a complete OAI-PMH initial URL to be specified (instead of using
  # the default URL). The URL is split into its component parts.
  ############################################################################
  def set_full_url(full_url)
    @url_base_str = @query_str_verb = @query_str_next_page = query_str = ''
    msg = <<-MSG_BAD_URL.gsub(/^\t*/, '')
	ERROR! Bad initial URL for the OAI-PMH 'ListRecords' verb was supplied:
	  '#{full_url}'

	Valid examples are:
	  'http://example.com/myapp/harvest?verb=ListRecords&metadataPrefix=oai_dc'
	  'https://example.com/myapplic/oai?verb=ListRecords&metadataPrefix=my_oai_md&set=myset'

	- Initial URLs must not specify a resumption token.
	- The URLs are shown within quotes as these are probably needed to escape
	  special characters (eg. "&") from the Unix shell.
    MSG_BAD_URL

    begin
      @url_base_str, query_str = full_url.match(/^([^\?]*)\?(.*)$/)[1,2]	# full_url = @url_base_str+'?'+query_str 
      @query_str_verb = query_str.match(/(verb=[^&]*)(&|$)/)[1]			# Extract 'verb=XXXX'
      @query_str_next_page = query_str.sub(@query_str_verb, '').sub(/&&/, '&').sub(/^&|&$/, '') # All query string except 'verb=XXXX&'
    rescue Exception => ex
      STDERR.puts msg
      exit 2
    end

    if [@url_base_str, @query_str_verb, @query_str_next_page].include?('') ||
      query_str.match(/resumptionToken/)
        STDERR.puts msg
        exit 2
    end
  end

  ############################################################################
  # Gives the URL of the page to be fetched when next_page() is invoked
  ############################################################################
  def next_url_str
    "#{@url_base_str}?#{@query_str_verb}&#{@query_str_next_page}"
  end

  ############################################################################
  # Fetch the next OAI-PMH page. Prepare for the next invocation (if
  # the fetched page has a resumption token).
  ############################################################################
  def next_page
    return nil unless @is_next_url_str_valid
    @url_str = next_url_str
    @page = InWebPage.new(url_str)
    @page_count += 1

    # Prepare for getting the page which follows.
    @doc = REXML::Document.new(@page.to_s)
    resumption_token = nil
    @doc.root.elements.each(XPATH_NEXT_PAGE){|e| resumption_token = e.text}

    @query_str_next_page = "resumptionToken=#{resumption_token}"
    @is_next_url_str_valid = !resumption_token.nil?
    true
  end

  ############################################################################
  # Convert to string (for debugging purposes only).
  ############################################################################
  def to_s
    "#{self.class}(page_count:#{@page_count}, url_str:#{@url_str})"
  end
end

