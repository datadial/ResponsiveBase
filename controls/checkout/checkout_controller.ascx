<%@ Control Language="VB" ClassName="checkout_controller"  %>
<%@ Import Namespace="ddEcomm.Checkout" %>
<%@ Import Namespace="ddEcomm.Customers" %>
<%@ Import Namespace="ddEcomm.Basket" %>

<script runat="server">
    
    Private _StageControl As CheckoutStageControl
    Private _StageName As String = "login"
    Private _NextStage As String = ""
    Private _Customer As ICustomer = Services.Customers.GetCurrentCustomer
    
    Private _Basket As IBasket = Services.Basket.GetCurrentBasket
    Public Property Basket As IBasket
        Get
            Return _Basket
        End Get
        Set(value As IBasket)
            _Basket = value
        End Set
    End Property
    Private _ResetBasketSub As Action = AddressOf Services.Basket.ResetCurrentBasket
    Public Property ResetBasketSub As Action
        Get
            Return _ResetBasketSub
        End Get
        Set(value As Action)
            _ResetBasketSub = value
        End Set
    End Property
    
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
        If Request.QueryString("stage") IsNot Nothing AndAlso Request.QueryString("stage").Length > 0 Then _StageName = Request.QueryString("stage")
        StageNextButton.Attributes.Add("type", "submit") ' for <= IE7
        If _StageName <> "payment_complete" And _Basket.Lines.Count = 0 Then Response.Redirect("/")
        
        Select Case _StageName
            Case "login"
                If Not _Customer.IsGuest Then Response.Redirect(Request.Path & "?stage=address")
                _NextStage = "address"
                StageTitleControl.Text = "Sign In"
                StageNextButton.Text = "Sign in to secure checkout"
                stage_login.Attributes.Add("class", "current")
            Case "address"
                CheckLoginStageSatisfied()
                _NextStage = "payment"
                StageTitleControl.Text = "Address Details"
                StageNextButton.Text = "Continue to payment"
                StageNextButton.Visible = _Customer.Addresses.Count > 0
                stage_address.Attributes.Add("class", "current")
            Case "payment"
                CheckAddressStageSatisfied()
                _NextStage = "payment_complete"
                StageTitleControl.Text = "Payment"
                StageNextButton.Text = "Make secure payment"
                stage_payment.Attributes.Add("class", "current")
            Case "payment_complete"
                CheckAddressStageSatisfied()
                StageTitleControl.Text = "Payment Complete"
                StageNextButton.Visible = False
                stage_payment.Attributes.Add("class", "current")
            Case Else
                Response.Redirect("/404.aspx")
        End Select
        
        ' load the relevant checkout control into the page
        _StageControl = Page.LoadControl("/controls/checkout/" & _StageName & ".ascx")
        _StageControl.Basket = Me.Basket
        _StageControl.ResetBasketSub = Me.ResetBasketSub
        stage.Controls.Add(_StageControl)
    End Sub
	
    'Sub Page_PreRender(ByVal sender As Object, ByVal e As EventArgs)
    '    If _StageName = "payment" Then
    '        If Not CType(_StageControl, Object).deliveryMethodIsValid() Then
    '            StageNextButton.visible = False
    '        End If
    '    End If
    'End Sub
    
    Sub CheckLoginStageSatisfied()
        'keep them on login if they haven't satisfied the login stage
        If _Customer.Email.Length = 0 Then Response.Redirect(Request.Path & "?stage=login")
    End Sub
	
    Sub CheckAddressStageSatisfied()
        'make sure the address and login stages are satisfied and redirect them appropriately if not
        If _Customer.Addresses.Count = 0 Then
            CheckLoginStageSatisfied()
            Response.Redirect(Request.Path & "?stage=address")
        End If
    End Sub
    
    Public Sub HandleNextButtonClick()
        If _StageControl.ProcessCustomerInput Then Response.Redirect(Request.Path & "?stage=" & _NextStage)
    End Sub

    
</script>

    <style type="text/css">
		ul#stages {
/*			overflow:hidden;
			width:70%;
			margin:0 auto;*/
			margin:0 0 20px 0;
		}
		ul#stages li {
/*			display:block;
			float:left;
			width:33%;*/
			text-align:center;
			white-space:nowrap;
		}
		ul#stages li span {
			padding-right:5px;
			
		}
		ul#stages li.current {
			font-weight:bold;
		}
	</style>

	<ul id="stages" class="block-grid three-up mobile-three-up">
		<li id="stage_login" runat="server"><span>1</span>Login</li>
		<li id="stage_address" runat="server"><span>2</span>Address</li>
		<li id="stage_payment" runat="server"><span>3</span>Payment</li>
	</ul>

	<fieldset>
		<asp:PlaceHolder ID="stage" runat="server" />
	</fieldset>