# Rules for rif2website.rb
# All assignments within this file are ruby script commands
#--
# Copyright (c) 2013-2014, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 
#
# It is important that the ruby constant identifier name for each rule
# matches the RIF-CS record-type and subtype as follows. For RIFCS 
# record <elem1 type="attr1">, the ruby constant name must be:
#   Elem1Attr1Rules
# Eg1. For <party type="person"> use the name PartyPersonRules.
# Eg2. For <collection type="catalogueOrIndex"> use the name
#      CollectionCatalogueOrIndexRules.
##############################################################################
# Note that within an XPath string, the program will replace the tag
# "[[PRIMARY_RECORD_TYPE_TAG]]" with the record's primary record type
# (ie. 'party', 'activity', 'service' or 'collection') before processing.
#
# Special-purpose action-name meanings have the format:
#   showelement_ELEMENT_NAME	# Assumes XPath: registryObjects/registryObject
#   showhdr_HEADER_INFO		# Assumes XPath: header[@status] = 'deleted'
#   showinfo_INFO		# Available with either XPath given above
#
# Generic action-name meanings have the format:
#   show_ABC_ABC
# where
#   A = 't' (this); 'c' (child)
#   B = 'a' (attribute); 'e' (element)
#   C = 'values' or 'names'
# Eg.
#   tavalues = attr values for this XPath
#   tanames  = attr names for this XPath
#   tevalues = element values for this XPath
#   cevalues = element values for child of XPath
##############################################################################

##############################################################################
# OAI-PMH records which have been deleted/retired. ie. <header status='deleted'>
##############################################################################
# OAI-PMH does not provide an XPath of metadata/registryObjects/registryObject 
# for deleted/retired records. So all our info must be derived from XPath
# header/...
AnyDeletedRules = [
# [ Sort, ActionMethod,			Label,					XPath, ],
  [ 2020, :showhdr_status,		"Status",				"", ],
  [ 2030, :show_tavalues_tevalues,	"Deletion datestamp",			"header/datestamp", ],
  [ 2040, :showhdr_datestamp_local,	"Deletion datestamp (local time)",	"header/datestamp", ],
  [ 2060, :show_tavalues_tevalues,	"Identifier (OAI)",			"header/identifier", ],
  ##[ 2090, :show_tavalues_tevalues,	"SetSpec (membership)",			"header/setSpec", ],

  [ 2470, :showinfo_repo_name,		"Repository name",			"", ],
  [ 2480, :showinfo_repo_oid,		"Repository object ID",			"", ],

  [ 2490, :showinfo_url_ands_rda,	"Record <em>may</em> exist at Research Data Australia",				"header/identifier", ],
  #[ 2495, :showinfo_url_ands_reg,	"Record <em>may</em> exist at the ANDS Online Services Collections Registry",	"header/identifier", ],
]

##############################################################################
# A set of rules suitable for record-types: activity, party, service.
##############################################################################
GenericRules_ActivityPartyService = [
# [ Sort, ActionMethod,			Label,			XPath, ],
  [ 2100, :show_tavalues_tevalues,	"Name",			"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/name/namePart", ],
  [ 2140, :showinfo_url_ands_rda,	"Record <em>may</em> exist at Research Data Australia",				"registryObjects/registryObject/key", ],
  [ 2160, :show_tavalues_tevalues,	"Identifier",		"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/identifier", ],

  [ 2200, :show_tavalues_cevalues,	"Electronic Address",	"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/location/address/electronic", ],
  [ 2220, :show_tavalues_tevalues,	"Physical Address",	"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/location/address/physical/addressPart", ],

  [ 2300, :show_tavalues_tevalues,	"Description",		"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/description", ],

  [ 2600, :showelement_related_object,	"Related Object",	"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/relatedObject", ],
  [ 2620, :show_tavalues_tevalues,	"Subject",		"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/subject", ],

  [ 2700, :show_tanames_tavalues,	"Registry Object",	"registryObjects/registryObject", ],
  ##[ 2720, :show_tavalues_tevalues,	"Originating Source",	"registryObjects/registryObject/originatingSource", ],
  [ 2740, :showinfo_repo_name,		"Repository name",	"", ],
  [ 2760, :showinfo_repo_oid,		"Repository object ID",	"", ],

  [ 2800, :show_tavalues_tevalues,	"Key",			"registryObjects/registryObject/key", ],

]

##############################################################################
# Parties
##############################################################################
# Processing rules for RIFCS record type <party type="person">
PartyPersonRules = GenericRules_ActivityPartyService

# Processing rules for RIFCS record type <party type="group">
PartyGroupRules = GenericRules_ActivityPartyService

##############################################################################
# Activities
##############################################################################
# Processing rules for RIFCS record type <activity type="project">
ActivityProjectRules = GenericRules_ActivityPartyService

##############################################################################
# Services
##############################################################################
# Processing rules for RIFCS record type <service type="SERVICE_TYPE">
# where SERVICE_TYPE is one of the following:
#   Annotate Assemble Create Generate Report Transform 
#   Harvest-oaipmh Search-http Search-opensearch Search-sru Search-srw
#   Search-z3950 Syndicate-atom Syndicate-rss
# Eg. Rules for <service type="create"> would be ServiceCreateRules
ServiceAnnotateRules  = GenericRules_ActivityPartyService
ServiceAssembleRules  = GenericRules_ActivityPartyService
ServiceCreateRules    = GenericRules_ActivityPartyService
ServiceGenerateRules  = GenericRules_ActivityPartyService
ServiceReportRules    = GenericRules_ActivityPartyService
ServiceTransformRules = GenericRules_ActivityPartyService

ServiceHarvest_oaipmhRules    = GenericRules_ActivityPartyService
ServiceSearch_httpRules       = GenericRules_ActivityPartyService
ServiceSearch_opensearchRules = GenericRules_ActivityPartyService
ServiceSearch_sruRules        = GenericRules_ActivityPartyService
ServiceSearch_srwRules        = GenericRules_ActivityPartyService

ServiceSearch_z3950Rules   = GenericRules_ActivityPartyService
ServiceSyndicate_atomRules = GenericRules_ActivityPartyService
ServiceSyndicate_rssRules  = GenericRules_ActivityPartyService

##############################################################################
# Collections
##############################################################################
# INCOMPLETE! relatedInfo, ...
# Processing rules for RIFCS record type <collection type="dataset">

CollectionDatasetRules = [
# [ Sort, ActionMethod,			Label,			XPath, ],
  [ 2100, :show_tavalues_tevalues,	"Name",			"registryObjects/registryObject/collection/name/namePart", ],
  #[ 2140, :showinfo_url_ands_reg,	"Record <em>may</em> exist at the ANDS Online Services Collections Registry",	"registryObjects/registryObject/key", ],
  [ 2140, :showinfo_url_ands_rda,	"Record <em>may</em> exist at Research Data Australia",				"registryObjects/registryObject/key", ],
  [ 2160, :show_tavalues_tevalues,	"Identifier",		"registryObjects/registryObject/collection/identifier", ],

  [ 2200, :show_tavalues_cevalues,	"Electronic Address",	"registryObjects/registryObject/collection/location/address/electronic", ],
  [ 2220, :show_tavalues_tevalues,	"Physical Address",	"registryObjects/registryObject/collection/location/address/physical/addressPart", ],

  [ 2300, :show_tavalues_tevalues,	"Description",		"registryObjects/registryObject/collection/description", ],
  [ 2320, :show_tavalues_tevalues,	"Rights Statement",	"registryObjects/registryObject/collection/rights/rightsStatement", ],
  [ 2340, :show_tavalues_tevalues,	"Access Rights",	"registryObjects/registryObject/collection/rights/accessRights", ],

  [ 2400, :show_tavalues_tevalues,	"Citation Info",	"registryObjects/registryObject/collection/citationInfo/fullCitation", ],

  [ 2500, :show_tavalues_tevalues,	"Temporal Coverage",	"registryObjects/registryObject/collection/coverage/temporal/date", ],
  [ 2520, :show_tavalues_tevalues,	"Spatial Coverage",	"registryObjects/registryObject/collection/coverage/spatial", ],

  [ 2600, :showelement_related_object,	"Related Object",	"registryObjects/registryObject/collection/relatedObject", ],
  [ 2620, :show_tavalues_tevalues,	"Subject",		"registryObjects/registryObject/collection/subject", ],
  [ 2640, :showelement_related_info,	"Related Information",	"registryObjects/registryObject/collection/relatedInfo", ],

  [ 2700, :show_tanames_tavalues,	"Registry Object",	"registryObjects/registryObject", ],
  ##[ 2720, :show_tavalues_tevalues,	"Originating Source",	"registryObjects/registryObject/originatingSource", ],
  [ 2740, :showinfo_repo_name,		"Repository name",	"", ],
  [ 2760, :showinfo_repo_oid,		"Repository object ID",	"", ],

  [ 2800, :show_tavalues_tevalues,	"Key",			"registryObjects/registryObject/key", ],
]

# Processing rules for RIFCS record type <collection type="collection">
CollectionCollectionRules = CollectionDatasetRules

# Processing rules for RIFCS record type <collection type="catalogueOrIndex">
CollectionCatalogueOrIndexRules = CollectionDatasetRules

# Processing rules for RIFCS record type <collection type="registry">
CollectionRegistryRules = CollectionDatasetRules

# Processing rules for RIFCS record type <collection type="repository">
CollectionRepositoryRules = CollectionDatasetRules

