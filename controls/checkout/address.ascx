<%@ Control Language="VB" Inherits="ddEcomm.Checkout.CheckoutStageControl, ddEcomm.Core" %>
<%@ Register TagPrefix="dd" TagName="address_fields" src="~/controls/address_fields.ascx" %>
<%@ Register TagPrefix="dd" TagName="additionalAddressFields" src="~/controls/checkout/additionalAddressFields.ascx" %>
<%@ Import Namespace="ddEcomm.Customers" %>

<script runat="server">
	
    Dim customer As ICustomer = Services.Customers.GetCurrentCustomer
	
	Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
		address_picker.visible = customer.addresses.count > 0
		open_new_address.visible = customer.addresses.count > 0 and not page.isPostback
		
		if not page.isPostback then
			for each address as ICustomerAddress in customer.addresses
				delivery_address.items.add(new listitem(address.toString().replace(vbCrLf, ", ").trim.trimEnd(","), address.ID.toString))
				billing_address.items.add(new listitem(address.toString().replace(vbCrLf, ", ").trim.trimEnd(","), address.ID.toString))
			next
			if customer.deliveryAddress isNot nothing then delivery_address.selectedValue = customer.deliveryAddress.ID.toString
			if customer.billingAddress isNot nothing then billing_address.selectedValue = customer.billingAddress.ID.toString
		end if
	End Sub
	
    Public Overrides Function ProcessCustomerInput() As Boolean
        customer.addresses.getByID(New GUID(delivery_address.selectedValue)).isDefaultDelivery = True
        customer.addresses.getByID(New GUID(billing_address.selectedValue)).isDefaultBilling = True
        If Not customer.isGuest Then services.customers.saveCustomer(customer)
		
        ' update the basket addresses
        Dim basket = services.basket.getCurrentBasket
        basket.deliveryAddress = customer.deliveryAddress
        basket.billingAddress = customer.billingAddress
		
        Return additionalAddressFields.processCustomerInput
    End Function
	
	Sub add_address(ByVal sender As Object, ByVal e As EventArgs)
		if page.isValid then
			dim address as new CustomerAddress
			new_address_fields.populate_address(address)
			customer.addresses.add(address)
			if not customer.isGuest then services.customers.saveCustomer(customer)
			response.Redirect(request.path & "?" & request.QueryString.toString)
		end if
	End Sub

	Sub edit_delivery_address(ByVal sender As Object, ByVal e As EventArgs)
		edit_address("delivery")
	End Sub
	
	Sub edit_billing_address(ByVal sender As Object, ByVal e As EventArgs)
		edit_address("billing")
	End Sub
	
	Sub edit_address(which as string)
		open_new_address.visible = false
		add_address_wrap.visible = false
		edit_address_wrap.visible = true
	
		dim address as customerAddress
		select case which
			case "delivery"
				address = customer.addresses.getByID(new GUID(delivery_address.selectedValue))
				address.isDefaultDelivery = true
			case "billing"
				address = customer.addresses.getByID(new GUID(billing_address.selectedValue))
				address.isDefaultBilling = true
		end select
		edit_address_id.text = address.ID.toString
		edit_address_fields.populate_fields(address)
	End Sub
	
	Sub save_address(sender as object, e as EventArgs)
		if page.isValid then
			dim address = customer.addresses.getByID(new GUID(edit_address_id.text))
			edit_address_fields.populate_address(address)
			if not customer.isGuest then services.customers.saveCustomer(customer)
			response.Redirect(request.path & "?" & request.QueryString.toString)
		end if
	End Sub
	
	Sub delete_address(sender as object, e as EventArgs)
		dim address = customer.addresses.getByID(new GUID(edit_address_id.text))
		customer.addresses.remove(address)
		if not customer.isGuest then services.customers.saveCustomer(customer)
		response.Redirect(request.path & "?" & request.QueryString.toString)
	End Sub
</script>

	<style type="text/css">	
		#<%=me.clientID%>_address_picker {
			border-bottom:1px solid #ccc;
			padding-bottom:15px;
			margin-bottom:15px;
		}
	</style>
	
	<script type="text/javascript">
		$(function(){
			$('form').ddValidate({
				onsubmit: false
			});
			$('#<%=me.clientID%>_add_address_button, #<%=me.clientID%>_edit_address_button').click(function(){ return $('form').valid(); });
			
			$('#<%=me.clientID%>_open_new_address').click(function(){
				$('#<%=me.clientID%>_add_address_wrap').fadeIn('normal');
				$(this).hide();
				return false;
			});
			$('#<%=me.clientID%>_open_new_address').show();
			
			if(!<%=page.isPostback.toString.toLower%> && <%=(customer.addresses.count > 0).toString.toLower%>){
				$('#<%=me.clientID%>_add_address_wrap').hide();
			}
			
			// Postcode Lookup
			var postcode_lookup_results = $('#postcode_lookup_results');
			var postcode_lookup_results_wrap = $('#postcode_lookup_results_wrap');
			var postcode_lookup_messages = $('#postcode_lookup_messages');
			
			$('#postcode_lookup_button').click(function(){
				postcode_lookup_messages.hide();
				$.ajax({
					url: '/pages/ajax.aspx?action=address_lookup&postcode='+escape($('#postcode_lookup').val()),
					dataType: 'json',
					success: function(data){
						if(data[0].Error){
							$('#postcode_lookup_messages').html(data[0].Description).fadeIn('normal');
							postcode_lookup_results_wrap.hide();
							return;
						}
						postcode_lookup_results.find('*').remove();
						for(var i=0, address; address=data[i]; i++){
							postcode_lookup_results.append('<option value="'+address.Id+'">'+address.StreetAddress+'</option>');
						}
						postcode_lookup_results_wrap.fadeIn('normal');
					}
				});
				return false;
			});
			postcode_lookup_results.change(function(){
				postcode_lookup_messages.hide();
				$.ajax({
					url: '/pages/ajax.aspx?action=address_lookup&id='+$(this).val(),
					dataType: 'json',
					success: function(data){
						data = data[0];
						if(data.Error){
							$('#postcode_lookup_messages').html(data.Description).fadeIn('normal');
							return;
						}
						$('#<%=new_address_fields.clientID%>_line1').val(data.Line1);
						$('#<%=new_address_fields.clientID%>_line2').val(data.Line2);
						$('#<%=new_address_fields.clientID%>_line3').val(data.Line3);
						$('#<%=new_address_fields.clientID%>_line4').val(data.PostTown);
						$('#<%=new_address_fields.clientID%>_postcode').val(data.Postcode);
					}
				});
			});

		});
	</script>

	<asp:Literal ID="errors" runat="server" />
	
	<div id="address_picker" runat="server" class="row">
		<div class="six columns">
			<h3>Choose your <span class="highlight">delivery address</span></h3>
			
			<div class="row mobile-bottom-padding">
				<div class="nine mobile-three columns">
					<asp:DropDownList ID="delivery_address" runat="server" class="no-custom" />
				</div>
				<div class="three mobile-one columns">
					<asp:Button ID="Button1" Text="Edit" CssClass="small button stretch" OnClick="edit_delivery_address" runat="server" />
				</div>
			</div>
				
		</div>
		
		<div class="six columns">
			<h3>Choose your <span class="highlight">billing address</span></h3>

			<div class="row">
				<div class="nine mobile-three columns">
					<asp:DropDownList ID="billing_address" runat="server" class="no-custom" />
				</div>
				<div class="three mobile-one columns">
					<asp:Button ID="Button2" Text="Edit" CssClass="small button stretch" OnClick="edit_billing_address" runat="server" />
				</div>
			</div>
			
		</div>
	</div>
	
	<a href="#" id="open_new_address" runat="server">Need to <span class="highlight"><strong>add another address?</strong></span></a>
	
	<div id="add_address_wrap" runat="server">
	
		<h2>Add a new address</h2>
		
		<p><big>This address can serve as your <strong>billing address</strong> or <strong>delivery address</strong>.<br />You can add another one afterwards.</big></p>
		
		<div id="postcode_lookup" runat="server" visible="true" class="panel" style="margin-bottom:20px;">
			Enter your postcode to auto-fill your new address
			
			<div class="row">
				<div class="nine mobile-three columns">
					<input type="text" id="postcode_lookup" submit_bind="postcode_lookup_button" />
				</div>
				<div class="three mobile-one columns">
					<button id="postcode_lookup_button" class="button small" style="width:100%;">Search&hellip;</button>
				</div>
			</div>
			
			<div id="postcode_lookup_results_wrap" style="display:none; text-align:left; width:100%; margin-top:10px;">
				Select your address:
				<select id="postcode_lookup_results" class="no-custom"></select>
			</div>
			<div id="postcode_lookup_messages" class="alert-box alert" style="display:none; margin-top:10px;"></div>
		</div>
	
		<dd:address_fields id="new_address_fields" runat="server" />
		<br />
		<asp:Button ID="add_address_button" Text="Add Address" OnClick="add_address" class="button" runat="server" style="float:right;" />
				
	</div>
	
	<div id="edit_address_wrap" runat="server" visible="false">
		<h2>Edit address</h2>
		<asp:Label ID="edit_address_id" runat="server" Visible="false" />
		<dd:address_fields id="edit_address_fields" runat="server" />
		<br />
		<div class="row">
			<div class="four mobile-two columns offset-by-four"><asp:Button ID="edit_address_button" Text="Save Changes" OnClick="save_address" class="success button stretch" runat="server" /></div>
			<div class="four mobile-two columns"><asp:Button ID="delete_address_button" Text="Delete Address" OnClick="delete_address" class="alert button stretch" runat="server" /></div>
		</div>
	</div>
	
	<dd:additionalAddressFields id="additionalAddressFields" runat="server" />
	