# Future

I have no immediate plans to rewrite this app. But if I did, some
of the possibilities are presented below.

## Option 1 - Using XSLT 1.0

1. Manage OAI-PMH resumption token using Ruby. [Same]
1. Extract each RIF-CS record into an individual file using Ruby. [Same]
1. Use XSLT 1.0 to convert each RIF-CS (XML) file into HTML. [New]
1. Perhaps use Ruby to find URLs and wrap them in HTML hyperlinks
   (as this is a task ideally suited to a function or macro and
   XSLT 1.0 does not support functions unless EXSLT is included
   in the implementation). [Rewrite]

You can see a very rough example which I have tested using xsltproc
and Firefox 25.0 (both under Linux Fedora release 20).
- XSLT file: party_rif1.xsl
- RIF-CS file: party_rif1.xml -- derived from
  http://ands.org.au/guides/cpguide/cpgparty.html; RIF-CS examples;
  Example of a party record for a person (fictional record)

## Option 2 - Using XSLT 2.0

1. Manage OAI-PMH resumption token using Ruby. [Same]
1. Extract each RIF-CS record into an individual file using XSLT 2.0. [New]
1. Use XSLT 2.0 to convert each RIF-CS (XML) file into HTML. [New]
1. Use XSLT 2.0 to wrap URLs in HTML hyperlinks (as this is a task ideally
   suited to a function or macro and XSLT 2.0 supports functions). [New]

You can see a very rough example which I have tested using the
Saxon processor and Firefox 25.0 (both under Linux Fedora release 20).
The folder *xslt2_single_file* shows these XSLT2 features except
for writing each RIF-CS record into an individual file.
- XSLT file: party_rif2.xsl
- RIF-CS file: party_rif2.xml -- derived from
  http://ands.org.au/guides/cpguide/cpgparty.html; RIF-CS examples;
  Example of a party record for a person (fictional record)

You can see a very rough example which I have tested using the
Saxon processor and Firefox 25.0 (both under Linux Fedora release 20).
The folder *xslt2_multi_file* shows all these XSLT2 features
including writing each RIF-CS record into an individual file.
- XSLT file: oai_parties_rif.xsl
- RIF-CS file: oai_parties_rif.xml -- derived from
  http://ands.org.au/guides/cpguide/cpgparty.html; RIF-CS examples;
  Example of a party record for a person (fictional record)

