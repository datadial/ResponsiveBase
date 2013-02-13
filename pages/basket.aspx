<%@ Page Language="VB" ContentType="text/html" %>
<%@ Register TagPrefix="dd" TagName="html" src="~/controls/html.ascx" %>
<%@ Register TagPrefix="dd" TagName="header_tags" src="~/controls/header_tags.ascx" %>
<%@ Register TagPrefix="dd" TagName="masthead" src="~/controls/masthead.ascx" %>
<%@ Register TagPrefix="dd" TagName="footer" src="~/controls/footer.ascx" %>
<%@ Register TagPrefix="dd" TagName="basket" src="~/controls/basket.ascx" %>

<%@ Import Namespace="ddEcomm.Basket" %>
<%@ Import Namespace="ddEcomm.Catalogue.Products" %>

<script runat="server">
	
	Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)		
		basket.next_button = checkout_button
		basket.vat_breakdown = true
'		basket.mode = "summary"
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
			
			<h1>Basket</h1>
			
			<dd:basket id="basket" runat="server" />

			<br />
			
			<a href="/pages/checkout.aspx" id="checkout_button" runat="server" class="button success" style="float:right;">Go To Checkout &rsaquo;</a>

		</div>
	</div>
	
	<dd:footer runat="server" />
</form>
</body>
</html>
