

	$.fn.extend({
		compactMobileNav: function(options){
			var config = $.extend(true, {
				selectedClass: 'active',
				openClass: 'open',
				mobileTitle: 'Menu',
				chooseText: 'SELECT'
			}, options);
			
			function getDropdown(ul, classnames){
				var dropdown = $('<select class="compact-mobile-attention" />');
				dropdown.data('boundList', ul);
				
				dropdown.append('<option value="_choose_">'+config.chooseText+'</option>');
				
				ul.children('li').each(function(){
					var self = $(this);
					var option = $('<option>'+self.children('a,span,h1,h2,h3,h4,h5').text()+(self.children('ul').length?'&hellip;':'')+'</option>');
					option.data('boundListItem', self);
					dropdown.append(option);
				});
				dropdown.change(function(event, isInitCall){
					$(this).parent().nextAll('.compact-mobile-nav-select-wrap').remove(); // remove later other drops
					
					var listItem = $(this).children(':selected').data('boundListItem');
					var display = $(this).closest('.compact-mobile-nav').children('.compact-mobile-display');
					
					if(listItem){
						if(listItem.has('ul').length){	
							var dropdown = getDropdown(listItem.children('ul:eq(0)'));
							display.append(dropdown);
						}else{
							var href = listItem.children('a:eq(0)').attr('href');
							if(href.length > 0 && !isInitCall){
								display.find('.compact-mobile-nav-select-wrap').hide();
								display.find('.compact-mobile-pleaseWait').show();
								document.location.href = href;
							}
						}
					}
					
					var dropdownWraps = display.find('.compact-mobile-nav-select-wrap');
					dropdownWraps.css('width', (100 / dropdownWraps.length.toFixed(0))+'%');
					
					if($(this).val() == '_choose_'){
						$(this).addClass('compact-mobile-attention');
					}else{
						$(this).removeClass('compact-mobile-attention');
					}
				});
				return dropdown.wrap('<div class="compact-mobile-nav-select-wrap '+(classnames || '')+'" />').parent();
			}
			
			$(this).each(function(){
				var self = $(this);
				
				if(self[0].nodeName.toLowerCase() != 'ul'){ console.warn('compactMobileNav must be used on a <ul>'); return this; }
				
				self.wrap('<div class="compact-mobile-nav" />');
				
				var display = $('<div class="compact-mobile-display" />');
				self.after(display);

				if(config.mobileTitle.length){
					display.append('<h4>'+config.mobileTitle+'</h4>');
				}

				display.append('<div class="panel compact-mobile-pleaseWait">Please wait&hellip;</div>');

				display.append(getDropdown(self, 'compact-mobile-primaryDropdown'));
				
				// set active
				var activeListItem = self.find('.'+config.selectedClass);
				switch(activeListItem.length){
					case 0:
						break;
					case 1:
						var parents = activeListItem.parentsUntil('.compact-mobile-nav', 'li').andSelf();
						for(var i=0; i<parents.length; i++){
							var dropdown = display.find('select:eq('+i+')');
							if(dropdown.length == 0){ break; }
							dropdown.children('option').each(function(){
								var dropdownOption = $(this);
								if($(parents[i]).is(dropdownOption.data('boundListItem'))){
									dropdown.val(dropdownOption.val())
									dropdown.trigger('change', true);
								}
							});
						}
						break;
					default:
						console.warn('compactMobileNav source has more than one element with the selectedClass (.'+config.selectedClass+')');
				}
				
				// handle toggling of non-mobile child menus
				self.find('li:has(.active)').addClass(config.openClass);
				self.find('ul:has(.active)').show();
				self.find('span').click(function(){
					$(this).next().fadeToggle('fast');
					$(this).parent().toggleClass(config.openClass);
				});
	
			});

			// handle bfcache behaviour
			window.onpageshow = function() {
				$('.compact-mobile-nav-select-wrap').show();
				$('.compact-mobile-pleaseWait').hide();
			};

			return this;
		}
	});
