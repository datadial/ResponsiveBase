<%@ Control Language="VB" Inherits="ddEcomm.Checkout.CheckoutStageControl, ddEcomm.Core" %>

<script runat="server">
    
    Dim min_password_length As Integer = 6
    Dim allow_guest_accounts As Boolean = EcommRegistry.CoreConfig.Customers.AllowGuestAccounts
	
    Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
        If Request.Cookies("remember_me") IsNot Nothing Then
            email.text = Request.Cookies("remember_me").Value
        End If
		
        guest_account_instructions.visible = allow_guest_accounts
    End Sub
	
    Public Overrides Function ProcessCustomerInput() As Boolean
        Dim error_html As String = ""
        Dim new_user As Boolean = new_customer.checked

        If new_user Then
            If Not services.customers.isEmailUnique(email.text.trim) Then error_html &= "Your email address has been used previously.<br />"
            If Not allow_guest_accounts Or (allow_guest_accounts And new_password.text.length > 0) Then
                If new_password.text.length < min_password_length Then error_html &= "Your password must be at least " & min_password_length & " characters long.<br />"
                If new_password.text <> new_password_retype.text Then error_html &= "Your passwords do not match.<br />"
            End If
            If first_name.text.trim.length = 0 Or last_name.text.trim.length = 0 Then error_html &= "Please enter your name<br />"
        Else
            If Not services.customers.logInCustomer(email.text, existing_password.text).success Then error_html &= "The email/password details you provided are incorrect. Please try again.<br />" ' & services.customers.logInCustomer(email.text, existing_password.text).exception.toString
        End If
		
        If new_user And error_html.length = 0 Then
            Dim customer = services.customers.getCurrentCustomer
            customer.forename = first_name.text
            customer.surname = last_name.text
            customer.email = email.text
            customer.password = new_password.text
			
            ' if their password is empty at this stage then they're a guest customer and don't need to be saved
            If customer.password.length Then
                If services.customers.saveCustomer(customer).success Then
                    ' send customer an email
                    '					dim replacements as new dictionary(Of String, String)
                    '					replacements.add("|password|", service_response.subject.password)
                    '					email.send("steffan@datadial.net", email_address, "Password Reminder", "/email_templates/password_reminder.aspx", replacements)
                Else
                    error_html &= "There was a problem creating your account. Please try again."
                End If
            End If
        End If
		
        If remember_me.checked Then
            Response.Cookies("remember_me").Expires = now.addYears(1)
            Response.Cookies("remember_me").Value = email.text
        Else
            Response.Cookies("remember_me").Value = ""
        End If

        If error_html.length Then
            errors.text = "<div class=""alert-box alert"">" & error_html & "</div>"
            Return False
        Else
            Return True
        End If
    End Function

</script>
       
	<script type="text/javascript">
		$(function(){
			$('form').ddValidate({
				rules: {
					<%=me.uniqueID%>$new_password: {
						minlength: <%=min_password_length%>
					},
					<%=me.uniqueID%>$new_password_retype: {
						minlength: <%=min_password_length%>,
						equalTo: "#<%=me.clientID%>_new_password"
					}
				},
				messages: {
					<%=me.clientID%>$new_password: {
						minlength: "Your password must be at least <%=min_password_length%> characters long"
					},
					<%=me.clientID%>$new_password_retype: {
						minlength: "Your password must be at least <%=min_password_length%> characters long",
						equalTo: "Please enter the same password as above"
					}
				}
			});
			
			var create_account = $('#create_account');
			create_account.hide();
			$('input[type=radio]').change(function(){
				if($(this).val() == 'existing_customer'){
					create_account.fadeOut('normal');
				}else{
					create_account.fadeIn('normal');
				}
			});
			$('input[type=radio]:checked').change();
			
			$('#forgotten-password').click(function(){
				var email_address = $('#<%=me.clientID%>_email').val();
				var messages = $('#forgotten-password-messages');
				messages.html('<div class="alert-box">Sending details to '+email_address+'&hellip;</div>');
				
				if(!email_address.length){ messages.html('<div class="error">Please enter your email address</div>'); return false; }
				
				$.ajax({
					type: 'post',
					dataType:'json',
					url: '/pages/ajax.aspx?action=forgotten_password',
					data: { email: email_address },
					success: function(data){
						if(data.success){
							messages.html('<div class="alert-box success">Your password has been sent to '+email_address+'</div>');
						}else{
							messages.html('<div class="alert-box alert">'+data.error+'</div>');
						}
					}
				});
				
				return false;
			});
		});		
	</script>

	
	<asp:Literal ID="errors" runat="server" />

	<h2>What is your email address?</h2>
	<div class="row">
		<div class="six columns offset-by-one">		
			<asp:TextBox ID="email" CssClass="required email" watermark="email@example.com" runat="server" />
			<asp:CheckBox ID="remember_me" Text="Remember me next time" Checked="true" runat="server" />
		</div>
	</div>

	<br />

	<h2>Have you shopped with us before?</h2>
	
	<p><asp:RadioButton ID="existing_customer" GroupName="new_or_existing" Text="Yes, I have a password" Checked="true" runat="server" /></p>
	<div class="row">
		<div class="six columns offset-by-one">
			<asp:TextBox ID="existing_password" CssClass="radio_indent" runat="server" TextMode="Password" />
			<p><a href="#" id="forgotten-password">Forgotten Password?</a></p>
			<div id="forgotten-password-messages"></div>
		</div>
	</div>
		
	<p><asp:RadioButton ID="new_customer" GroupName="new_or_existing" Text="No, I am a new customer" runat="server" /></p>
	
	<div id="create_account">
		<div class="row">
			<div class="three columns offset-by-one">Enter your name</div>
			<div class="four mobile-two columns"><asp:TextBox ID="first_name" placeholder="John" runat="server" /></div>
			<div class="four mobile-two columns"><asp:TextBox ID="last_name" placeholder="Smith" runat="server" /></div>
		</div>
	
		<div id="guest_account_instructions" runat="server" class="row">
			<div class="eleven columns offset-by-one">
				<br />
				<div class="panel center">If you would like to create an account with us, enter a password in the boxes below.</div>
			</div>
		</div>

		<div class="row">
			<div class="three mobile-two columns offset-by-one">Enter a new password</div>
			<div class="four mobile-two columns end"><asp:TextBox ID="new_password" TextMode="Password" runat="server" /></div>
		</div>

		<div class="row">
			<div class="three mobile-two columns offset-by-one">Re-type your password</div>
			<div class="four mobile-two columns end"><asp:TextBox ID="new_password_retype" TextMode="Password" runat="server" /></div>
		</div>	
	</div>
	