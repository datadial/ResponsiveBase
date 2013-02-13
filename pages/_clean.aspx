<%@ Page Language="VB" ContentType="text/html" %>
<%@ Register TagPrefix="dd" TagName="html" src="~/controls/html.ascx" %>
<%@ Register TagPrefix="dd" TagName="header_tags" src="~/controls/header_tags.ascx" %>
<%@ Register TagPrefix="dd" TagName="masthead" src="~/controls/masthead.ascx" %>
<%@ Register TagPrefix="dd" TagName="footer" src="~/controls/footer.ascx" %>

<%@ Import Namespace="ddEcomm.Catalogue.Categories" %>

<script runat="server">
	
	Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
	End Sub
			
</script>

<dd:html  runat="server" />
<head>
	<dd:header_tags  runat="server" />
</head>
<body>
<form runat="server">
	<dd:masthead runat="server" />

	<div class="row">
		<div class="twelve columns">
			
			<h1>Clean</h1>
			
		</div>
	</div>
	
	<dd:footer runat="server" />
</form>
</body>
</html>
