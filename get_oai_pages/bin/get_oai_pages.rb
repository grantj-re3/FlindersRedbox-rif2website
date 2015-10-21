#!/usr/bin/env ruby
#--
# Usage: See get_command_line_options()
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
  # Get the command line options for this program. Return the results
  # as key-value pairs in a hash.
  ############################################################################
  def self.get_command_line_options
    sample_fname = sprintf(OUT_PAGE_PRINTF_FMT, OUT_PAGE_PREFIX, 1, OUT_PAGE_SUFFIX)
    msg = <<-MSG_COMMAND_LINE_ARGS.gsub(/^\t*/, '')
		Usage:  #{File.basename $0}  OPTIONS  OAIPMH_INITIAL_URL
		where
		  OPTIONS are:

		    -m|--max-pages N: Allows the maximum number of OAI-PMH pages to be
		      set to the integer N. If N is negative, there is no limit to the
		      number of pages. The default behaviour is to have no page limit.

		    -f|--filename-prefix NAME: Allows the filename prefix to be set to NAME.
		      The default filename prefix is '#{OUT_PAGE_PREFIX}' which means the
		      filename for the first page will be '#{sample_fname}'.

		    -h|--help: This help message.

		  OAIPMH_INITIAL_URL is the URL of the first OAI-PMH page.
    MSG_COMMAND_LINE_ARGS

    opts = {
      # Default options
      :is_max_oai_page_count => false,	# false= unlimited OAI pages; true= use opts[:max_oai_page_count]
      :max_oai_page_count => -1,
      :out_page_prefix => OUT_PAGE_PREFIX,
    }

    if ARGV.include?('-h') || ARGV.include?('--help')	# Search all of arg list
      STDERR.puts msg
      exit 0
    end

    while ARGV[0]
      case ARGV[0]
        when /-m|--max-pages/
          ARGV.shift
          num_pages = ARGV.shift.to_i
          opts[:is_max_oai_page_count] = num_pages >= 0
          opts[:max_oai_page_count] = num_pages

        when /-f|--filename-prefix/
          ARGV.shift
          opts[:out_page_prefix] = ARGV.shift

        else
          # Unrecognised option. We expect OAIPMH_INITIAL_URL here.
          break
      end
    end

    if ARGV.length == 0
      STDERR.puts "OAIPMH_INITIAL_URL not found.\n\n#{msg}"
      exit 1
    end
    if ARGV.length > 1
      STDERR.puts "Unrecognised options or too many arguments:\n  #{ARGV.join(' ')}\n\n#{msg}"
      exit 1
    end
    opts
  end

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
    opts = get_command_line_options
    mgr = InOaiPageManager.new
    mgr.set_full_url(ARGV[0]) if ARGV.length > 0

    # Test mgr.page_count before mgr.next_page as next_page() increments the page_count
    while (!opts[:is_max_oai_page_count] || opts[:is_max_oai_page_count] && mgr.page_count < opts[:max_oai_page_count]) && mgr.next_page
      fname = sprintf(OUT_PAGE_PRINTF_FMT, opts[:out_page_prefix], mgr.page_count, OUT_PAGE_SUFFIX)
      STDERR.puts "Saving file: #{fname}"
      File.write_string(fname, mgr.page)
    end
    exit 0
  end

end

##############################################################################
# Main
##############################################################################
GetOaiPages.main
exit 0

