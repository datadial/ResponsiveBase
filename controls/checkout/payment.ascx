<%@ Control Language="VB" ClassName="Payment" Inherits="ddEcomm.Checkout.PaymentCheckoutStageControl, ddEcomm.Core" %>
<%@ Register TagPrefix="dd" TagName="order" src="~/controls/order.ascx" %>
<%@ Register TagPrefix="dd" TagName="additionalPaymentFields" src="~/controls/checkout/additionalPaymentFields.ascx" %>
<%@ Import Namespace="ddEcomm.Customers" %>
<%@ Import Namespace="ddEcomm.Transactions" %>
<%@ Import Namespace="ddEcomm.Orders" %>
<%@ Import Namespace="ddEcomm.Basket" %>
<%@ Import Namespace="ddEcomm.Checkout" %>

<script runat="server">
    
    Private _Customer As ICustomer = Services.Customers.GetCurrentCustomer
    Private _Basket As IBasket = Services.Basket.GetCurrentBasket
    Private _PaymentProviderHandler As PaymentProviderHandlerControl
    
    Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
        _PaymentProviderHandler = Page.LoadControl(EcommRegistry.CoreConfig.Transactions.PaymentProviders.GetByCode("SAGEPAYDIRECT").Handlers.GetByCode("DEFAULT").URL)
        Me.Controls.Add(_PaymentProviderHandler)
        If Request.QueryString("orderID") IsNot Nothing And IsNumeric(Request.QueryString("orderID")) Then
            Dim orderResponse = Services.Orders.GetOrder(CInt(Request.QueryString("orderID")))
            If orderResponse.Success Then
                DeliveryAddress.Text = orderResponse.Subject.DeliveryAddress.ToHtml
                BillingAddress.Text = orderResponse.Subject.BillingAddress.ToHtml
            Else
                DeliveryAddress.Text = ""
                BillingAddress.Text = ""
            End If
        Else
            DeliveryAddress.Text = _Basket.DeliveryAddress.ToHtml
            BillingAddress.Text = _Basket.BillingAddress.ToHtml
        End If
    End Sub
    
    Public Overrides Function ProcessCustomerInput() As Boolean
        If _PaymentProviderHandler.Validate() and additionalPaymentFields.processCustomerInput() Then
            ' create order then tell the payment provider control to create a transaction
            Dim error_messages As String = ""
            Dim order As IOrder = _Basket.GetOrder
            Dim result = Services.Orders.SaveOrder(order)
			
            If result.Success Then
                _PaymentProviderHandler.DoPayment(order, AddressOf HandlePaymentSuccess, AddressOf HandlePaymentFailure)
            Else
                error_messages = "There was a problem saving your order.<br />Technical services have been notified."
                SendErrorEmail("Order Save Fail", result.Exception.ToString)
            End If
	
            If error_messages.Length > 0 Then
                errors.Text = "<br /><div class=""alert-box alert"">" & error_messages & "</div>"
            End If
        End If
        Return False
    End Function
    
    Public Overrides Sub HandlePaymentSuccess(ByVal transaction As ITransaction)
        Dim error_messages As String = ""
        Dim order As IOrder
        Try
            Dim getOrderResponse = Services.Orders.GetOrder(transaction.OrderID)
            If getOrderResponse.Success Then
                order = getOrderResponse.Subject
            Else
                Throw New Exception("Failure in checkout process. Failed to retrieve order " & transaction.OrderID & " after successful payment.")
            End If
            transaction.Description = "Front end payment"
            transaction.Value = order.GrossTotal
        Catch ex As Exception
            errors.Text = "<br /><div class=""alert-box alert"">Payment was taken but there was a problem finalising your order.<br />Technical services have been notified.</div>"
            SendErrorEmail("Transaction Save Fail - Order ID:" & order.ID, ex.ToString)
        End Try
		
        transaction.Description = "Front end payment"
        transaction.Value = order.GrossTotal
		
        Dim result = Services.Transactions.SaveTransaction(transaction)
        If result.Success Then
            result = order.Finalise()
			
            If Not result.Success Then
                error_messages = "Payment was taken, but there was a problem finalising your order.<br />Technical services have been notified."
                SendErrorEmail("Order Finalise Fail - Order ID:" & order.ID, result.Exception.ToString)
            End If
        Else
            error_messages = "Payment was taken, but there was a problem saving your payment details.<br />Technical services have been notified."
            SendErrorEmail("Transaction Save Fail - Order ID:" & order.ID, result.Exception.ToString)
        End If

        If error_messages.Length > 0 Then
            errors.Text = "<br /><div class=""alert-box alert"">" & error_messages & "</div>"
        Else
            Email.Send(EcommRegistry.CoreConfig.Client.OutgoingEmail, EcommRegistry.CoreConfig.Client.IncomingEmail, CommonRegistry.ClientName & " Order Notification", "/email_templates/order_confirmation_client.aspx?id=" & order.ID, New Dictionary(Of String, String))
            Email.Send(EcommRegistry.CoreConfig.Client.OutgoingEmail, _Customer.Email, CommonRegistry.ClientName & " Order Confirmation", "/email_templates/order_confirmation.aspx?id=" & order.ID, New Dictionary(Of String, String))
	
            Services.Basket.ResetCurrentBasket()
	
            Response.Redirect(Request.Path & "?stage=payment_complete&order_id=" & order.ID)
        End If
    End Sub
    
    Public Overrides Sub HandlePaymentFailure(ByVal errorMessage As String)
        errors.Text = "<div class=""alert-box alert"" style=""white-space:normal !important;"">" & errorMessage & "</div><br />"
    End Sub
    
    Sub SendErrorEmail(ByVal subject As String, ByVal errorDetails As String)
        Dim replacements As New Dictionary(Of String, String)
        replacements.Add("|details|", errorDetails)
        Email.Send("support@datadial.net", "kerry@datadial.net", subject & " [" & CommonRegistry.ClientName & "]", "/email_templates/error.aspx", replacements)
    End Sub
    
</script>

	<style type="text/css">
		#delivery_address {
			width:47%;
			float:left;
		}
		#billing_address {
			width:47%;
			float:right;
		}
		#delivery_address h2, #billing_address h2 {
			padding-bottom:5px;
		}
		#delivery_address a, #billing_address a {
			font-size:0.9em;
		}
	</style>

	<dd:order runat="server" />
	
	<div id="delivery_address">
		<h2>Delivering to:</h2>
        <asp:Literal ID="DeliveryAddress" runat="server" />
		<a href="?stage=address">Change Address</a>
	</div>
	
	<div id="billing_address">
		<h2>Billing to:</h2>
        <asp:Literal ID="BillingAddress" runat="server" />
		<a href="?stage=address">Change Address</a>
	</div>
	
	<dd:additionalPaymentFields id="additionalPaymentFields" runat="server" />
	
	<div style="clear:both;"><asp:Literal ID="errors" runat="server" /></div>
	
	<asp:PlaceHolder ID="payment_provider_handler" runat="server" />