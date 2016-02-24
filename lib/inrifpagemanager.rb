#--
# Copyright (c) 2013, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 

# Load standard library files
require 'logger'
require 'rexml/document'
require 'rexml/xpath'

# Load application library files
require 'inwebpage'

##############################################################################
# RIF-CS XML pages are usually paginated such that a maximum of N (eg. 10)
# records are displayed on a given page. This class manages the fetching
# of initial and subsequent RIF-CS pages. Another page follows if the
# current page has a resumption token. Typical usage:
#
#   mgr = InRifPageManager.new
#   while mgr.next_page
#     # Access xml elements with 'rexml/document' & 'rexml/xpath' methods via mgr.doc
#     mgr.doc.root.elements.each(SOME_XPATH){|e| ... }
#     ...
#   end



class InRifPageManager
  QUERY_STRING_PART1 = 'verb=ListRecords'
  XPATH_NEXT_PAGE = 'ListRecords/resumptionToken'
  # OAI-PMH UTC datestamp format: YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ
  OAI_DATESTAMP_REGEX = /^\d{4}(-\d{2}){2}(T\d{2}(:\d{2}){2}Z)?$/

  attr_reader :url_base_str, :url_str, :page_count, :page, :doc

  # Create a new InRifPageManager object.
  # * Argument _oai_from_: This optional argument is the OAI-PMH 'from' UTC
  #   datestamp with format YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ
  # * Argument _oai_until_: This optional argument is the OAI-PMH 'until' UTC
  #   datestamp with format YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ
  # * Argument _url_str_without_query_: This optional argument is the base-URL
  #   string (ie. without the query string) for the RIF-CS portal. It is
  #   assumed that the hash Config[] has been defined with key:
  #   * <em>:url_str_rifcs</em> -- The default base-URL string (ie. without the query string)
  #     for the RIF-CS portal.
  def initialize(oai_from=nil, oai_until=nil, url_str_without_query=Config[:url_str_rifcs])
    @url_base_str = url_str_without_query
    @query_str_next_page = 'metadataPrefix=rif'

    if self.class.oai_datestamps_ok(oai_from, oai_until)
      @query_str_next_page << "&from=#{oai_from}" if oai_from
      @query_str_next_page << "&until=#{oai_until}" if oai_until
    else
      @query_str_next_page = ""		# Don't get any OAI-PMH pages
    end

    # Vars below correspond to the current page
    @page_count = 0
    @url_str = nil
    @page = nil
    @doc = nil
  end

  # Returns true if OAI-PMH datestamp is valid; else returns false
  def self.oai_datestamp_ok(datestamp)
    return true if datestamp.nil?
    # Currently no range checking
    (datestamp =~ OAI_DATESTAMP_REGEX) ? true : false
  end

  # Returns true if OAI-PMH datestamps are valid; else returns false
  def self.oai_datestamps_ok(oai_from, oai_until)
    return false unless oai_datestamp_ok(oai_from) && oai_datestamp_ok(oai_until)
    return false if oai_from && oai_until && oai_from > oai_until
    true
  end

  # Gives the URL of the page to be fetched when next_page() is invoked
  def next_url_str
    "#{@url_base_str}?#{QUERY_STRING_PART1}&#{@query_str_next_page}"
  end

  # Fetch the next RIF-CS page. Prepare for the next invocation (if
  # the fetched page has a resumption token).
  def next_page
    return nil if @query_str_next_page.empty?
    @url_str = next_url_str
    @page = InWebPage.new(@url_str)
    @page_count += 1

    # Prepare for getting the page which follows.
    @doc = REXML::Document.new(@page.to_s)
    @query_str_next_page = ''
    @doc.root.elements.each(XPATH_NEXT_PAGE){|e| @query_str_next_page = "resumptionToken=#{e.text}"}
    true
  end

  # Convert to string (for debugging purposes only).
  def to_s
    "#{self.class}(page_count:#{@page_count}, url_str:#{@url_str})"
  end
end  # class InRifPage

