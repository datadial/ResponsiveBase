<%@ Page Language="VB" ContentType="text/html" %>
<%@ Register TagPrefix="dd" TagName="html" src="~/controls/html.ascx" %>
<%@ Register TagPrefix="dd" TagName="header_tags" src="~/controls/header_tags.ascx" %>
<%@ Register TagPrefix="dd" TagName="masthead" src="~/controls/masthead.ascx" %>
<%@ Register TagPrefix="dd" TagName="footer" src="~/controls/footer.ascx" %>

<%@ Register TagPrefix="dd" TagName="checkout_controller" src="~/controls/checkout/checkout_controller.ascx" %>


<script runat="server">
	
	Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
	End Sub

    Protected Sub next_button_Click(sender As Object, e As System.EventArgs)
        checkout_controller.HandleNextButtonClick()
    End Sub
			
</script>

<dd:html  runat="server" />
<head>
	<dd:header_tags  runat="server" />
	
	<style>
		<% ' Override the ul#stages styling in checkout_controller.ascx %>
		ul#stages {
		}
		ul#stages li {
/*			padding:5px 0 10px;*/
			font-size:1.2em;
			font-family: 'MichromaRegular';
		}
		ul#stages li span {
			font-size:1.5em;
			display:block;
			margin:0 auto;
			border-bottom:1px solid #6b5e4f;
			padding-bottom:3px;
			margin-bottom:3px;
		}
		ul#stages li.current {
			background:url(/img/diagonal-stripes.jpg) left top repeat;
			color:#2C3135;
			font-weight:normal !important;
		}
		ul#stages li.current span {
			border-color:#D81010;
		}	
	</style>
</head>
<body>
<form runat="server" class="custom">
	<dd:masthead runat="server" />

	<div class="row">
		<div class="nine columns mobile-bottom-padding">
			
			<h1><asp:Literal ID="checkout_stage_title" runat="server" /></h1>
	
			<dd:checkout_controller id="checkout_controller" runat="server" />
			
			<div class="row">
				<div class="four offset-by-eight mobile-two columns">
					<asp:Button ID="checkout_next_button" CssClass="button success stretch" runat="server" onclick="next_button_Click" />
				</div>
			</div>

		</div>
		
		<div class="three columns">
			<h3>Secure Checkout</h3>
			
			<% if not commonRegistry.isDevSite then %>
				<!--- Secure Site Seal - DO NOT EDIT --->
				<span id="ss_img_wrapper_115-55_image_en"><a href="http://www.alphassl.com/ssl-certificates/wildcard-ssl.html" target="_blank" title="SSL Certificates"><img alt="Wildcard SSL Certificates" border=0 id="ss_img" src="//seal.alphassl.com/SiteSeal/images/alpha_noscript_115-55_en.gif" title="SSL Certificate"></a></span><script type="text/javascript" src="//seal.alphassl.com/SiteSeal/alpha_image_115-55_en.js"></script>
				<!--- Secure Site Seal - DO NOT EDIT --->
			<% else %>
				<img src="http://placehold.it/210x300&text=Secure+Cert" />
			<% end if %>
		</div>
	</div>
	
	<dd:footer runat="server" />
</form>
</body>
</html>
