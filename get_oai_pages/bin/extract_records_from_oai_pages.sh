#!/bin/sh
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# See usage_exit() for usage.
#
# PURPOSE
#   This program processes one or more OAI-PMH list-files (ie. page-files
#   partitioned by a Resumption Token) by extracting all records from the
#   page-files. Each record is written to an output file. The output
#   filename contains the input filename (of the page-file) as a suffix.
#
# GOTCHAs
# - In order to extract OAI-PMH XML record-trees properly, this script
#   assumes either the input OAI-PMH files will be formatted internally
#   (ie. will_format_xml_input=1) or input files have the property:
#   * <record> is the first tag on a line, and
#   * the corresponding </record> is the last tag on a line
#
# The example below shows which XML elements are extracted.
#
#   <?xml version="1.0" encoding="UTF-8"?>
#   <OAI-PMH ...>
#     <responseDate>2015-12-01T03:22:54Z</responseDate>
#     <request verb="ListRecords" ...</request>
#     <ListRecords>
#
#       <record>	# Written to file #1
#         ...		# Written to file #1
#       </record>	# Written to file #1
#
#       <record>	# Written to file #2
#         ...		# Written to file #2
#       </record>	# Written to file #2
#
#       <resumptionToken/>
#     </ListRecords>
#   </OAI-PMH>
#
##############################################################################
app=`basename $0`
fname_prefix_record_out="rec_"		# Future: Command line param

# Format input XML using xmllint: 1=format input XML file; 0=do not format
will_format_xml_input=1			# Future: Command line param

##############################################################################
extract_records_into_files() {
  awk -v rec_num_offset="$1" -v fname_out_prefix="$2" -v fname_out_suffix="$3" '
    # In order to extract OAI-PMH XML record-trees properly, this script
    # assumes:
    # - <record> is the first tag on a line, and
    # - </record> is the last tag on a line
    # You might achieve this by pre-processing files with a command such as:
    #   xmllint --format XML_FILE

    BEGIN {
      rec_name_prefix = fname_out_prefix
      rec_name_suffix = fname_out_suffix
      rec_num_accum = rec_num_offset
      will_display = 0		# 1=write line to file; 0=Suppress writing line to file
    }

    /<record>/ {
      will_display = 1
      rec_num_accum ++
      fname = sprintf("%s%06d%s", rec_name_prefix, rec_num_accum, rec_name_suffix)
    }

    will_display == 1 {print > fname}

    /<\/record>/ {will_display = 0}

    END {printf("Records extracted: %d (Running total: %d)\n", rec_num_accum - rec_num_offset, rec_num_accum)}
  '
}

##############################################################################
usage_exit() {
	exit_code="$1"
	msg="$2"
	cat <<-EOM_USAGE
		$msg
		Usage:         $app  XML_FILE1 XML_FILE2 ...
		               $app  -h|--help
		Example usage: $app  oai_dc_00*.xml
	EOM_USAGE
	exit "$exit_code"
}

##############################################################################
# Main()
##############################################################################
[ "$1" = -h -o "$1" = --help ] && usage_exit 0
[ $# = 0 ] && usage_exit 1 "You must specify at least one OAI-PMH XML list-file (ie. page-file)."

echo "Extracting OAI-PMH records"
accum_rec_count=0

for fname in $@; do
  printf "Processing OAI-PMH page $fname:"

  if [ $will_format_xml_input = 1 ]; then
    fmt_cmd="xmllint --format"
  else
    fmt_cmd="cat"
  fi

  cmd="$fmt_cmd \"$fname\" |extract_records_into_files \"$accum_rec_count\" \"$fname_prefix_record_out\" \".$fname\""
  msg=`eval $cmd`
  printf " %s\n" "$msg"
  accum_rec_count=`echo "$msg" |tail -1 |sed 's~^.*: ~~' |tr -dc 0-9`
done

