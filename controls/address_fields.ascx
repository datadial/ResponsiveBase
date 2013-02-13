<%@ Control Language="VB" %>
<%@ Import Namespace="ddEcomm.Customers" %>

<script runat="server">
	
	Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
		if not page.isPostback then
			country.datasource = services.location.getCountries
			country.dataTextField = "Name"
			country.dataValueField = "ID"
			country.databind
			country.selectedValue = services.location.getDefaultCountry.ID
		else
			init_states(request.form(country.uniqueID), request.form(state.uniqueID))
		end if
	End Sub
	
	Sub populate_address(byref address as customerAddress)
		address.name.forename = forename.text
		address.name.surname = surname.text
		
		address.line1 = line1.text
		address.line2 = line2.text
		address.line3 = line3.text
		address.line4 = line4.text
		address.postcode = postcode.text
		address.countryID = country.selectedValue
		
		if services.location.getStates.getByCountryID(address.countryID).count > 0 then
			address.stateID = request.form(state.uniqueID)
		else
			address.stateID = -1
		end if
	End Sub
	
	Sub populate_fields(address as customerAddress)
		forename.text = address.name.forename
		surname.text = address.name.surname

		line1.text = address.line1
		line2.text = address.line2
		line3.text = address.line3
		line4.text = address.line4
		postcode.text = address.postcode
		country.selectedValue = address.country.ID
		
		init_states(address.country.ID, address.stateID)
	End Sub
	
	Function init_states(country_id as integer, state_id as integer)
		state.datasource = services.location.getStates.getByCountryID(country_id)
		state.dataTextField = "Name"
		state.dataValueField = "ID"
		state.databind
		if state.items.count > 0 then
			if state_id > 0 then state.selectedValue = state_id
			state_selection.attributes.add("style", "display:block;")
		end if
	End Function
	
</script>

	<script type="text/javascript">
		$(function(){
			$('#<%=country.clientID%>').change(function(){
				$.ajax({
					url: '/pages/ajax.aspx?action=get_states_for_country&country_id='+$(this).val(),
					dataType: 'json',
					success: function(data){
						if(data.length){
							var state_drop = $('#<%=state.clientID%>');
							state_drop.find('*').remove();
							for(var i=0, state; state=data[i]; i++){
								state_drop.append('<option value="'+state.ID+'">'+state.Name+'</option>');
							}
							
							$('#<%=state_selection.clientID%>').fadeIn('normal');
						}else{
							$('#<%=state_selection.clientID%>').hide();
						}
					}
				});
			});
		});
	</script>

	<div class="row">
		<div class="four mobile-two columns"><label class="inline">Name</label></div>
		<div class="four mobile-one columns">
			<asp:TextBox ID="forename" CssClass="required" placeholder="John" runat="server" />
		</div>
		<div class="four mobile-one columns end">
			<asp:TextBox ID="surname" CssClass="required" placeholder="Smith" runat="server" />
		</div>
	</div>
	
	<div class="row">
		<div class="four mobile-two columns"><label class="inline">Address</label></div>
		<div class="eight mobile-two columns">
			<asp:TextBox ID="line1" CssClass="required" runat="server" />
			<asp:TextBox ID="line2" runat="server" />
			<asp:TextBox ID="line3" runat="server" />
		</div>
	</div>
	
	<div class="row">
		<div class="four mobile-two columns"><label class="inline">Town/City</label></div>
		<div class="eight mobile-two columns">
			<asp:TextBox ID="line4" runat="server" />
		</div>
	</div>
	
	<div class="row">
		<div class="four mobile-two columns"><label class="inline">Post Code / ZIP Code</label></div>
		<div class="eight mobile-two columns">
			<asp:TextBox ID="postcode" CssClass="required" runat="server" />
		</div>
	</div>

	<div class="row">
		<div class="four mobile-two columns"><label class="inline">Country</label></div>
		<div class="eight mobile-two columns">
			<asp:DropDownList ID="country" class="no-custom" runat="server" />
		</div>
	</div>
	
	
	<div id="state_selection" runat="server" class="row" style="display:none;">
		<div style="margin-top:12px;">
			<div class="four mobile-two columns"><label class="inline">State</label></div>
			<div class="eight mobile-two columns">
				<asp:DropDownList ID="state" class="no-custom" runat="server" />
			</div>
		</div>
	</div>

