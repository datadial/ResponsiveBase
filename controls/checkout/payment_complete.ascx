<%@ Control Language="VB" Inherits="ddEcomm.Checkout.CheckoutStageControl, ddEcomm.Core" %>
<%@ Import Namespace="ddEcomm.Customers" %>

<script runat="server">
	
	Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)

    End Sub
    
    Public Overrides Function ProcessCustomerInput() As Boolean
        Return True
    End Function

</script>

	<style>
	</style>
	
	<script type="text/javascript">
	</script>

	<asp:Literal ID="errors" runat="server" />
	
	
	<h2>Thank you</h2>
	
	<h3>Your order number is <%=request.QueryString("order_id")%></h3>
	
	<p>An email should arrive with you shortly, with a confirmation of your order details.</p>