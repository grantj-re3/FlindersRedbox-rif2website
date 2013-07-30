# Rules for rif2website.rb
# All assignments within this file are ruby script commands
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

  #[ 2490, :showinfo_url_ands_reg,	"Record <em>may</em> exist at the ANDS Online Services Collections Registry",	"header/identifier", ],
  [ 2490, :showinfo_url_ands_rda,	"Record <em>may</em> exist at Research Data Australia",				"header/identifier", ],
  [ 2495, :showinfo_url_ands_reg,	"Record <em>may</em> exist at the ANDS Online Services Collections Registry",	"header/identifier", ],
]

##############################################################################
# A set of rules suitable for record-types: activity, party, service.
##############################################################################
GenericRules_ActivityPartyService = [
# [ Sort, ActionMethod,			Label,			XPath, ],
  [ 2040, :show_tavalues_tevalues,	"Name (part)",		"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/name/namePart", ],
  [ 2060, :show_tavalues_tevalues,	"Key",			"registryObjects/registryObject/key", ],
  [ 2100, :show_tavalues_tevalues,	"Identifier",		"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/identifier", ],
  [ 2200, :show_tavalues_cevalues,	"Address (electronic)",	"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/location/address/electronic", ],
  [ 2202, :show_tavalues_tevalues,	"Address (physical)",	"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/location/address/physical/addressPart", ],

  [ 2220, :show_tavalues_tevalues,	"Subject",		"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/subject", ],
  [ 2240, :show_tavalues_tevalues,	"Description",		"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/description", ],
  [ 2260, :showelement_related_object,	"Related Object",	"registryObjects/registryObject/[[PRIMARY_RECORD_TYPE_TAG]]/relatedObject", ],

  [ 2360, :show_tanames_tavalues,	"Registry Object",	"registryObjects/registryObject", ],
  ##[ 2380, :show_tavalues_tevalues,	"Originating Source",	"registryObjects/registryObject/originatingSource", ],

  [ 2470, :showinfo_repo_name,		"Repository name",	"", ],
  [ 2480, :showinfo_repo_oid,		"Repository object ID",	"", ],

  [ 2490, :showinfo_url_ands_rda,	"Record <em>may</em> exist at Research Data Australia",				"registryObjects/registryObject/key", ],

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
# INCOMPLETE!
# Processing rules for RIFCS record type <service type="create">
ServiceCreateRules = GenericRules_ActivityPartyService

##############################################################################
# Collections
##############################################################################
# INCOMPLETE! relatedInfo, ...
# Processing rules for RIFCS record type <collection type="dataset">

CollectionDatasetRules = [
# [ Sort, ActionMethod,			Label,			XPath, ],
  [ 2040, :show_tavalues_tevalues,	"Name (part)",		"registryObjects/registryObject/collection/name/namePart", ],
  [ 2060, :show_tavalues_tevalues,	"Key",			"registryObjects/registryObject/key", ],

  [ 2100, :show_tavalues_tevalues,	"Identifier",		"registryObjects/registryObject/collection/identifier", ],
  [ 2200, :show_tavalues_cevalues,	"Address (electronic)",	"registryObjects/registryObject/collection/location/address/electronic", ],
  [ 2202, :show_tavalues_tevalues,	"Address (physical)",	"registryObjects/registryObject/collection/location/address/physical/addressPart", ],

  [ 2204, :show_tavalues_tevalues,	"Coverage (spatial)",	"registryObjects/registryObject/collection/coverage/spatial", ],
  [ 2206, :show_tavalues_tevalues,	"Coverage (temporal)",	"registryObjects/registryObject/collection/coverage/temporal/date", ],

  [ 2220, :show_tavalues_tevalues,	"Subject",		"registryObjects/registryObject/collection/subject", ],
  [ 2240, :show_tavalues_tevalues,	"Description",		"registryObjects/registryObject/collection/description", ],
  [ 2260, :showelement_related_object,	"Related Object",	"registryObjects/registryObject/collection/relatedObject", ],

  [ 2280, :show_tavalues_tevalues,	"Rights Statement",	"registryObjects/registryObject/collection/rights/rightsStatement", ],
  [ 2290, :show_tavalues_tevalues,	"Access Rights",	"registryObjects/registryObject/collection/rights/accessRights", ],
  [ 2300, :showelement_related_info,	"Related Information",	"registryObjects/registryObject/collection/relatedInfo", ],

  [ 2360, :show_tanames_tavalues,	"Registry Object",	"registryObjects/registryObject", ],
  ##[ 2380, :show_tavalues_tevalues,	"Originating Source",	"registryObjects/registryObject/originatingSource", ],

  [ 2470, :showinfo_repo_name,		"Repository name",	"", ],
  [ 2480, :showinfo_repo_oid,		"Repository object ID",	"", ],

  #[ 2490, :showinfo_url_ands_reg,	"Record <em>may</em> exist at the ANDS Online Services Collections Registry",	"registryObjects/registryObject/key", ],
  [ 2490, :showinfo_url_ands_rda,	"Record <em>may</em> exist at Research Data Australia",				"registryObjects/registryObject/key", ],

]

# Processing rules for RIFCS record type <collection type="collection">
CollectionCollectionRules = CollectionDatasetRules

# Processing rules for RIFCS record type <collection type="catalogueOrIndex">
CollectionCatalogueOrIndexRules = CollectionDatasetRules

# Processing rules for RIFCS record type <collection type="registry">
CollectionRegistryRules = CollectionDatasetRules

# Processing rules for RIFCS record type <collection type="repository">
CollectionRepositoryRules = CollectionDatasetRules

