<%@ Page Language="VB" runat="server" explicit="true" strict="true" %>
<%@ Register TagPrefix="dd" TagName="html" src="~/controls/html.ascx" %>
<%@ Register TagPrefix="dd" TagName="header_tags" src="~/controls/header_tags.ascx" %>
<%@ Register TagPrefix="dd" TagName="masthead" src="~/controls/masthead.ascx" %>
<%@ Register TagPrefix="dd" TagName="footer" src="~/controls/footer.ascx" %>

<script runat="server">

	Sub Page_Load()
		try
			if Context.Items("CustomErrorHandler_LastErrorReport") isnot nothing and ddCommon.CommonRegistry.IsDevSite then
				Page.Visible = False
				Response.Write(Context.Items("CustomErrorHandler_LastErrorReport"))
			else
				Response.Status = "500 Internal Server Error"
				Response.StatusCode = 500
			end if
		catch e as exception
			response.Write("e = " & e.message)
		end try
	End Sub
	
</script>

<dd:html  runat="server" />
<head>
	<dd:header_tags runat="server" />
	
	<meta name="robots" content="noindex,nofollow" />
	<title>500 Internal Server Error</title>
</head>
<body>	
<form runat="server">
	<dd:masthead runat="server" />
	
	<div class="row">
		<div class="twelve columns">

			<h1>There's been an error!</h1>
			<p>We're sorry but there was an error with the page you were requesting and it cannot be displayed. Our technical administration team have automatically been informed of the problem and are working to correct it.</p>
			<p>You may want to try again or <a href="/">return to the home page</a>.</p>
	
		</div>
	</div>
	
	<dd:footer runat="server" />
</form>

</body>
</html>
