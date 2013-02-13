<%@ Page Language="VB" runat="server" explicit="true" strict="true" %>
<%@ Register TagPrefix="dd" TagName="html" src="~/controls/html.ascx" %>
<%@ Register TagPrefix="dd" TagName="header_tags" src="~/controls/header_tags.ascx" %>
<%@ Register TagPrefix="dd" TagName="masthead" src="~/controls/masthead.ascx" %>
<%@ Register TagPrefix="dd" TagName="footer" src="~/controls/footer.ascx" %>

<script runat="server">

	Sub Page_Load()
		Response.Status = "404 Not Found"
		Response.StatusCode = 404
	End Sub
	
</script>

<dd:html  runat="server" />
<head>
	<dd:header_tags runat="server" />
	
	<meta name="robots" content="noindex,nofollow" />
	<title>404 Page Not Found</title>
</head>
<body>	
<form runat="server">
	<dd:masthead runat="server" />

	<div class="row">
		<div class="twelve columns">
			
			<h1>The page you're looking for can't be found.</h1>
			<p>We're really sorry about that... pages really shouldn't go missing, but sometimes it happens. If you keep seeing this page then please let us know.</p>
			<p>Perhaps you want to <a href="/">return to our home page</a> instead?<p>
			
		</div>
	</div>
	
	<dd:footer runat="server" />
</form>

</body>
</html>