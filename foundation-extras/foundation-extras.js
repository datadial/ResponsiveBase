
$.extend({
	foundationExtras: function(options){
		var config = $.extend(true, {
			smallScreenPxBreakpoint:	768,
			onSmallScreen: 				function(){},
			offSmallScreen: 			function(){},
			smallScreenCssClass: 		'mobile'

		}, options);
		
		var html = $('html');
		
		function handleResize(){
			var width = $(window).width();
	
			if(width < config.smallScreenPxBreakpoint){
				if(!html.hasClass(config.smallScreenCssClass)){
					html.addClass(config.smallScreenCssClass);
					config.onSmallScreen();
				}
			}else{
				if(html.hasClass(config.smallScreenCssClass)){
					html.removeClass(config.smallScreenCssClass);
					config.offSmallScreen();
				}
			}
		};
	
		$(window)
			.resize(handleResize)
			.trigger('resize');	
		
		return this;
	}
});
