<%@ Control Language="VB" Inherits="ddEcomm.Checkout.PaymentProviderHandlerControl, ddEcomm.Core" %>
<%@ Register TagPrefix="dd" TagName="droplist_month_picker" src="~/controls/droplist_month_picker.ascx" %>
<%@ Import Namespace="ddEcomm.Customers" %>
<%@ Import Namespace="ddEcomm.Transactions" %>
<%@ Import Namespace="ddEcomm.Orders" %>
<%@ Import Namespace="ddEcomm.Basket" %>
<%@ Import Namespace="ddEcomm.Checkout" %>

<script runat="server">
    
    Private _Provider As SagePayDirectPaymentProvider = EcommRegistry.CoreConfig.Transactions.PaymentProviders.GetByCode("SAGEPAYDIRECT")
    Private _Helper As New SagePayTransactionHelper
    Private _GetTransactionFunction As Func(Of SagePayDirectTransaction) = Function() New SagePayDirectTransaction
    Private _D3DSecureTermURL As String = _Provider.D3DSecureTermURL
	Private _TransactionType as ProtxHelperTransactionType = ProtxHelperTransactionType.Payment
	
    Public Property GetTransactionFunction As Func(Of SagePayDirectTransaction)
        Get
            Return _GetTransactionFunction
        End Get
        Set(value As Func(Of SagePayDirectTransaction))
            _GetTransactionFunction = value
        End Set
    End Property
    Public Property D3DSecureTermURL As String
        Get
            Return _D3DSecureTermURL
        End Get
        Set(value As String)
            _D3DSecureTermURL = value
        End Set
    End Property
    Public Property TransactionType As ProtxHelperTransactionType
        Get
            Return _TransactionType
        End Get
        Set(value As ProtxHelperTransactionType)
            _TransactionType = value
        End Set
    End Property
    
    Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
        Page.MaintainScrollPositionOnPostBack = "true"
		
        card_types.DataSource = _Provider.CardTypes
        card_types.DataBind()

        If Not Page.IsPostBack Then card_holder.Text = Services.Customers.GetCurrentCustomer.Name.FullName
		
        If Request.QueryString("callback") IsNot Nothing And IgnoreQuerystringCallBackFlag.Value <> "ignore" Then Handle3DSecureCallback()
    End Sub
    
    Public Overrides Function Validate() As Boolean
        Dim error_html As String = ""
        If Request.Form("card_type") Is Nothing Then error_html &= "Select a card type<br />"
        If card_number.Text.Trim.Length = 0 Then error_html &= "Enter a card number<br />"
        If issue_number.Text.Trim.Length > 0 And Not IsNumeric(issue_number.Text.Trim) Then error_html &= "Enter an issue number<br />"
        If cv2.Text.Trim.Length = 0 Then
            error_html &= "Enter a security code<br />"
        Else
            If Not IsNumeric(cv2.Text.Trim) Or cv2.Text.Trim.Length <> 3 Then error_html &= "Security code must be a three digit number<br />"
        End If
        If error_html.Length Then
            errors.Text = "<div class=""alert-box alert"">" & error_html & "</div><br />"
            Return False
        End If
        Return True
    End Function

    Public Overrides Sub DoPayment(ByVal order As IOrder, ByVal paymentSuccessCallback As Action(Of ITransaction), ByVal paymentFailureCallback As Action(Of String))
        Dim transaction As SagePayDirectTransaction = GetTransactionFunction.Invoke()
        transaction.OrderID = order.ID
        Dim helper As New SagePayTransactionHelper
        helper.Add("TxType", Me.TransactionType.ToString.ToUpper)
        helper.Add("AccountType", "E")
        'helper.add("AccountType", "M") 'bypass 3D Secure
		
        helper.Add("VPSProtocol", "2.23")
        helper.Add("Vendor", _Provider.Vendor)
		
        helper.Add("VendorTxCode", transaction.VendorTxCode)
        helper.Add("Amount", Decimal.Parse(FormatNumber(order.GrossTotal.ConvertTo(Currency.DefaultCurrency).Amount, 2)))
        helper.Add("Currency", _Provider.DefaultCurrency)
        helper.Add("Description", _Provider.DefaultDescription)
        helper.Add("CardHolder", card_holder.Text)
        helper.Add("CardNumber", card_number.Text.Trim.Replace(" ", ""))
        'helper.Add("StartDate", start_date.get_credit_card_date())
        helper.Add("ExpiryDate", end_date.get_credit_card_date())
        helper.Add("IssueNumber", issue_number.Text)
        helper.Add("CV2", cv2.Text)
        helper.Add("CardType", Request.Form("card_type"))

        helper.Add("BillingFirstnames", order.BillingAddress.Name.ForeName)
        helper.Add("BillingSurname", order.BillingAddress.Name.Surname)
        helper.Add("BillingAddress1", order.BillingAddress.Line1)
        helper.Add("BillingAddress2", order.BillingAddress.Line2)
        helper.Add("BillingAddress3", order.BillingAddress.Line3)
        helper.Add("BillingCity", order.BillingAddress.Line4)
        helper.Add("BillingPostCode", order.BillingAddress.PostCode)
        helper.Add("BillingCountry", order.BillingAddress.Country.Code)
		
        If order.BillingAddress.Country.HasStates Then
            helper.Add("BillingState", order.BillingAddress.State.Code)
        End If
		
        helper.Add("DeliveryFirstnames", order.DeliveryAddress.Name.ForeName)
        helper.Add("DeliverySurname", order.DeliveryAddress.Name.Surname)
        helper.Add("DeliveryAddress1", order.DeliveryAddress.Line1)
        helper.Add("DeliveryAddress2", order.DeliveryAddress.Line2)
        helper.Add("DeliveryAddress3", order.DeliveryAddress.Line3)
        helper.Add("DeliveryCity", order.DeliveryAddress.Line4)
        helper.Add("DeliveryPostCode", order.DeliveryAddress.PostCode)
        helper.Add("DeliveryCountry", order.DeliveryAddress.Country.Code)
		
        If order.DeliveryAddress.Country.HasStates Then
            helper.Add("DeliveryState", order.DeliveryAddress.State.Code)
        End If

        helper.Add("CustomerName", order.BillingAddress.Name.FullName)
		
        helper.DoPost(Me.TransactionType)
        
        HandleResponse(helper, transaction, paymentSuccessCallback, paymentFailureCallback)
    End Sub
    
    Protected Sub HandleResponse(ByVal helper As SagePayTransactionHelper, ByVal transaction As SagePayDirectTransaction, ByVal paymentSuccessCallback As Action(Of ITransaction), ByVal paymentFailureCallback As Action(Of String))
        Dim errorMessage As String = ""
		
        IgnoreQuerystringCallBackFlag.Value = "ignore"

        transaction.IsTest = (_Provider.Mode.ToLower <> "live")

        Select Case helper.ResponseParams("Status").ToLower
            Case "ok", "registered", "authenticated"
                If helper.ResponseParams.ContainsKey("VPSTxId") Then transaction.ProviderTransactionID = helper.ResponseParams("VPSTxId")
                If helper.ResponseParams.ContainsKey("TxAuthNo") Then transaction.ProviderAuthorisationCode = helper.ResponseParams("TxAuthNo")
                If helper.ResponseParams.ContainsKey("SecurityKey") Then transaction.SecurityKey = helper.ResponseParams("SecurityKey")
                If helper.ResponseParams.ContainsKey("CAVV") Then transaction.CAVV = helper.ResponseParams("CAVV")
				
                transaction.OriginalRequestString = helper.OriginalRequestString
                transaction.OriginalResponseString = helper.OriginalResponseString
              
                paymentSuccessCallback.Invoke(transaction)
            Case "abort"
                errorMessage = helper.ResponseParams("StatusDetail") & "<br />" & _Provider.PaymentAbortMessage
            Case "error"
                errorMessage = helper.ResponseParams("StatusDetail") & "<br />" & _Provider.PaymentErrorMessage
            Case "invalid"
                errorMessage = helper.ResponseParams("StatusDetail") & "<br />" & _Provider.PaymentInvalidMessage
            Case "malformed"
                errorMessage = helper.ResponseParams("StatusDetail") & "<br />" & _Provider.PaymentMalformedMessage
            Case "notauthed"
                errorMessage = helper.ResponseParams("StatusDetail") & "<br />" & _Provider.PaymentNotAuthedMessage
            Case "rejected"
                errorMessage = helper.ResponseParams("StatusDetail") & "<br />" & _Provider.PaymentRejectedMessage
            Case "undef"
                errorMessage = helper.ResponseParams("StatusDetail") & "<br />" & _Provider.PaymentUndefMessage
            Case "3dauth"
                Response.Redirect(CommonRegistry.SecureSiteRootURL & _Provider.D3DSecureRedirectFormURL & _
                     "?ACSURL=" & helper.ResponseParams("ACSURL") & _
                     "&PAReq=" & helper.ResponseParams("PAReq") & _
                     "&MD=" & helper.ResponseParams("MD") & _
                     "&order_id=" & transaction.OrderID & _
                     "&tx_code=" & transaction.VendorTxCode & _
                     "&termURL=" & Me.D3DSecureTermURL)
        End Select

        If errorMessage.Length > 0 Then
            GetParentControl.HandlePaymentFailure(errorMessage)
            'Else
            '    errors.Text = "<div class=""alert-box alert"" style=""white-space:normal !important;"">" & errorMessage & "</div><br />"
            'End If
        End If
    End Sub
    
    Sub Handle3DSecureCallback()
        _Helper.Add("MD", Request.Form("MD"))
        _Helper.Add("PARes", Request.Form("PARes"))
        _Helper.DoPost(ProtxHelperTransactionType.CallBack)

        Dim transaction As SagePayDirectTransaction = GetTransactionFunction.Invoke()
        transaction.OrderID = Request.QueryString("order_id")
        transaction.VendorTxCode = Request.QueryString("tx_code")
        
        HandleResponse(_Helper, transaction, AddressOf GetParentControl.HandlePaymentSuccess, AddressOf GetParentControl.HandlePaymentFailure)
    End Sub
    
    Public Overrides Sub DoRefund(originalTransaction As ITransaction, amount As Decimal, description As String, ByVal paymentSuccessCallback As Action(Of ITransaction), ByVal paymentFailureCallback As Action(Of String))
        Dim transaction As New SagePayDirectTransaction()
        transaction.OrderID = originalTransaction.OrderID
        transaction.VendorTxCode = Guid.NewGuid.ToString
	
        _Helper.Add("VPSProtocol", "2.23")
        _Helper.Add("Vendor", _Provider.Vendor)

        _Helper.Add("TxType", "REFUND")
        _Helper.Add("VendorTxCode", transaction.VendorTxCode)
        _Helper.Add("RelatedVPSTxId", originalTransaction.ProviderTransactionID)
        _Helper.Add("RelatedVendorTxCode", CType(originalTransaction, SagePayDirectTransaction).VendorTxCode)
        _Helper.Add("RelatedSecurityKey", CType(originalTransaction, SagePayDirectTransaction).SecurityKey)
        _Helper.Add("RelatedTxAuthNo", originalTransaction.ProviderAuthorisationCode)
        _Helper.Add("Amount", amount)
        _Helper.Add("Currency", originalTransaction.Value.Currency.Code)
        _Helper.Add("Description", description)

        _Helper.DoPost(ProtxHelperTransactionType.Refund)
	
        HandleResponse(_Helper, transaction, paymentSuccessCallback, paymentFailureCallback)
    End Sub
    
</script>

	<style type="text/css">
		ul#card_types {
			list-style:none;
			padding:0 0 10px 0;
			overflow:hidden;
		}
		ul#card_types li {
			float:left;
			display:block;
			padding:10px 0;
			width:30%;
			margin:0 4.5% 0 0;
		}
		ul#card_types li.end-of-line {
			margin-right:0;
		}
		ul#card_types input {
			float:left;
			display:block;
			margin:10px 5px 0 10px;
		}
		ul#card_types label {
			float:left;
			font-size:15px;
			line-height:32px;
			cursor:pointer;
			cursor:hand;
			margin:0;
		}
		ul#card_types img {
			float:left;
			display:block;
			margin: 0 5px 0 0;
		}
		ul#card_types .selected {
			background-color:#eee;
		}
		
		#cv2-help-info {
			position:absolute;
			right:0px;
			top:45px;
			border:1px solid #285A8E;
			padding:10px;
			background-color:#fff;
			display:none;
			-webkit-box-shadow: 0px 0px 5px 0px #ccc;
			-moz-box-shadow: 0px 0px 5px 0px #ccc;
			box-shadow: 0px 0px 5px 0px #ccc;
		}
		
		.payment-section {
			float:left;
			width:45%;
			margin:0 10% 10px 0;
		}
		.payment-section-end-of-line {
			margin-right:0;
		}
	</style>
    <%=""%>
	<script type="text/javascript">
		$(function(){
			$('form').validate();
			
			<% if not page.isPostback then %>
				$('#payment_form').hide();
			<% else %>
				$('#card_types input[value=<%=request.Form("card_type")%>]').attr('checked', true);
			<% end if %>
			
			$('#card_types input').click(function(){
				var self = $(this);
				$('#card_types li').removeClass('selected');
				self.closest('li').addClass('selected');
				
				if(self.attr('has-issue-number').toLowerCase() == 'true'){
					$('#<%=issue_number.clientID%>').stop().fadeTo(500, 1, function(){ $('#<%=issue_number.clientID%>').attr('disabled', false); });
				}else{
					$('#<%=issue_number.clientID%>').val('').stop().fadeTo(500, 0.5, function(){ $('#<%=issue_number.clientID%>').attr('disabled', true); });
				}
				
				$('#payment_form').fadeIn('normal');
			});
			$('#card_types input:checked').click();
			
			$('#cv2-help-icon').hover(
				function(){
					$('#cv2-help-info').fadeIn('fast');
				},
				function(){
					$('#cv2-help-info').fadeOut('fast');
				}
			);
		});
	</script>

	<h2 style="clear:both; padding-top:40px;">How would you like to pay?</h2>
	

	
	<asp:Literal ID="errors" runat="server" />
	
	<asp:Repeater ID="card_types" runat="server">
		<headertemplate><ul id="card_types"></headertemplate>
		<itemtemplate>
			<li class="ui-corner-all<%# iif((container.itemIndex+1) mod 3 = 0 , " end-of-line", "")%>">
				<input type="radio" name="card_type" has-start-date="<%# container.dataitem.hasStartDate%>" has-issue-number="<%# container.dataitem.hasIssueNumber%>" value="<%# container.dataitem.code%>" id="card_type_<%# container.dataitem.code%>" />
				<label for="card_type_<%# container.dataitem.code%>">
					<img src="<%# container.dataitem.logoImageUrl%>" />
					<%# Container.DataItem.name%>
				</label>
			</li>
		</itemtemplate>
		<footertemplate></ul></footertemplate>
	</asp:Repeater>
	
	<br clear="all" />

	<div id="payment_form">
		<div class="payment-section"><label for="<%=card_holder.clientID%>">Name of Card Holder</label><asp:TextBox ID="card_holder" runat="server" style="width:100%;" /></div>
		<div class="payment-section payment-section-end-of-line"><label for="<%=card_number.clientID%>">Card Number</label><asp:TextBox ID="card_number" autocomplete="off" runat="server" style="width:100%;" /></div>
		<div class="payment-section"><label for="<%=issue_number.clientID%>">Issue Number</label><asp:TextBox ID="issue_number" CssClass="number" runat="server" /></div>
		<div class="payment-section payment-section-end-of-line" style="position:relative; overflow:visible;">
			<label for="<%=cv2.clientID%>">Security Code (CV2)</label>
			<asp:TextBox ID="cv2" CssClass="required number" runat="server" style="float:left;" /> 
			<span id="cv2-help-icon" style="float:left; cursor:pointer; cursor:help;" class="ui-icon ui-icon-help"></span>
			<span id="cv2-help-info">
				<img src="/img/cv2.jpg" />
			</span>
		</div>
		
		<div class="payment-section payment-section-end-of-line"><label>End Date</label><dd:droplist_month_picker id="end_date" year_offset="10" runat="server" /></div>
	</div>
	
	<input type="hidden" id="IgnoreQuerystringCallBackFlag" runat="server" value="" />