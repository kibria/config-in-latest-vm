<?xml version='1.0' encoding='UTF-8'?>

<!--
  Transformation of Solr query results to Atom+OpenSearch feed.
 -->

<xsl:stylesheet version='1.0'
                xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
                xmlns="http://www.w3.org/2005/Atom"
                xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/"
                xmlns:semantic="http://a9.com/-/opensearch/extensions/semantic/1.0/"
                xmlns:dt="http://a9.com/-/opensearch/extensions/time/1.0/"
                xmlns:custom="http://escenic.com/opensearchextensions/1.0/"
                xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:ui="http://xmlns.escenic.com/2008/interface-hints"
                xmlns:ece="http://www.escenic.com/2007/content-engine"
                xmlns:thr="http://purl.org/syndication/thread/1.0"
                xmlns:metadata="http://xmlns.escenic.com/2010/atom-metadata"
                xmlns:vdf="http://www.vizrt.com/types"
                xmlns:facet="http://xmlns.escenic.com/2015/facet"
                xmlns:app="http://www.w3.org/2007/app"
                xmlns:vaext="http://www.vizrt.com/atom-ext">

  <xsl:output media-type="application/atom+xml; charset=UTF-8" method="xml" encoding="UTF-8" />
  <xsl:variable name="base_uri" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='base_uri']"/>
  <xsl:variable name="top_link" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='top_link']"/>
  <xsl:variable name="filters" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='filters']"/>
  <xsl:template match='/'>
    <xsl:variable name="query" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='q']"/>
    <xsl:variable name="search_uri" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='search_uri']"/>
    <xsl:variable name="tags" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='tags']"/>
    <xsl:variable name="startIndex" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='start']"/>
    <xsl:variable name="numResults" select="response/result/@numFound"/>
    <xsl:variable name="wantedHitsPerPage" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='rows']"/>
    <xsl:variable name="hitsPerPage">
      <xsl:choose>
        <xsl:when test="$numResults &lt; $wantedHitsPerPage and $numResults &gt;= 0">
          <xsl:value-of select="$numResults"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$wantedHitsPerPage"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="numPages">
      <xsl:choose>
        <xsl:when test="$hitsPerPage != 0">
          <xsl:value-of select="ceiling($numResults div $hitsPerPage)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="0"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="currentPage">
      <xsl:choose>
        <xsl:when test="$hitsPerPage != 0">
          <xsl:value-of select="floor($startIndex div $hitsPerPage) + 1"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="lastPage">
      <xsl:choose>
        <xsl:when test="$numPages = 0">
          <xsl:value-of select="1"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$numPages"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <feed>
      <title><xsl:value-of select="$query"/></title>
      <author>
        <name>Escenic Content Engine</name>
      </author>
      <!-- First page number is __1__ -->
      <link rel="self" type="application/atom+xml" href="{$search_uri}?pw={$currentPage}&amp;c={$hitsPerPage}{$tags}{$filters}"/>
      <link rel="first" type="application/atom+xml" href="{$search_uri}?pw=1&amp;c={$hitsPerPage}{$tags}{$filters}"/>
      <xsl:if test="($currentPage) &lt; ($numPages)">
        <link rel="next" type="application/atom+xml" href="{$search_uri}?pw={$currentPage + 1}&amp;c={$hitsPerPage}{$tags}{$filters}"/>
      </xsl:if>
      <xsl:if test="($currentPage - 1) &gt; 0">
        <link rel="previous" type="application/atom+xml" href="{$search_uri}?pw={$currentPage - 1}&amp;c={$hitsPerPage}{$tags}{$filters}"/>
      </xsl:if>
      <link rel="last" type="application/atom+xml" href="{$search_uri}?pw={$lastPage}&amp;c={$hitsPerPage}{$tags}{$filters}"/>
      <updated>
        <xsl:value-of select="response/result/doc[position()=1]/date[@name='timestamp']"/>
      </updated>
      <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>
      <opensearch:totalResults><xsl:value-of select="$numResults"/></opensearch:totalResults>
      <opensearch:startIndex><xsl:value-of select="$startIndex"/></opensearch:startIndex>
      <opensearch:itemsPerPage><xsl:value-of select="$hitsPerPage"/></opensearch:itemsPerPage>
      <opensearch:Query role="request" searchTerms="{$query}" startPage="0" />
      <xsl:apply-templates select="response/result/doc"/>
      <facet:Group title="section"/>
      <xsl:apply-templates select="response/lst[@name='facet_counts']/lst[@name='facet_fields']/lst[@name='section']"/>
      <facet:Group title="contenttype"/>
      <xsl:apply-templates select="response/lst[@name='facet_counts']/lst[@name='facet_fields']/lst[@name='contenttype']"/>
      <facet:Group title="classification"/>
      <xsl:apply-templates select="response/lst[@name='facet_counts']/lst[@name='facet_fields']/lst[@name='classification']"/>
      <facet:Group title="author_username_s"/>
      <xsl:apply-templates select="response/lst[@name='facet_counts']/lst[@name='facet_fields']/lst[@name='author_username_s']"/>
      <facet:Group title="state"/>
      <xsl:apply-templates select="response/lst[@name='facet_counts']/lst[@name='facet_fields']/lst[@name='state']"/>
      <xsl:apply-templates select="response/lst[@name='facet_counts']/lst[@name='facet_queries']/int[starts-with(@name, 'state')]"/>
      <facet:Group title="creationdate" />
      <xsl:apply-templates select="response/lst[@name='facet_counts']/lst[@name='facet_ranges']/lst[@name='creationdate']/lst[@name='counts']"/>
      <xsl:apply-templates select="response/lst[@name='facet_counts']/lst[@name='facet_queries']/int[starts-with(@name, 'creationdate')]"/>
    </feed>
  </xsl:template>

  <!-- Match facet fields -->
  <xsl:template match="response/lst[@name='facet_counts']/lst[@name='facet_fields']/lst">
    <xsl:variable name="type" select="@name"/>
    <xsl:for-each select="int">
      <xsl:variable name="name" select="@name"/>
      <xsl:variable name="hitCount" select="."/>
      <opensearch:Query
              role="subset"
              custom:type="{$type}"
              semantic:related="{$name}"
              title="{$name}"
              totalResults="{$hitCount}"/>
    </xsl:for-each>
  </xsl:template>

  <!-- Match creationdate facets -->
  <xsl:template match="response/lst[@name='facet_counts']/lst[@name='facet_ranges']/lst[@name='creationdate']/lst[@name='counts']">
    <xsl:for-each select="int">
      <xsl:variable name="dtstart" select="@name"/>
      <xsl:variable name="hitCount" select="."/>
      <opensearch:Query
              role="subset"
              custom:type="date_facet"
              dt:start="{$dtstart}"
              totalResults="{$hitCount}"/>
    </xsl:for-each>
  </xsl:template>

  <!-- Match creationdate query facets -->
  <xsl:template match="response/lst[@name='facet_counts']/lst[@name='facet_queries']/int[starts-with(@name, 'creationdate')]">
      <xsl:variable name="dateQuery" select="substring-after(@name, ':')"/>
      <xsl:variable name="hitCount" select="."/>
      <opensearch:Query
              role="subset"
              custom:type="date_query_facet"
              dateQuery="{$dateQuery}"
              totalResults="{$hitCount}"/>
  </xsl:template>

  <!-- Match state query facets -->
  <xsl:template match="response/lst[@name='facet_counts']/lst[@name='facet_queries']/int[starts-with(@name, 'state')]">
      <xsl:variable name="stateQuery" select="substring-after(@name, ':')"/>
      <xsl:variable name="hitCount" select="."/>
      <opensearch:Query
              role="subset"
              custom:type="state_query_facet"
              stateQuery="{$stateQuery}"
              totalResults="{$hitCount}"/>
  </xsl:template>

  <!-- search results xslt -->
  <xsl:template match="doc">
    <xsl:variable name="id" select="str[@name='objectid']"/>
    <xsl:variable name="contenttype" select="str[@name='contenttype']"/>
    <xsl:variable name="edit_uri" select="str[@name='edit_uri']"/>
    <xsl:variable name="duration" select="double[@name='duration_double']"/>

    <xsl:variable name="entry_id">
      <xsl:choose>
        <xsl:when test="$contenttype = 'com.escenic.tag'">
          <xsl:value-of select="$id"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat('urn:', $contenttype, ':', $id)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <entry>
      <xsl:choose>
        <xsl:when test="$contenttype = 'com.escenic.tag'">
          <title type="html"><xsl:apply-templates mode="highlight" select="str[@name = 'title']"/></title>
        </xsl:when>
        <xsl:otherwise>
          <title><xsl:apply-templates mode="highlight" select="str[@name = 'title']"/></title>
        </xsl:otherwise>
      </xsl:choose>
      <link rel="edit" href="{concat($base_uri, $edit_uri)}"/>
      <link rel="self" href="{concat($base_uri, $edit_uri)}"/>
      <link rel="http://www.vizrt.com/types/relation/publication" type="application/atom+xml; type=entry">
        <xsl:attribute name="href">
          <xsl:value-of select="$base_uri"/>escenic/publication/<xsl:value-of select="str[@name = 'publication']"/>
        </xsl:attribute>
        <xsl:attribute name="title">
          <xsl:value-of select="str[@name = 'publication']"/>
        </xsl:attribute>
      </link>
      <link rel="http://www.escenic.com/types/relation/model" type="application/vnd.vizrt.model+xml">
        <xsl:attribute name="href">
          <xsl:value-of select="$base_uri"/>model/content-type/<xsl:value-of select="$contenttype"/>
        </xsl:attribute>
        <xsl:attribute name="title">
          <xsl:value-of select="$contenttype"/>
        </xsl:attribute>
      </link>
      <link rel="http://www.escenic.com/types/relation/summary-model" type="application/vnd.vizrt.model+xml">
        <xsl:attribute name="href">
          <xsl:value-of select="$base_uri"/>model/content-summary/<xsl:value-of select="$contenttype"/>
        </xsl:attribute>
        <xsl:attribute name="title">
          <xsl:value-of select="$contenttype"/>
        </xsl:attribute>
      </link>
      <xsl:if test="int[@name='home_section'] > 0">
        <link rel="http://www.vizrt.com/types/relation/home-section" type="application/atom+xml">
          <xsl:attribute name="href">
            <xsl:value-of select="$base_uri"/>escenic/section/<xsl:value-of select="int[@name = 'home_section']"/>
          </xsl:attribute>
          <xsl:attribute name="title">
            <xsl:value-of select="str[@name = 'home_section_name']"/>
          </xsl:attribute>
        </link>
      </xsl:if>

      <xsl:if test="$top_link = 'true'">
        <xsl:choose>
          <xsl:when test="$contenttype = 'com.escenic.section'">
            <xsl:variable name="publication" select="str[@name='publication']"/>
            <link href="{concat($base_uri, 'publication/', $publication, '/')}" rel="http://www.vizrt.com/types/relation/top" type="application/atom+xml; type=entry" title="{$publication}"/>
          </xsl:when>
          <xsl:when test="$contenttype = 'com.escenic.tag'">
            <xsl:variable name="tag_scheme" select="str[@name='tag_scheme']"/>
            <xsl:variable name="tag_scheme_name" select="str[@name='tag_scheme_name']"/>
            <link href="{concat($base_uri, 'escenic/classification/', $tag_scheme)}" rel="http://www.vizrt.com/types/relation/top" type="application/atom+xml; type=entry" title="{$tag_scheme_name}"/>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
      <xsl:if test="$contenttype = 'com.escenic.tag'">
        <xsl:variable name="tag_parent" select="str[@name='tag_parent']"/>
        <xsl:variable name="tag_child_count" select="int[@name='tag_child_count']"/>
        <xsl:choose>
          <xsl:when test="$tag_parent">
            <link rel="http://www.vizrt.com/types/relation/parent" href="{concat($base_uri, 'escenic/classification/tag/', $tag_parent)}"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="tag_scheme" select="str[@name='tag_scheme']"/>
            <link rel="http://www.vizrt.com/types/relation/parent" href="{concat($base_uri, 'escenic/classification/', $tag_scheme)}"/>
          </xsl:otherwise>
        </xsl:choose>
        <link rel="down" href="{concat($base_uri, 'escenic/classification/tag/children/', $id)}" thr:count="{$tag_child_count}"/>
        <link rel="http://www.vizrt.com/types/relation/merge" href="{concat($base_uri, 'escenic/classification/merge')}"/>
      </xsl:if>
      <id><xsl:value-of select="$entry_id"/></id>
      <xsl:for-each select="arr[@name = 'author']/str">
        <author>
          <name><xsl:value-of select="."/></name>
        </author>
      </xsl:for-each>
      <dcterms:created><xsl:value-of select="date[@name = 'creationdate']"/></dcterms:created>
      <published><xsl:value-of select="date[@name = 'publishdate']"/></published>
      <updated><xsl:value-of select="date[@name = 'lastmodifieddate']"/></updated>

      <xsl:choose>
        <xsl:when test="$contenttype = 'com.escenic.section'">
          <summary ui:align="right"><xsl:value-of select="str[@name = 'sectionpath']"/></summary>
        </xsl:when>
        <xsl:when test="$contenttype = 'com.escenic.tag'">
          <summary ui:align="right" type="html">
            <xsl:value-of select="str[@name = 'tag_path']"/>
            <xsl:variable name="document_id" select="str[@name='id']"/>
            <xsl:for-each select="/response/lst[@name='highlighting']/lst[@name=$document_id]/arr[@name='tag_alias']/str">
              <xsl:text> </xsl:text>
              <xsl:value-of select="."/>
            </xsl:for-each>
          </summary>
          <content type="application/vnd.vizrt.payload+xml">
            <vdf:payload xmlns:vdf="http://www.vizrt.com/types">
              <vdf:field name="aliases">
                <vdf:list>
                  <xsl:for-each select="arr[@name='tag_alias']/str">
                    <vdf:value><xsl:value-of select="."/></vdf:value>
                  </xsl:for-each>
                </vdf:list>
              </vdf:field>
            </vdf:payload>
          </content>
        </xsl:when>
        <xsl:otherwise>
          <summary><xsl:apply-templates mode="highlight" select="str[@name = 'summary']"/></summary>
        </xsl:otherwise>
      </xsl:choose>

      <ece:state><xsl:value-of select="str[@name = 'state']"/></ece:state>
      <xsl:if test="arr[@name='states_facet']">
        <app:control>
          <xsl:for-each select="arr[@name='states_facet']/*">
            <xsl:element name="state" namespace="http://www.vizrt.com/atom-ext"> <xsl:attribute name="name"><xsl:value-of select="."/></xsl:attribute></xsl:element>
          </xsl:for-each>
        </app:control>
      </xsl:if>
      <ece:type><xsl:value-of select="$contenttype"/></ece:type>
      <ece:duration><xsl:value-of select="$duration"/></ece:duration>

      <xsl:if test="int[@name='home_section'] > 0">
        <ece:home>
          <ece:uri><xsl:value-of select="$base_uri"/>content/com.escenic.section/<xsl:value-of select="int[@name = 'home_section']"/></ece:uri>
          <ece:name><xsl:value-of select="str[@name = 'home_section_name']"/></ece:name>
        </ece:home>
      </xsl:if>
      <ece:last_edited_by><xsl:value-of select="str[@name = 'last_edited_by']"/></ece:last_edited_by>
      <xsl:for-each select="arr[@name='extension_text']/*">
        <ece:extension><xsl:value-of select="."/></ece:extension>
      </xsl:for-each>
      <xsl:for-each select="arr[@name='thumbnail_id']/*">
        <link rel="thumbnail" href="{concat($base_uri,'thumbnail/article/',.)}"/>
      </xsl:for-each>

      <xsl:for-each select="arr[substring(@name, string-length(@name) - 13, 14) = '_relation_link']/*">
        <xsl:if test=". = 'com.escenic.edit-media'">
          <xsl:variable name="field" select="substring-before(../@name, '_relation_link')"/>
          <xsl:variable name="mimetype" select="../../arr[@name = concat($field, '_mime-type_link')]/*" />
          <xsl:if test="substring-before($mimetype, '/') = 'image'">
            <link rel="edit-media" href="{concat($base_uri,'binary/',$contenttype,'/',$id)}" type="{$mimetype}" />
          </xsl:if>
        </xsl:if>
      </xsl:for-each>

      <xsl:if test="$contenttype = 'com.escenic.person'">
        <vdf:payload>
          <xsl:attribute name="model"><xsl:value-of select="$base_uri"/>model/content-type/<xsl:value-of select="$contenttype"/></xsl:attribute>
          <xsl:if test="arr[@name='occupation_s_text']">
            <vdf:field name="com.escenic.occupation">
              <vdf:value><xsl:value-of select="arr[@name='occupation_s_text']"/></vdf:value>
            </vdf:field>
          </xsl:if>
          <xsl:if test="arr[@name='phoneprivate_s_text']">
            <vdf:field name="com.escenic.phonePrivate">
              <vdf:value><xsl:value-of select="arr[@name='phoneprivate_s_text']"/></vdf:value>
            </vdf:field>
          </xsl:if>
          <xsl:if test="arr[@name='phonemobile_s_text']">
            <vdf:field name="com.escenic.phoneMobile">
              <vdf:value><xsl:value-of select="arr[@name='phonemobile_s_text']"/></vdf:value>
            </vdf:field>
          </xsl:if>
          <xsl:if test="arr[@name='phonework_s_text']">
            <vdf:field name="com.escenic.phoneWork">
              <vdf:value><xsl:value-of select="arr[@name='phonework_s_text']"/></vdf:value>
            </vdf:field>
          </xsl:if>
          <xsl:if test="arr[@name='emailaddress_s_text']">
            <vdf:field name="com.escenic.emailAddress">
              <vdf:value><xsl:value-of select="arr[@name='emailaddress_s_text']"/></vdf:value>
            </vdf:field>
          </xsl:if>
        </vdf:payload>
      </xsl:if>
    </entry>
  </xsl:template>

  <!--Handle hightlighting. If some document matches the ID, replace the named field with the hightlighted content,
   otherwise do nothing.
    TODO: Current solr implementation does not support highlighing with wildcards.
   -->
  <xsl:template match="*" mode="highlight">
    <xsl:variable name="id" select="../str[@name='id']"/>
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="field_orig_value" select="."/>
    <xsl:variable name="field_value" select="/response/lst[@name='highlighting']/lst[@name=$id]/arr[@name=$name]/str/text()"/>

    <xsl:choose>
      <xsl:when test="string-length($field_value) &gt; 0">
        <xsl:value-of select="$field_value"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$field_orig_value"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
