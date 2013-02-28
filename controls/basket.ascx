<%@ Control Language="VB" %>
<%@ Import Namespace="ddEcomm.Basket" %>
<%'@ Import Namespace="siteSpecific.domainLogic.common" %>
<%'@ Import Namespace="siteSpecific.domainLogic.Delivery" %>

<script runat="server">

	public next_button as object ' any runat="server" element for the 'Next' button
	public mode as string = "full"
	public vat_breakdown as boolean = false
	
	dim basket = services.basket.getCurrentBasket
	dim customer = services.customers.getCurrentCustomer
	
	Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs)
		if not string.isNullOrEmpty(request.QueryString("remove_from_basket")) then
			basket.removeItem(new GUID(request.QueryString("remove_from_basket")))
		end if
		
		basket_lines.datasource = basket.lines
		basket_lines.databind
		
		' add quantities to dropdowns, baring in mind stock levels
		for i as integer = 0 to basket_lines.items.count - 1
			dim item = basket_lines.items(i)
			dim quantity_drop as dropdownList = item.findControl("quantity")
			dim number_for_sale as integer = basket.lines(i).item.product.numberavailableforsale

			for x as integer = 1 to iif(number_for_sale > 20, 20, number_for_sale)
				quantity_drop.items.add(new listItem(x, x))
			next
			
			quantity_drop.selectedValue = basket.lines(i).quantity
		next
		
		basket_discount_lines.datasource = basket.discountLines
		basket_discount_lines.databind
		
		out_of_stock_items.datasource = basket.outOfStockItems
		out_of_stock_items.databind
		out_of_stock_items.visible = basket.outOfStockItems.count > 0
		basket.outOfStockItems.clear()
		
		if basket_lines.items.count = 0 then
			basket_wrap.visible = false
			if next_button isNot nothing then next_button.visible = false
			no_items.visible = true
		end if
		
		if not page.isPostback then
			delivery_country.datasource = services.location.getCountries
			delivery_country.dataTextField = "Name"
			delivery_country.dataValueField = "ID"
			delivery_country.databind
			delivery_country.selectedValue = basket.deliveryAddress.countryID
			
			' delivery methods
'			dim zoneCharges as deliveryChargeCollection = SiteSpecificRegistry.DeliveryCharges.GetByZone(services.location.getCountry(basket.deliveryAddress.countryID).subject.zoneID)
'			for each method in services.delivery.getDeliveryMethods
'				dim charge = zoneCharges.getByDeliveryMethod(method.id).getByWeight(basket.TotalWeight)
'				if charge isNot nothing then
'					delivery_method.items.add(new listItem(charge.DeliveryMethodName & " (" & charge.charge.convertTo(ecommRegistry.currentCurrency).toString & ")", charge.DeliveryMethodID))
'				end if
'			next
'			delivery_method.selectedValue = basket.deliveryMethod.id
'			'handle scenario when the weight exceeds (or is not handled) by any charges for the chosen zone
'			if delivery_method.items.count = 0 then
'				unhandled_delivery_weight.visible = true
'				delivery_method.visible = false
'				basket_totals.visible = false
'				if next_button isNot nothing then next_button.visible = false
'			end if
		end if
	End Sub
	
	Sub update_basket(ByVal sender As Object, ByVal e As EventArgs)
		if basket_lines.items.count = basket.lines.count then ' sanity check
			for each line in basket_lines.items
				dim basket_line = basket.lines(line.itemIndex)
				if basket_line.isEditable then
					dim quantity = line.findControl("quantity").selectedValue
					dim itemID = basket_line.itemID
					basket.setItemQuantity(itemID, quantity)
				end if
			next
		end if
		if mode = "full" then
			basket.deliveryAddress.countryID = delivery_country.selectedValue
			
			dim redirectUrl = request.path & iif(request.QueryString("stage") isNot nothing, "?stage=" & request.QueryString("stage"), "")
			
			if isNumeric(delivery_method.selectedValue) then 'will be empty if there's no valid delivery methods, and the user changes country
				dim deliveryMethod = services.delivery.getDeliveryMethod(delivery_method.selectedValue).subject
				if deliveryMethod isnot nothing then
					basket.deliveryMethod = services.delivery.getDeliveryMethod(delivery_method.selectedValue).subject
					response.Redirect(redirectUrl)
				else
					response.Write("ERROR: Delivery Method with ID " & delivery_method.selectedValue & " is Nothing")
				end if
			else
				response.Redirect(redirectUrl)
			end if
		end if
	End Sub

	Function get_product_image(images) as string
'		dim style as string = "style=""width:80px; float:left; margin-right:10px;"""
'		if images.count then
'			if images(0).images.count then return "<img src=""" & images(0).images(0).url & """ " & style & " />"
'			return "<img src=""" & images(0).url & """ " & style & " />"
'		end if
'		return "<div " & style & ">&nbsp;</div>"
		return ""
	End Function
	
	public function deliveryMethodIsValid as boolean
		return delivery_method.items.count > 0
	end function
	
</script>

	<style>
		#<%=me.clientID%>_basket_wrap .row {
			padding:5px 0;
			margin:0; /* foundation override */
		}
		#basket-heading {
			font-weight:bold;
			border-bottom:1px solid #565A5D;
			line-height:30px;
		}
		#basket-lines {
			border-bottom:1px solid #565A5D;
			margin:0 0 10px ;
		}
		#basket-lines .row {
			border-bottom:1px solid #ccc;
			min-height: 40px;
		}
		#basket-lines .row:last-child {
			border:none;
		}
		.mobile #basket-lines .row .show-for-small {
			display:inline !important;
		}
		#basket-footer .nine {
			font-weight:bold;
		}
		#update_basket {
			text-align:right;
			padding:5px 0;
			border-top:1px solid #555;
			margin-top:-1px;
		}
		#<%=me.clientID%>_basket_wrap .one, #basket-footer .row {
			line-height:30px;
		}
		#basket-footer .row {
			padding-top:0;
			padding-bottom:0;
		}
		#basket-lines select.basket-quantity {
			margin:0;
		}
	</style>
	
	
	<script type="text/javascript">
		$(function(){
			$('#update_basket').hide();
			
			$('.basket-quantity, #<%=me.clientID%>_delivery_country, #<%=me.clientID%>_delivery_method').change(function(){
				$('#update_basket input').click();
				$(this).hide().after('<div>Wait&hellip;</div>');
			});
		});
	</script>

	<asp:Repeater id="out_of_stock_items" runat="server" EnableViewState="false" Visible="false">
		<headertemplate>
			<div class="panel">
				<h3>The following items in your basket have become out of stock</h3>
		</headertemplate>
		<itemtemplate>
				<div><%# container.dataitem.product.name%></div>
		</itemtemplate>
		<separatortemplate>
				<hr />
		</separatortemplate>
		<footertemplate>
			</div>
		</footertemplate>
	</asp:Repeater>

	<div id="basket_wrap" runat="server">
		<div id="basket-heading" class="row hide-for-small">
			<div class="eight columns">
				Description
			</div>
			
			<div class="one columns right">
				<% if vat_breakdown then %>Net<% end if %>
			</div>
			<div class="one columns right">Price</div>
			<div class="one columns right">Quantity</div>
				
			<div class="one columns">&nbsp;</div>
		</div>
		<div id="basket-lines">
			<asp:Repeater ID="basket_lines" EnableViewState="false" runat="server">
				<itemtemplate>
					<div class="row basket-line">
						<div class="eight columns">
							<% if mode = "full" then %>
								<%# get_product_image(container.dataitem.item.product.images) %>
							<% end if %>
							<%# container.dataitem.description%>
	
							<asp:Repeater DataSource='<%# container.dataitem.appliedOffers%>' runat="server">
								<itemtemplate>
									<div><strong>OFFER: <%# container.dataitem.description%></strong></div>
								</itemtemplate>
							</asp:Repeater>
						</div>
						<div class="one mobile-one columns right">
							<% if vat_breakdown then %>
								<strong class="show-for-small">NET: </strong>
								<%# container.dataitem.netPrice.toHtml %>
							<% end if %>
						</div>
						<div class="one mobile-one columns right">
							<strong class="show-for-small">Price: </strong>
							<%# container.dataitem.grossPrice.toHtml %>
						</div>
						<div class="one mobile-one columns right">	
							<% if mode = "full" then %>
								<asp:DropDownList ID="quantity" Visible="<%#container.dataitem.isEditable%>" class="basket-quantity" runat="server" />
								<%# iif(container.dataitem.isEditable, "", container.dataitem.quantity)%>
							<% else %>
								<%# container.dataitem.quantity %>
							<% end if %>
						</div>
						<div class="one mobile-one columns right">
							<% if mode = "full" then %>
								<span runat="server"  Visible="<%#container.dataitem.isEditable%>"><a href="?remove_from_basket=<%# container.dataitem.itemID%>">Remove</a></span>
							<% end if %>
						</div>
					</div>
				</itemtemplate>
			</asp:Repeater>
			<asp:Repeater ID="basket_discount_lines" EnableViewState="false" runat="server">
				<itemtemplate>
					<div class="row">
						<div class="eight columns">
							<%# container.dataitem.description%>
						</div>
						<div class="one mobile-two columns right">
							<% if vat_breakdown then %>
								<%# container.dataitem.netPrice.toHtml %>
							<% end if %>
						</div>
						<div class="one mobile-two columns right end">
							<%# container.dataitem.grossPrice.toHtml %>
						</div>
					</div>
				</itemtemplate>
			</asp:Repeater>
		</div>
		<div id="update_basket">If you have made any changes to quantity or delivery location... <asp:Button OnClick="update_basket" Text="Update" CssClass="small_button" runat="server" /></div>
		<div id="basket-footer">
		
			<% if mode = "full" then %>
				<div class="row">
					<div class="nine mobile-two columns right">Delivery location</div>
					<div class="three mobile-two columns">
						<asp:DropDownList ID="delivery_country" runat="server" />
					</div>
				</div>
				<div class="row">
					<div class="nine mobile-two columns right">Shipping Method (<%=basket.TotalWeight.toString()%>)</div>
					<div class="three mobile-two columns">
						<asp:DropDownList ID="delivery_method" runat="server" />
					</div>
				</div>
			<% end if %>
			
			<div id="basket_totals" runat="server">
				<div class="row">
					<div class="nine mobile-two columns right">Delivery/Shipping</div>
					<div class="one mobile-two columns end right">
						<%=basket.grossDeliveryCharge.toHtml%>
					</div>
				</div>
	
				<% if mode = "full" then %>
					<div class="row">
						<div class="nine mobile-two columns right">Sub total <small>(exc. VAT)</small></div>
						<div class="one mobile-two columns end right">
							<%=basket.totalNetPrice.toHtml%>
						</div>
					</div>
					<div class="row">
						<div class="nine mobile-two columns right">VAT</div>
						<div class="one mobile-two columns end right">
							<div><%=basket.totalVat.toHtml%></div>
						</div>
					</div>
				<% end if %>
				
				<div class="row">
					<div class="nine mobile-two columns right">Total payable</div>
					<div class="one mobile-two columns end right">
						<%=basket.totalGrossPrice.toHtml%>
					</div>
				</div>
			</div>
		</div>
	</div>
	
	<div id="no_items" runat="server" visible="false">
		<br />
		<div class="panel center" style="padding:40px 0;"><h3>Your basket is empty.</h3></div>
	</div>

	<div id="unhandled_delivery_weight" runat="server" visible="false">
		<br />
		<div class="panel">The weight of items exceeds our delivery options.<br />Please contact us on 020 8341 9721 or email <a href="mailto:info@selvedge.org">info@selvedge.org</a></div>
		<br />
	</div>