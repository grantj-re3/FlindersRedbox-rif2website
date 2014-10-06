<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xdt="http://www.w3.org/2005/xpath-datatypes" xmlns:cust="http://my_custom_functions" version="2.0">

  <xsl:output method="html" version="4.0"/>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Custom function: Return string argument as a hyperlink -->
  <xsl:function name="cust:toHyperlink">
    <xsl:param name="url_string"/>

    <a>
      <xsl:attribute name="href">
        <xsl:value-of select="$url_string" />
      </xsl:attribute>
      <xsl:value-of select="$url_string" />
    </a>

  </xsl:function>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Custom function: If string is a URL, return it in a hyperlink -->
  <xsl:function name="cust:toHyperlinkIfUrl">
    <xsl:param name="str"/>

    <xsl:choose>
      <xsl:when test="matches($str, '^(http|https)://')">
        <xsl:sequence select="cust:toHyperlink($str)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$str" />
      </xsl:otherwise>
    </xsl:choose>

  </xsl:function>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Root template -->
  <xsl:template match="/">
    <xsl:variable name="heading_str" as="xs:string" select="'XSLT 2.0: RIF-CS to HTML example'" />

    <html>
    <head>
      <title><xsl:copy-of select="$heading_str" /></title>

      <style>
        table,th,td {
          border:1px solid black;
        }
      </style>
    </head>
    <body>
      <h2><xsl:copy-of select="$heading_str" /></h2>
      <p>This is a XSLT 2.0 example using a custom function.</p>
      <xsl:apply-templates select="/registryObjects/registryObject/party"/>
    </body>
    </html>

  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Build a table -->
  <xsl:template match="party">
    <h3><xsl:value-of select = "local-name()" />-<xsl:value-of select="@type" /></h3>

    <table>
    <tr>
      <th>Field</th>
      <th>Aux. field</th>
      <th>Value</th>
    </tr>

    <xsl:apply-templates select="name/namePart"/>
    <xsl:apply-templates select="relatedObject"/>
    <xsl:apply-templates select="relatedInfo"/>
    <xsl:apply-templates select="identifier"/>

    <xsl:apply-templates select="/registryObjects/registryObject/key | /registryObjects/registryObject/originatingSource"/>

    </table>
  </xsl:template>


  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Show one row of a 3-column table -->
  <xsl:template match="namePart">
    <tr>
      <td>
        <strong><em>Name</em></strong>
      </td>
      <td>
        <strong><em><xsl:value-of select="@type"/></em></strong>
      </td>
      <td>
        <strong><em><xsl:value-of select="."/></em></strong>
      </td>
    </tr>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Show one row of a 3-column table -->
  <xsl:template match="relatedObject">
    <tr>
      <td>
        Related Object
      </td>
      <td>
        <xsl:value-of select="relation/@type"/>
      </td>
      <td>
        <xsl:variable name="key" as="xs:string" select="key"/>
        <xsl:sequence select="cust:toHyperlinkIfUrl($key)" />
      </td>
    </tr>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Show one row of a 3-column table -->
  <xsl:template match="relatedInfo">
    <tr>
      <td>
        Related Information
      </td>
      <td>
        <xsl:value-of select="identifier/@type"/>
      </td>
      <td>
        <xsl:variable name="id" as="xs:string" select="identifier"/>
        <xsl:sequence select="cust:toHyperlinkIfUrl($id)" />
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="identifier">
    <tr>
      <td>
        Identifier
      </td>
      <td>
        <xsl:value-of select="@type"/>
      </td>
      <td>
        <xsl:sequence select="cust:toHyperlinkIfUrl(current())" />
      </td>
    </tr>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Show one row of a 3-column table -->
  <!-- Show element-name & element-value (enclosing the later in an anchor if applicable) -->
  <xsl:template match="key|originatingSource">
    <tr>
      <td>
        <xsl:value-of select = "local-name()" /> 
      </td>

      <td>
        &#160;
      </td>

      <td>
        <xsl:sequence select="cust:toHyperlinkIfUrl(current())" />
      </td>
    </tr>
  </xsl:template>

</xsl:stylesheet>

