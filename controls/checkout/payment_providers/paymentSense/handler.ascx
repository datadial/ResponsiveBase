<%@ Control Language="VB" Inherits="ddEcomm.Checkout.PaymentProviderHandlerControl, ddEcomm.Core" %>
<%@ Register TagPrefix="dd" TagName="droplist_month_picker" src="~/controls/droplist_month_picker.ascx" %>
<%@ Import Namespace="ddEcomm.Customers" %>
<%@ Import Namespace="ddEcomm.Transactions" %>
<%@ Import Namespace="ddEcomm.Transactions.PaymentSense" %>
<%@ Import Namespace="ddEcomm.Orders" %>
<%@ Import Namespace="ddEcomm.Basket" %>
<%@ Import Namespace="ddEcomm.Checkout" %>
<%@ Register TagPrefix="dd" TagName="paymentDetails" src="~/controls/checkout/paymentDetails.ascx" %>
<%@ Register TagPrefix="dd" TagName="orderDetails" src="~/controls/order.ascx" %>

<script runat="server">
    
    Private _Provider As PaymentSenseDirectPaymentProvider = EcommRegistry.CoreConfig.Transactions.PaymentProviders.GetByCode("PAYMENTSENSEDIRECT")
    Private _Helper As New PaymentSenseTransactionHelper
    
    Public ReadOnly Property StageTitleControl As Literal
        Get
            Return Me.Page.FindControl("checkout_stage_title")
        End Get
    End Property
    Public ReadOnly Property StageNextButton As Button
        Get
            Return Me.Page.FindControl("checkout_next_button")
        End Get
    End Property

    Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
        'orderDetails.Order = Services.Basket.GetCurrentBasket.GetOrder()
        Page.MaintainScrollPositionOnPostBack = "true"
        Dim cardTypes As New CardTypeCollection
        cardTypes.AddRange(_Provider.CardTypes)
        paymentDetails.CardTypes.AddRange(_Provider.CardTypes)
        If _Provider.IncludePayPalAsPaymentOption Then
            Dim payPalType As New CardType
            payPalType.Code = "PAYPAL"
            payPalType.Name = "PayPal"
            payPalType.LogoImageUrl = "https://www.paypal.com/en_GB/GB/i/logo/PayPal_mark_50x34.gif"
            payPalType.HasNoDetails = True
            cardTypes.Add(payPalType)
        End If
        paymentDetails.CardTypes = cardTypes
        If Is3DSecureCallBack() Then Handle3DSecureCallback()
        If IsPayPalCallBack() Then HandlePayPalCallback()
    End Sub
    
    Public Function Is3DSecureCallBack() As Boolean
        Return (Request.Form("MD") IsNot Nothing)
    End Function
    Public Function IsPayPalCallBack() As Boolean
        Return Request.QueryString("payPalCallback") IsNot Nothing
    End Function
    
    Public Overrides Function Validate() As Boolean
        Return paymentDetails.Validate
    End Function

    Public Overrides Sub DoPayment(ByVal order As IOrder, ByVal paymentSuccessCallback As Action(Of ITransaction), ByVal paymentFailureCallback As Action(Of String))
        If paymentDetails.SelectedCardType.Code = "PAYPAL" Then HandlePayPal(order, paymentSuccessCallback, paymentFailureCallback) : Exit Sub
        Dim transaction As New PaymentSenseDirectTransaction()
        transaction.OrderID = order.ID
        transaction.IsTest = CBool((_Provider.Mode = PaymentSenseMode.Test))
        Dim cardDetailsTrans As New CardDetailsTransaction
        cardDetailsTrans.TransactionType = PSTransactionType.SALE
        cardDetailsTrans.Amount = order.GrossTotal
        cardDetailsTrans.OrderID = order.ID
        cardDetailsTrans.OrderDescription = _Provider.DefaultDescription
        cardDetailsTrans.CardName = paymentDetails.CardHolderName
        cardDetailsTrans.CardNumber = paymentDetails.CardNumber
        If paymentDetails.SelectedCardType.HasStartDate Then
            cardDetailsTrans.CardStartDate.Month = paymentDetails.StartDateMonth
            cardDetailsTrans.CardStartDate.Year = paymentDetails.StartDateYear
        End If
        cardDetailsTrans.CardExpiryDate.Month = paymentDetails.EndDateMonth
        cardDetailsTrans.CardExpiryDate.Year = paymentDetails.EndDateYear
        If paymentDetails.SelectedCardType.HasIssueNumber Then
            cardDetailsTrans.CardIssueNumber = paymentDetails.IssueNumber
        End If
        cardDetailsTrans.CardCV2 = paymentDetails.SecurityCode
        cardDetailsTrans.CustomerBillingAddress(cityLine:=4) = order.BillingAddress
        cardDetailsTrans.CustomerEmailAddress = order.CustomerEmail
        Dim response = _Helper.SendCardDetailsTransaction(cardDetailsTrans)
        HandleResponse(response, transaction, paymentSuccessCallback, paymentFailureCallback)
    End Sub
    
    Public Sub HandlePayPal(ByVal order As IOrder, ByVal paymentSuccessCallback As Action(Of ITransaction), ByVal paymentFailureCallback As Action(Of String))
        Dim payPalProvider As PayPalPaymentProvider = EcommRegistry.CoreConfig.Transactions.PaymentProviders.GetByCode("PAYPAL")
        Dim req = New PayPalSetExpressCheckoutRequest(payPalProvider, order)
        req.ReturnUrl = String.Format("{0}/pages/checkout.aspx?stage=payment&payPalCallback=true&action=success&orderID={1}", CommonRegistry.SecureSiteRootURL, order.ID) 
        req.CancelUrl = String.Format("{0}/pages/checkout.aspx?stage=payment&payPalCallback=true&action=cancel&orderID={1}", CommonRegistry.SecureSiteRootURL, order.ID)
        Dim resp = req.Send
        If resp.RequestSuccess Then
            order.TemporaryPaymentData = resp.Token
            Services.Orders.SaveOrder(order)
            Response.Redirect(payPalProvider.GetLoginRedirectURL & "&token=" & Server.UrlEncode(resp.Token))
        Else
            paymentFailureCallback(resp.RequestErrorDetails)
        End If
    End Sub
    
    Protected Sub HandleResponse(ByVal response As IPaymentSenseResponse, ByVal transaction As PaymentSenseDirectTransaction, ByVal paymentSuccessCallback As Action(Of ITransaction), ByVal paymentFailureCallback As Action(Of String))
        Dim errorMessage As String = ""
		
        IgnoreQuerystringCallBackFlag.Value = "ignore"

        transaction.IsTest = (_Provider.Mode = PaymentSenseMode.Test)
        
        Select Case response.Status
            Case PSCardDetailsTransactionResultStatus.TransactionSuccessful
                transaction.ProviderAuthorisationCode = response.AuthCode
                transaction.ProviderTransactionID = response.CrossReference
                transaction.OriginalRequestXML = response.RequestXML
                transaction.OriginalResponseXML = response.ResponseXML
                paymentSuccessCallback.Invoke(transaction)
            Case PSCardDetailsTransactionResultStatus.CardDeclined, PSCardDetailsTransactionResultStatus.CardReferred
                errorMessage = _Provider.PaymentDeclinedMessage
            Case PSCardDetailsTransactionResultStatus.DuplicateTransaction, PSCardDetailsTransactionResultStatus.None, PSCardDetailsTransactionResultStatus.UnknownError
                errorMessage = _Provider.PaymentErrorMessage
            Case PSCardDetailsTransactionResultStatus.ThreeDSecureAuthenticationRequired
                Dim redirectUrl = String.Format("{0}{1}?ACSURL={2}&PAReq={3}&MD={4}&order_id={5}", CommonRegistry.SecureSiteRootURL, _Provider.D3DSecureRedirectFormURL, response.ThreeDSecureACSURL, Uri.EscapeDataString(response.ThreeDSecurePaREQ), response.CrossReference, transaction.OrderID)
                Page.Response.Redirect(redirectUrl)
        End Select

        If errorMessage.Length > 0 Then
            paymentFailureCallback(errorMessage)
        End If
    End Sub
    
    Sub Handle3DSecureCallback()
        Dim threeDSecureAuth As New ThreeDSecureAuthentication
        threeDSecureAuth.ThreeDSecureMessage.ThreeDSecureInputData.CrossReference = Request.Form("MD")
        threeDSecureAuth.ThreeDSecureMessage.ThreeDSecureInputData.PaRES = Request.Form("PARes")
        Dim authResponse As ThreeDSecureAuthenticationResponse = _Helper.SendThreeDSecureAuthorisation(threeDSecureAuth)

        Dim transaction As New PaymentSenseDirectTransaction()
        transaction.OrderID = Request.QueryString("order_id")
        HandleResponse(authResponse, transaction, AddressOf GetParentControl.HandlePaymentSuccess, AddressOf GetParentControl.HandlePaymentFailure)
    End Sub
    
    Sub HandlePayPalCallback()
        If Request.Form(IsPayPalConfirm.UniqueID) = "true" Then HandlePayPalConfirm() : Exit Sub
        Dim action As String = Request.QueryString("action")
        Dim orderID As Integer = Request.QueryString("orderID")
        If action = "cancel" Then GetParentControl.HandlePaymentFailure("You have cancelled your payment via PayPal.")
        If action = "success" Then
            paymentDetails.Visible = False
            IsPayPalConfirm.Value = "true"
            PayPalConfirmText.Text = "<br /><p>Please review your order details and confirm payment via PayPal by clicking the button below.</p>"
            StageTitleControl.Text = "Confirm Payment"
            StageNextButton.Text = "Confirm payment"
        End If
    End Sub
    
    Sub HandlePayPalConfirm()
        Dim payPalProvider As PayPalPaymentProvider = EcommRegistry.CoreConfig.Transactions.PaymentProviders.GetByCode("PAYPAL")
        paymentDetails.Visible = False
        Dim orderID As Integer = Request.QueryString("orderID")
        Dim orderResponse = Services.Orders.GetOrder(orderID)
        If orderResponse.Result.Success Then
            Dim order = orderResponse.Subject
            Dim token = order.TemporaryPaymentData
            Dim payerID = ""
            Dim getDetailsRequest As New PayPalGetExpressCheckoutDetailsRequest(token)
            Dim getDetailsResponse = getDetailsRequest.Send
            If getDetailsResponse.RequestSuccess Then
                payerID = getDetailsResponse.PayerID
            Else
                Response.Write(getDetailsResponse.RequestErrorDetails & " ------------ ")
              
                Response.Write(getDetailsResponse.RequestBody & " ------------ ")
                Response.Write(getDetailsResponse.ResponseBody)
                GetParentControl.HandlePaymentFailure("An error occurred retrieving your details from paypal. No payment has been taken.")
                Exit Sub
            End If
            Dim doPaymentRequest As New PayPalDoExpressCheckoutPaymentRequest(token, payerID, order)
            Dim doPaymentResponse = doPaymentRequest.Send
            Response.Write(doPaymentResponse.RequestBody & " ------------ ")
            Response.Write(doPaymentResponse.ResponseBody)
            If doPaymentResponse.RequestSuccess Then
                Dim transaction As New PayPalTransaction
                transaction.ProviderAuthorisationCode = "n/a"
                transaction.ProviderTransactionID = doPaymentResponse.TransactionID
                transaction.OriginalRequestBody = doPaymentResponse.RequestBody
                transaction.OriginalResponseBody = doPaymentResponse.ResponseBody
                transaction.PayerID = payerID
                transaction.IsTest = (payPalProvider.Mode = PayPalMode.Test)
                transaction.OrderID = order.ID
                GetParentControl.HandlePaymentSuccess(transaction)
            Else
                GetParentControl.HandlePaymentFailure("PayPal has not authorised this payment.<br />" & doPaymentResponse.RequestErrorDetails)
            End If
        Else
            GetParentControl.HandlePaymentFailure("An error occurred retrieving your order details. No payment has been taken.")
        End If
    End Sub
    
    Public Overrides Sub DoRefund(originalTransaction As ITransaction, amount As Decimal, description As String, ByVal paymentSuccessCallback As Action(Of ITransaction), ByVal paymentFailureCallback As Action(Of String))
        If originalTransaction.Type = "PAYPAL" Then DoPayPalRefund(originalTransaction, amount, description, paymentSuccessCallback, paymentFailureCallback)
        Dim transaction As New PaymentSenseDirectTransaction()
        transaction.OrderID = originalTransaction.OrderID
        transaction.VendorTxCode = Guid.NewGuid.ToString
        Dim crossRefTrans As New CrossReferenceTransaction
        crossRefTrans.Amount = New Money(amount, originalTransaction.Value.Currency)
        crossRefTrans.CrossReference = originalTransaction.ProviderTransactionID
        crossRefTrans.NewTransaction = True
        crossRefTrans.OrderID = transaction.VendorTxCode
        crossRefTrans.TransactionType = PSTransactionType.REFUND
        crossRefTrans.OrderDescription = "Refund against web order " & originalTransaction.OrderID
        Dim crossRefTransResponse As CrossReferenceTransactionResponse = _Helper.SendCrossReferenceTransaction(crossRefTrans)
        HandleResponse(crossRefTransResponse, transaction, paymentSuccessCallback, paymentFailureCallback)
    End Sub
    
    Public Sub DoPayPalRefund(originalTransaction As ITransaction, amount As Decimal, description As String, ByVal paymentSuccessCallback As Action(Of ITransaction), ByVal paymentFailureCallback As Action(Of String))
        Dim payPalProvider As PayPalPaymentProvider = EcommRegistry.CoreConfig.Transactions.PaymentProviders.GetByCode("PAYPAL")
        Dim doRefundRequest As New PayPalRefundTransactionRequest(originalTransaction, New Money(amount, originalTransaction.Value.Currency))
        Dim doRefundResponse = doRefundRequest.Send
        If doRefundResponse.RequestSuccess Then
            Dim transaction As New PayPalTransaction()
            transaction.OrderID = originalTransaction.OrderID
            transaction.ProviderAuthorisationCode = "n/a"
            transaction.ProviderTransactionID = doRefundResponse.RefundTransactionID
            transaction.OriginalRequestBody = doRefundResponse.RequestBody
            transaction.OriginalResponseBody = doRefundResponse.ResponseBody
            transaction.PayerID = ""
            transaction.IsTest = (payPalProvider.Mode = PayPalMode.Test)
            paymentSuccessCallback(transaction)
        Else
            paymentFailureCallback("PayPal has not authorised this refund.<br />" & doRefundResponse.RequestErrorDetails)
        End If
    End Sub
    
</script>

    <dd:paymentDetails id="paymentDetails" runat="server" />
	<input type="hidden" id="IgnoreQuerystringCallBackFlag" runat="server" value="" />
    <input type="hidden" id="IsPayPalConfirm" runat="server" value="" />
    <asp:Literal ID= "PayPalConfirmText" runat="server" EnableViewState="false" />