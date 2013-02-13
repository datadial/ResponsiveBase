
	Date.prototype.addDays = 		function(iDays){
										return new Date(this.getTime() + iDays*24*60*60*1000);
									};
	Date.prototype.daysInMonth =	function(){
										return 32 - new Date(this.getYear(), this.getMonth(), 32).getDate();
									};
									
	Date.prototype.toLongString = 	function(){
										var s = '';
										switch(this.getDate().toString().substring(this.getDate().toString().length-1)){
											case '1': s='st'; break;
											case '2': s='nd'; break;
											case '3': s='rd'; break;
											default: s='th'; 
										}
										if(this.getDate() > 10 && this.getDate() < 20){s='th';}
										
										return this.dayName() +' ' +this.getDate()+s+' '+this.monthName()+' '+this.getFullYear();
									};
	Date.prototype.toLongStringWithTime = 	function(){
										return this.toLongString() + ' at ' + this.getHours().pad(2) + ':' + this.getMinutes().pad(2);
									};
	Date.prototype.toISO =			function(){
										return this.getFullYear()+'-'+(this.getMonth()+1).pad(2)+'-'+this.getDate().pad(2);
									};
	Date.prototype.toSortableString = function(){
										return this.getDate().pad(2)+' '+this.monthName()+' '+this.getFullYear() + ' at ' + this.getHours().pad(2) + ':' + this.getMinutes().pad(2);
									};
	Date.prototype.monthName = 		function(){
										//var aMonthNames = new Array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
										var aMonthNames = new Array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
										return aMonthNames[this.getMonth()];
									};
	Date.prototype.dayName = 		function(){
										var days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
										return days[this.getDay()];
									};
	Array.prototype.filterBy = 		function(predicate){ /* USED ONLY FOR KNOCKOUT */
										var result = [];
										for(var i=0; i<this.length; i++){
											if(predicate(this[i])){
												result.push(this[i]);
											}
										}
										return ko.mapping.fromJS(result);
									};
	Array.prototype.getByID = 		function(iID){
										for(var i=0; i<this.length; i++){
											/* if ID is a function we're dealing with a Knockout ObservableArray */
											var id = this[i].ID;
											if(typeof(id) == 'function'){
												if(id() == iID){ return this[i]; }
											}else{
												if(id == iID){ return this[i]; }
											}
										}
										return null;
									};
	Array.prototype.getIndexByID = 	function(iID){
										for(var i=0; i<this.length; i++){
											/* if ID is a function we're dealing with a Knockout ObservableArray */
											var id = this[i].ID;
											if(typeof(id) == 'function'){
												if(id() == iID){ return i; }
											}else{
												if(id == iID){ return i; }
											}
										}
										return -1;
									};
	Array.prototype.getByGUID = 	function(GUID){
										for(var i=0; i<this.length; i++){
											if(this[i].GUID == GUID){ return this[i]; }
										}
										return null;
									};
	Array.prototype.getIndexByGUID = 	function(GUID){
										for(var i=0; i<this.length; i++){
											if(this[i].GUID == GUID){ return i; }
										}
										return -1;
									};
	Array.prototype.getById = 		function(iID){
										for(var i=0; i<this.length; i++){
											if(this[i].id == iID){ return this[i]; }
										}
										return null;
									};
	Array.prototype.getIndexById = 	function(iID){
										for(var i=0; i<this.length; i++){
											if(this[i].id == iID){ return i; }
										}
										return -1;
									};
	Array.prototype.swap = 			function(x,y) {
										var b = this[x];
										this[x] = this[y];
										this[y] = b;
										return this;
									};
	Array.prototype.remove = 		function(i) {
										return this.splice(i,1)[0];
									};
	Array.prototype.removeID = 		function(iID) {
										var index = this.getIndexByID(iID);
										if(index > -1){
											return this.splice(this.getIndexByID(iID),1)[0];
										}else{
											return null;
										}
									};
	Array.prototype.insertAt = 		function(value, index){
										if ( index > -1 && index <= this.length ) {
											this.splice(index, 0, value);
											return true;
										}        
										return false;
									};
	Number.prototype.pad = 			function(length){
										var s = this;
										while (s.toString().length < length) {
											s = '0' + s;
										}
										return s;
									};
	
	Number.prototype.random = 		function(minimum){
										return ( Math.floor ( Math.random ( ) * this + 1 ) );
									};
									
	String.prototype.trim = 		function(char){
										if(!char){ char = '\\s'; }
										return this.replace(eval('/^'+char+'+/'), '').replace(eval('/'+char+'+$/'), '');
									};


	function clone(obj){
		return $.extend(true, {}, obj);
	}
	
	var cookies = {
		set: function(name, value, expires, path, domain, secure){
			var curCookie = name + "=" + escape(value) +
				((expires) ? "; expires=" + expires.toGMTString() : "") +
				((true) ? "; path=/" : "") +
				((domain) ? "; domain=" + domain : "") +
				((secure) ? "; secure" : "");
			document.cookie = curCookie;
		},
		get: function(name){
			var dc = document.cookie;
			var prefix = name + "=";
			var begin = dc.indexOf("; " + prefix);
			if (begin == -1) {
			begin = dc.indexOf(prefix);
			if (begin != 0) return "";
			} else
			begin += 2;
			var end = document.cookie.indexOf(";", begin);
			if (end == -1)
			end = dc.length;
			return unescape(dc.substring(begin + prefix.length, end));
		}
	};
		
	$.fn.extend({
		ddValidate: function(options){
			$(this).validate($.extend(true, {
				errorElement:'small'
			}, options));
			
			return this;
		}
	});

