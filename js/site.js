
var site = {
	updateBasketCount: function(count){
		$('#mastead-basket-itemCount').html(count+' '+(count==1 ? 'item' : 'items'));
	}
};