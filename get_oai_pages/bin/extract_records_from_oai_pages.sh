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
fname_prefix_record_out="rec"		# Future: Command line param
fname_suffix_delim="."

# Format input XML using xmllint: 1=format input XML file; 0=do not format
will_format_xml_input=1			# Future: Command line param

##############################################################################
extract_records_into_files() {
  target_node_name="${4:-record}"
  awk -v rec_num_offset="$1" -v fname_out_prefix="$2" -v fname_out_suffix="$3" -v node_name="$target_node_name" '
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

      begin_tag = "<" node_name ">"
      end_tag = "</" node_name ">"
    }

    $0 ~ begin_tag {
      will_display = 1
      rec_num_accum ++
      fname = sprintf("%s%06d%s", rec_name_prefix, rec_num_accum, rec_name_suffix)
    }

    will_display == 1 {print > fname}

    $0 ~ end_tag {will_display = 0}

    END {printf("Records extracted: %d (Running total: %d)\n", rec_num_accum - rec_num_offset, rec_num_accum)}
  '
}

##############################################################################
usage_exit() {
	exit_code="$1"
	msg="$2"

	cat <<-EOM_USAGE >&2
		$msg
		Usage:
		  $app  [-n NODE] XML_FILE1 XML_FILE2 ...
		  $app  -h|--help


		This program processes one or more OAI-PMH page-files by extracting all
		records from each listed page-file. Each record is written to an output
		file. The output filename uses the input filename (of the page-file) as
		a suffix.

		The default behaviour is to extract 'record' nodes (ie. all nodes between
		<record> and </record> inclusive) as if the OAI-PMH pages had been
		created with the 'ListRecords' verb. However if the pages were created
		with some other verb you can extract corresponding records by specifying
		a different NODE name using the -n option. For example, you can specify:

		* '-n header'
		* '-n set'
		* '-n metadataFormat'

		for 'ListIdentifiers', 'ListSets' and 'ListMetadataFormats' verbs
		respectively.

		Example usage:
		  $app  path/to/oai_dc_page00*.xml

		may result in output files such as:
		  ...
	EOM_USAGE

	rec_name_prefix="$fname_prefix_record_out"
	rec_name_suffix="oai_dc_page0033.xml"
	for rec_num_accum in {330..332}; do
        	printf "  %s%06d%s\n" "$rec_name_prefix" "$rec_num_accum" "$fname_suffix_delim$rec_name_suffix" >&2
	done
	exit "$exit_code"
}

##############################################################################
# Main()
##############################################################################
[ "$1" = -h -o "$1" = --help ] && usage_exit 0

[ "$1" = -n ] && {
  node_name_to_match="$2"
  shift
  shift
}

[ $# = 0 ] && usage_exit 1 "You must specify at least one OAI-PMH XML list-file (ie. page-file)."

if [ $will_format_xml_input = 1 ]; then
  fmt_cmd="xmllint --format"
else
  fmt_cmd="cat"
fi

echo "Extracting OAI-PMH records"
accum_rec_count=0

for fname_in in $@; do
  printf "Processing OAI-PMH page $fname_in:"
  fname_in_base=`basename "$fname_in"`

  cmd="$fmt_cmd \"$fname_in\" |extract_records_into_files \"$accum_rec_count\" \"$fname_prefix_record_out\" \"$fname_suffix_delim$fname_in_base\" \"$node_name_to_match\""
  msg=`eval $cmd`
  printf " %s\n" "$msg"
  accum_rec_count=`echo "$msg" |tail -1 |sed 's~^.*: ~~' |tr -dc 0-9`
done

