<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:docx2hub="http://transpect.io/docx2hub"
  exclude-result-prefixes="xs" version="2.0">
  <xsl:output indent="yes"/>

  <xsl:function name="docx2hub:generate-border-elements">
    <xsl:param name="name" as="xs:string"/>
    <xsl:variable name="val" select="'none', 'solid'" as="xs:string+"/>
    <xsl:variable name="sz" select="2, 8, 12" as="xs:decimal+"/>
    <xsl:for-each select="$val">
      <xsl:variable name="v" select="."/>
      <xsl:for-each select="$sz">
        <xsl:element name="w:{$name}">
          <xsl:attribute name="w:val" select="$v"/>
          <xsl:attribute name="w:sz" select="."/>
        </xsl:element>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:function>

  <xsl:template name="main">
    <x:description xmlns:x="http://www.jenitennison.com/xslt/xspec" xmlns:mml="http://www.w3.org/1998/Math/MathML"
      xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
      xmlns:docx2hub="http://transpect.io/docx2hub" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
      stylesheet="../xsl/main.xsl">
      <x:param name="debug" select="'no'"/>
      <x:scenario label="tblBorders get copied to tcBorders">
        <x:scenario label="when all tblBorders are defined">
          <x:scenario label="and no tcBorders are defined">

            <xsl:for-each select="docx2hub:generate-border-elements('top')">
              <xsl:variable name="top" select="."/>
              <x:scenario label="with top/@val='{@w:val}' and top/@sz={@w:sz}">
                <xsl:for-each select="docx2hub:generate-border-elements('left')">
                  <xsl:variable name="left" select="."/>
                  <x:scenario label="with left/@val='{@w:val}' and left/@sz={@w:sz}">
                    <xsl:for-each select="docx2hub:generate-border-elements('bottom')">
                      <xsl:variable name="bottom" select="."/>
                      <x:scenario label="with bottom/@val='{@w:val}' and bottom/@sz={@w:sz}">
                        <xsl:for-each select="docx2hub:generate-border-elements('right')">
                          <x:scenario label="with right/@val is {@w:val} and right/@sz is {@w:sz}">
                            <x:context mode="docx2hub:resolve-tblBorders">
                              <w:tbl>
                                <w:tblPr>
                                  <w:tblBorders>
                                    <xsl:sequence select="$top"/>
                                    <xsl:sequence select="$left"/>
                                    <xsl:sequence select="$bottom"/>
                                    <xsl:sequence select="."/>
                                  </w:tblBorders>
                                </w:tblPr>
                                <w:tr>
                                  <w:tc>
                                    <w:tcPr/>
                                  </w:tc>
                                </w:tr>
                              </w:tbl>
                            </x:context>
                            <x:expect label="all Border gets copied">
                              <w:tbl>
                                <w:tblPr> 
                                <w:tblBorders>
                                    <xsl:sequence select="$top"/>
                                    <xsl:sequence select="$left"/>
                                    <xsl:sequence select="$bottom"/>
                                    <xsl:sequence select="."/>
                                  </w:tblBorders></w:tblPr>
                                <w:tr>
                                  <w:tc>
                                    <w:tcPr>
                                      <w:tcBorders>
                                        <xsl:sequence select="$top"/>
                                        <xsl:sequence select="$left"/>
                                        <xsl:sequence select="$bottom"/>
                                        <xsl:sequence select="."/>
                                      </w:tcBorders>
                                    </w:tcPr>

                                  </w:tc>
                                </w:tr>
                              </w:tbl>
                            </x:expect>

                          </x:scenario>
                        </xsl:for-each>
                      </x:scenario>
                    </xsl:for-each>
                  </x:scenario>
                </xsl:for-each>
              </x:scenario>
            </xsl:for-each>
          </x:scenario>
        </x:scenario>
      </x:scenario>
    </x:description>
  </xsl:template>







</xsl:stylesheet>
