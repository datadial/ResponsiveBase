<%@ Page Language="VB" ContentType="text/html" ResponseEncoding="iso-8859-1" %>
<%@ Import Namespace="ddEcomm.Transactions" %>

<script runat="server">
    
    Private _TermURL As String = CType(EcommRegistry.CoreConfig.Transactions.PaymentProviders.GetByCode("SAGEPAYDIRECT"), SagePayDirectPaymentProvider).D3DSecureTermURL
	
    Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
        If Request.QueryString("termURL") IsNot Nothing Then _TermURL = Request.QueryString("termURL")
        If _TermURL.Contains("?") Then _TermURL &= "&" Else _TermURL &= "?"
    End Sub
	
</script>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>3DSecure Redirect</title>
</head>
<body>
<form name="form" action="<%=request.QueryString("ACSURL")%>" method="POST">
	<div align="center">
		<p>You are being redirected to your bank for authentication.</p>
		<input type="hidden" id="PaReq" name="PaReq" value="<%=request.QueryString("PAReq").Replace(" ", "+")%>" />
		<input type="hidden" id="TermUrl" name="TermUrl" value="<%=commonRegistry.secureSiteRootURL & _TermURL & "order_id=" & request.QueryString("order_id") & "&tx_code=" & request.QueryString("tx_code") & "&callback=true" %>" />
		<input type="hidden" id="MD" name="MD" value="<%=request.QueryString("MD")%>" />
		<input name="test" type="submit" value="Please click here if you are not automatically redirected" />
	</div>
</form>
<SCRIPT LANGUAGE="Javascript">    document.form.submit();</SCRIPT>
</body>
</html>