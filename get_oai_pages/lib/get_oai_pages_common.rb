#--
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 
##############################################################################

##############################################################################
# This module contains constants common to get_oai_pages.rb and
# its libraries.
##############################################################################
module GetOaiPagesCommon
  # Version of this program
  VERSION = '0.1rc1'

  OUT_PAGE_PREFIX = 'oai_page_'
  OUT_PAGE_SUFFIX = '.xml'
  # Eg. 4 => max file sequence from  0001 to  9999
  # Eg. 5 => max file sequence from 00001 to 99999
  OUT_PAGE_NUM_DIGITS = 4

  # Eg. Output filename = oai_page_0001.xml, oai_page_0002.xml, ...
  OUT_PAGE_PRINTF_FMT = "%s%0#{OUT_PAGE_NUM_DIGITS}d%s"
  # Will run command below using eval
  OUT_PAGE_FILENAME_CMD = "sprintf(OUT_PAGE_PRINTF_FMT, OUT_PAGE_PREFIX, mgr.page_count, OUT_PAGE_SUFFIX)"

  ############################################################################
  # OAI-PMH constants
  ############################################################################
  OAI_URL_BASE_STRING = 'http://localhost/oai/request'

  # OAI-PMH verb
  QUERY_STRING_PART1 = 'verb=ListRecords'
  QUERY_STRING_PART2_INITIAL = 'metadataPrefix=ore&set=hdl_123456789_6226'
  XPATH_NEXT_PAGE = 'ListRecords/resumptionToken'

  ############################################################################
  # Web page access constants
  ############################################################################
  # Valid protocol schemes.
  VALID_SCHEMES = %w(http https)

  # Web client user-agent header
  USER_AGENT = "#{File.basename($0)}/#{VERSION} (ruby)"

  # ModSecurity or other web server rules may have minimum requirements for
  # the HTTP GET-request header (eg. may need to specify 'User-Agent'). The
  # header must be a hash as required by Net::HTTP get2()
  HTTP_GET_HEADER = {
    'User-Agent' => USER_AGENT,
  }

end

