#!/usr/bin/env ruby
#--
# Usage: get_oai_pages.rb
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
# PURPOSE
#
# To read OAI-PMH (XML) pages via a network connection & generate an
# output file for each page.
#
#++
##############################################################################
# Add dirs to the library path
$: << File.expand_path("../lib", File.dirname(__FILE__))

require 'in_oai_page_manager'
require 'object_extra'
require 'get_oai_pages_common'	# Config options for this app

##############################################################################
# A class for reading OAI-PMH (XML) pages into files
##############################################################################
class GetOaiPages
  include GetOaiPagesCommon

  ############################################################################
  # The main method for this program
  #
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
  #                   ...info...
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
  #    section.
  # 2. The last OAI-PMH page has an empty <resumptionToken> element.
  ############################################################################
  def self.main
    mgr = InOaiPageManager.new
    while mgr.next_page
      fname = eval OUT_PAGE_FILENAME_CMD
      STDERR.puts "Saving file: #{fname}"
      File.write_string(fname, mgr.page)
    end
  end

end

##############################################################################
# Main
##############################################################################
GetOaiPages.main
exit 0

