<%@ Control Language="VB" %>
<%@ Import Namespace="ddCommon" %>
<script runat="server">
	Public Title As String = ""
	Public Keywords As String = ""
	Public Description As String = ""
	
	Public DisplayPage As IDisplayPageMetaData
	
	Private ClientName As String = "PPCGB"
	Private TitleDefault As String = ""
	Private KeywordsDefault As String = ""
	Private DescriptionDefault As String = ""
	
	Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
		'Specifically defined Title, Keywords and Descriptions get precendence over all others
		Dim sTitle As String = ""
		Dim sKeywords As String = ""
		Dim sDescription As String = ""
		
		if DisplayPage isnot nothing then
            me.title = DisplayPage.MetaTitle
            me.keywords = DisplayPage.SEO.MetaKeywords
            me.description = DisplayPage.MetaDescription
		end if

		if Title.ToString.Length > 0 then sTitle = Title
		if sTitle.Length = 0 then sTitle = TitleDefault
		
		if Keywords.ToString.Length > 0 then sKeywords = Keywords
		if sKeywords.Length = 0 then sKeywords = KeywordsDefault
		
		if Description.ToString.Length > 0 then sDescription = Description
		if sDescription.Length = 0 then sDescription = DescriptionDefault
		
		litTitle.Text = sTitle & iif(sTitle.length > 0, " - ", "")
		litKeywords.Text = "<meta name=""Keywords"" content=""" & sKeywords & """ />"
		litDescription.Text = "<meta name=""Description"" content=""" & sDescription & """ />"
	End Sub

</script>

	<title><asp:Literal ID="litTitle" runat="server" /><%=ClientName%></title>
	
	<asp:Literal ID="litKeywords" runat="server" />
	<asp:Literal ID="litDescription" runat="server" />
	
	<meta name="robots" content="<%=iif(commonRegistry.isDevSite, "noindex,nofollow", "follow,index")%>" />
	<meta name="author" content="Datadial Ltd" />
	
	<!--link rel="shortcut icon" href="/img/favicon.jpg" /-->
	
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>

	<%' <foundation> %>
			<meta charset="utf-8" />
			<meta name="viewport" content="width=device-width" />
			<link rel="stylesheet" href="/foundation/stylesheets/foundation.css">
			<!--link rel="stylesheet" href="/foundation/stylesheets/foundation.min.css"-->
			<script src="/foundation/javascripts/modernizr.foundation.js"></script>
			<script src="/foundation/javascripts/foundation.min.js"></script>
			<script src="/foundation/javascripts/app.js"></script>
			
			<link rel="stylesheet" href="/foundation-extras/foundation-extras.css">
			<script type="text/javascript" src="/foundation-extras/foundation-extras.js"></script>
			<script type="text/javascript">
				$(function(){
					$.foundationExtras(); /* see foundation-extras.js for optional config */
				});
			</script>
	<%' </foundation> %>
	
	<%' <site styling and operations> %>
			<link rel="stylesheet" href="/css/base.css">
			<link rel="stylesheet" href="/css/site.css">
			<script type="text/javascript" src="/js/site.js"></script>
	<%' </site styling and operations> %>
	
	<link rel="stylesheet" href="/js/compactMobileNav/compactMobileNav.css">
	<script type="text/javascript" src="/js/compactMobileNav/compactMobileNav.js"></script>

	<script type="text/javascript" src="/js/common.js"></script>

	<script type="text/javascript" src="/js/json/json2.js"></script>
	
	<script type="text/javascript" src="/js/uiState/uiState.js"></script>

	<script type="text/javascript" src="/js/jquery-validation-1.9.0/jquery.validate.js"></script>
	
	<!--script type="text/javascript" src="/js/tiny_mce/jquery.tinymce.js"></script>
	
	<script type="text/javascript" src="/js/datadial/common.js"></script>
	<script type="text/javascript" src="/js/datadial/function-extensions.js"></script>
	<script type="text/javascript" src="/js/datadial/ui-extensions.js"></script>
	
	<script type="text/javascript" src="/js/jquery-ui/jquery-ui-1.8.8.custom.min.js"></script>
	<link rel="stylesheet" media="all" type="text/css" href="/js/jquery-ui/jquery-ui-1.8.8.custom.css" />
	
	<script type="text/javascript" src="/js/submit_bind/submit_bind.js"></script>
	
	<script type="text/javascript" src="/js/sheen/sheen.js"></script-->
	
	<%' Site specific imports below.  Do not add to or remove any of the code above. %>
	
	<!--script type="text/javascript" src="/admin/js/json/dd_json.js"></script>
	
	<script type="text/javascript" src="/admin/js/knockout/dd-modded-knockout-1.2.1.debug.js"></script>
	<script type="text/javascript" src="/admin/js/knockout/knockout.mapping.js"></script>
	<script type="text/javascript" src="/admin/js/datadial/knockout-helpers.js"></script-->

	<%' <facebook open graph> %>
		<meta property="og:title" content="PPCGB - Prestige Performance Centre" />
		<meta property="og:description" content="PPCGB supply car parts, car spares and car accessories, to both retail and to the trade. Our product and accessory range includes VW, Audi and BMW performance parts, brakes, exhausts, tyres, wheels and interiors at great prices." />
		<meta property="og:type" content="website" />
		<meta property="og:url" content="<%=commonRegistry.siteRootUrl%>" />
		<meta property="og:image" content="<%=commonRegistry.siteRootUrl%>img/social-logo.jpg" />
		<meta property="og:site_name" content="PPCGB - Prestige Performance Centre" />
	<%' </facebook open graph> %>

