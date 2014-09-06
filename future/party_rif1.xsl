<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="4.0"/>

  <!-- Root template -->
  <xsl:template match="/">

    <xsl:variable name="heading_str">
      <xsl:value-of select="'XSLT 1.0: RIF-CS to HTML example'"/>
    </xsl:variable>

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
      This is a XSLT 1.0 example without using EXSLT.
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

  <xsl:apply-templates select="/registryObjects/registryObject/key|/registryObjects/registryObject/originatingSource"/>

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
    <tr>
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
        <xsl:value-of select="key"/>
      </td>
    </tr>
    <tr>
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
        <xsl:value-of select="identifier"/>
      </td>
    </tr>
    <tr>
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
        <xsl:value-of select="."/>
      </td>
    </tr>
    <tr>
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
      </td>

      <td>
        <xsl:variable name="node_value">
          <xsl:value-of select="."/>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="starts-with($node_value, 'http://') or starts-with($node_value, 'https://')">
            <!-- String is a URL; display as a hyperlink -->
            <a>
              <xsl:attribute name="href">
                <xsl:copy-of select="$node_value" />
              </xsl:attribute>
              <xsl:copy-of select="$node_value" />
            </a>
          </xsl:when>
          <xsl:otherwise>
            <!-- String is not a URL; display without modification -->
            <xsl:copy-of select="$node_value" />
          </xsl:otherwise>
        </xsl:choose>

      </td>
    </tr>
  </xsl:template>

</xsl:stylesheet>

