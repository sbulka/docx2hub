<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:docx2hub="http://transpect.io/docx2hub"
  exclude-result-prefixes="xs docx2hub"
  version="2.0">
  
  <xsl:template match="w:styles/w:style" exclude-result-prefixes="#all" mode="docx2hub:preprocess-styles">
    <!-- (w:style)* -->
    <xsl:variable name="self" select="."/>
    <xsl:variable name="doc-styles" select=".."/>
    <xsl:for-each select="('', w:tblStylePr/@w:type)">
      <xsl:variable name="stripped-style" as="node()">
        <w:style>
          <xsl:sequence select="$self/@* except $self/@w:styleId"/>
          <xsl:attribute name="w:styleId" select="($self[current() = '']/@w:styleId, concat($self/@w:styleId, '-', .))[1]"/>
          <xsl:variable name="bare-props" select="$self/node()[not(self::w:tblStylePr)]" as="node()*"/>
          <xsl:sequence
            select="docx2hub:consolidate-style-properties($self/node()[self::w:tblStylePr[@w:type = current()]]/node(), $bare-props)"
          />
        </w:style>
      </xsl:variable>
      <xsl:element name="{$self/name()}">
        <xsl:sequence
          select="$stripped-style/@*, docx2hub:get-style-properties($stripped-style, $doc-styles)[not(self::w:basedOn or self::w:tblStylePr)]"
        />
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  
  <!--<xsl:template match="w:tbl/w:tblPr[w:tblStyle]" mode="docx2hub:preprocess-styles">
    <xsl:variable name="style-name" select="w:tblStyle/@w:val" as="xs:string"/>
    <xsl:variable name="apply-styles" select="'', /w:root/w:styles//w:style[@w:styleId = $style-name]/w:tblStylePr/@w:type" as="xs:string+"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each select="$apply-styles">
        <xsl:element name="w:tblStyle">
          <xsl:attribute name="w:val">
            <xsl:sequence
              select="($style-name[current() = ''], concat($style-name, '-', .))[1], ' '[not(last())]"/>
          </xsl:attribute>
        </xsl:element>
      </xsl:for-each>
      <xsl:apply-templates select="node() except w:tblStyle" mode="#current"/>
    </xsl:copy>
  </xsl:template>-->
  
  <xsl:function name="docx2hub:get-style-properties" as="node()*">
    <xsl:param name="style" as="node()"/><!-- w:style -->
    <xsl:param name="styles" as="node()*"/><!-- (w:style)* -->
    <xsl:variable name="based-on" select="$style/w:basedOn/@w:val"/>
    <xsl:variable name="resolved-parent-style"
      select="if ($based-on) then docx2hub:get-style-properties($styles/node()[@w:styleId = $based-on], $styles) else ()"
      as="node()*"/>
    <xsl:sequence select="docx2hub:consolidate-style-properties($style/node(), $resolved-parent-style)"/>
  </xsl:function>

  <xsl:function name="docx2hub:consolidate-style-properties" as="node()*">
    <xsl:param name="style1" as="node()*"/>
    <xsl:param name="style2" as="node()*"/>
    <xsl:for-each select="$style1">
      <xsl:variable name="ptype" select="concat(local-name(), @w:type)"/>
      <xsl:choose>
        <xsl:when test="not(node()) and @*">
          <!-- copy flat prop from style1 -->
          <xsl:sequence select="."/>
        </xsl:when>
        <xsl:otherwise>
          <!-- recursive for nested props -->
          <xsl:element name="{name()}">
            <xsl:sequence select="@*"/>
            <xsl:sequence
              select="docx2hub:consolidate-style-properties(node(), $style2[concat(local-name(), @w:type) = $ptype]/node())"
            />
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:for-each select="$style2">
      <xsl:variable name="ptype" as="xs:string"
        select="concat('', local-name(), @w:type[count($style1/node()[local-name() = current()/local-name()]) gt 1])"/>
      <xsl:choose>
        <xsl:when test="$style1[concat('', local-name(), @w:type[count($style1/node()[local-name() = current()/local-name()]) gt 1]) = $ptype]">
          <!-- this one was copied from style1 already -->
        </xsl:when>
        <xsl:otherwise>
          <!-- props added by style2 -->
          <xsl:sequence select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>

  <xsl:template match="w:tbl/w:tr" mode="docx2hub:resolve-tblBorders">
    <xsl:next-match>
      <xsl:with-param name="tr-pos" select="position() - count(../* except ../w:tr)" tunnel="yes"/>
    </xsl:next-match>
  </xsl:template>
  
  <xsl:template match="w:tbl/w:tr/w:tc" mode="docx2hub:resolve-tblBorders">
    <xsl:next-match>
      <xsl:with-param name="tc-pos" select="position() - count(../* except ../w:tc)" tunnel="yes"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="w:tbl/w:tr/w:tc/w:tcPr" mode="docx2hub:resolve-tblBorders">
    <xsl:param name="tr-pos" tunnel="yes"/>
    <xsl:param name="tc-pos" tunnel="yes"/>
    <xsl:variable name="self" select="."/>
    <xsl:variable name="pos" select="$tc-pos, $tr-pos, count(../../w:tc), ../../../count(w:tr)" as="xs:decimal+">
        <!-- values are: tc-pos, tr-pos, last-tc, last-tr -->
    </xsl:variable>
    <xsl:variable name="style-name" as="xs:string*">
      <xsl:variable name="prefix" select="../../../w:tblPr/w:tblStyle/@w:val"/>
      <xsl:variable name="lk" as="xs:boolean+"
      select="
      ((../../../w:tblPr/w:tblLook, ../../w:tblPrEx/w:tblBorders)/@w:firstRow)[1] = (1, 'true'),
      ((../../../w:tblPr/w:tblLook, ../../w:tblPrEx/w:tblBorders)/@w:firstColumn)[1] = (1, 'true'),
      ((../../../w:tblPr/w:tblLook, ../../w:tblPrEx/w:tblBorders)/@w:lastRow)[1] = (1, 'true'),
      ((../../../w:tblPr/w:tblLook, ../../w:tblPrEx/w:tblBorders)/@w:lastColumn)[1] = (1, 'true')"/>
      <xsl:variable name="suffix" as="xs:string*">
        <xsl:variable name="possible-suffixes" as="xs:string*">
          <xsl:choose>
            <xsl:when test="$lk[2] and $lk[1] and $pos[1] eq 1 and $pos[2] eq 1">
              <xsl:sequence select="'nwCell', 'firstRow', 'firstCol'"/>
            </xsl:when>
            <xsl:when test="$lk[2] and $lk[3] and $pos[1] eq 1 and $pos[2] eq $pos[4]">
              <xsl:sequence select="'swCell', 'lastRow', 'firstCol'"/>
            </xsl:when>
            <xsl:when test="$lk[4] and $lk[1] and $pos[1] eq $pos[3] and $pos[2] eq 1">
              <xsl:sequence select="'neCell', 'firstRow', 'lastCol'"/>
            </xsl:when>
            <xsl:when test="$lk[4] and $lk[3] and $pos[1] eq $pos[3] and $pos[2] eq $pos[4]">
              <xsl:sequence select="'seCell', 'lastRow', 'lastCol'"/>
            </xsl:when>
            <xsl:when test="$lk[2] and $pos[1] eq 1">
              <xsl:sequence select="'firstCol'"/>
            </xsl:when>
            <xsl:when test="$lk[1] and $pos[2] eq 1">
              <xsl:sequence select="'firstRow'"/>
            </xsl:when>
            <xsl:when test="$lk[3] and $pos[1] eq $pos[3]">
              <xsl:sequence select="'lastRow'"/>
            </xsl:when>
            <xsl:when test="$lk[4] and $pos[2] eq $pos[4]">
              <xsl:sequence select="'lastCol'"/>
            </xsl:when>
            <!-- TODO: H/V-banding props -->
            <xsl:otherwise/>
          </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="for $s in $possible-suffixes return $s[exists($self/ancestor::*[last()]//w:style[@w:styleId = concat($prefix, '-', $s)])]"/>
      </xsl:variable>
      <xsl:sequence select="$prefix[empty($suffix)] ,for $s in $suffix return string-join(($prefix, ('-', $s)[not($s= '')]), '')"/>
    </xsl:variable>
    <!--<xsl:comment>
      <xsl:value-of select="$style-name" separator="  |  "/>
    </xsl:comment>-->
    <xsl:variable name="style" select="for $s in $style-name return $self/ancestor::*[last()]//w:style[@w:styleId = concat('', $s)]" as="element()*"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:element name="w:tcBorders">
        <xsl:for-each select="'top','left','bottom','right'">
          <xsl:variable name="outer-border" select="
            (. = 'top' and $pos[2] eq 1) or
            (. = 'left' and $pos[1] eq 1) or
            (. = 'bottom' and $pos[2] eq $pos[4]) or
            (. = 'right' and $pos[1] eq $pos[3])" as="xs:boolean"/>
          <xsl:variable name="tblBorder-by-style" as="element()?">
            <xsl:variable name="borders"
              select="$style/w:tblPr/w:tblBorders, $style/w:tcPr/w:tcBorders"/>
            <xsl:element name="w:{.}">
              <xsl:choose>
                <xsl:when test="$outer-border">
                  <xsl:sequence
                    select="($borders/w:*[local-name() = current()])[last()]/@*"
                  />
                </xsl:when>
                <!-- inner tcBorder -->
                <xsl:otherwise>
                  <xsl:sequence
                    select="($borders/w:insideH[current() = ('top', 'bottom')])[1]/@*, ($borders/w:insideV[current() = ('left', 'right')])[1]/@*"
                  />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:element>
          </xsl:variable>
          <xsl:variable name="ancestors" select="
            $self/../../w:tblPrEx/w:tblBorders[$outer-border],
            $self/../../../w:tblPr/w:tblBorders[$outer-border],
            $style/w:tcPr/w:tcBorders"/>
          <xsl:variable name="adhoc-border"
            select="(($self/w:tcBorders, $ancestors)/w:*[local-name() = current()])[1]"
            as="element()?"
          />
          <xsl:variable name="border">
            <xsl:choose>
              <xsl:when test="exists($adhoc-border)">
                <xsl:sequence select="$adhoc-border"/>
              </xsl:when>
              <xsl:when test="exists($tblBorder-by-style)">
                <xsl:sequence select="$tblBorder-by-style"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:element name="w:{.}">
                  <xsl:attribute name="w:val" select="'nil'"/>
                </xsl:element>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:apply-templates select="$border" mode="#current"/>
        </xsl:for-each>
      </xsl:element>
      <xsl:apply-templates select="node() except w:tcBorders"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
