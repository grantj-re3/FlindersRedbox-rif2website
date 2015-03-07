<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="4.0"/>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Custom function-behaviour: Write string argument as a hyperlink -->
  <xsl:template name="toHyperlink">
    <xsl:param name="url_string"/>

    <a>
      <xsl:attribute name="href">
        <xsl:value-of select="$url_string" />
      </xsl:attribute>
      <xsl:value-of select="$url_string" />
    </a>

  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Custom function-behaviour: If string is a URL, write it in a hyperlink -->
  <xsl:template name="toHyperlinkIfUrl">
    <xsl:param name="text_or_url"/>

    <xsl:choose>
      <xsl:when test="starts-with($text_or_url, 'http://') or starts-with($text_or_url, 'https://')">
        <xsl:call-template name="toHyperlink">
          <xsl:with-param name="url_string" select="$text_or_url"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$text_or_url" />
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Root template -->
  <xsl:template match="/">
    <xsl:variable name="heading_str" as="xs:string" select="'XSLT 1.0: RIF-CS to HTML example'"/>
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
      <p>This is a XSLT 1.0 example without using EXSLT.</p>
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
        <xsl:call-template name="toHyperlinkIfUrl">
          <xsl:with-param name="text_or_url" select="key"/>
        </xsl:call-template>
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
        <xsl:call-template name="toHyperlinkIfUrl">
          <xsl:with-param name="text_or_url" select="identifier"/>
        </xsl:call-template>
      </td>
    </tr>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Show one row of a 3-column table -->
  <xsl:template match="identifier">
    <tr>
      <td>
        Identifier
      </td>
      <td>
        <xsl:value-of select="@type"/>
      </td>
      <td>
        <xsl:call-template name="toHyperlinkIfUrl">
          <xsl:with-param name="text_or_url" select="current()"/>
        </xsl:call-template>
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
        <xsl:call-template name="toHyperlinkIfUrl">
          <xsl:with-param name="text_or_url" select="current()"/>
        </xsl:call-template>
      </td>
    </tr>
  </xsl:template>

</xsl:stylesheet>

