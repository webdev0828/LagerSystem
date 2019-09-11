if( ! window.console )
	window.console = { log: function(){} };

(function($){

	$.extend({
		notify: function( text, o ){
			$("<div>" + text + "</div>").notify(o || {});
		}
	});

	$.fn.extend({

		sfOut: function(speed, callback){
			return this.fadeTo(speed, 0).slideUp(speed, callback);
		},

		sfIn: function(speed, easing, callback){
			return this.hide().css('opacity', 0).slideDown(speed).fadeTo(speed, 1, callback);
		},

		notify: function(o){
			var o = $.extend({}, {
				className: "notice",
				duration: 5000,
				target: '#notifications',
				sticky: false,
				rendered: false,
				speed: 200,
				prepend: false
			}, o);

			return this.each(function(){
				if( !o.rendered ) $(this).hide().css('opacity', 0)[o.prepend?'prependTo':'appendTo'](o.target);
				$(this).addClass('notification').addClass(o.type);
				$(this).click(function(){ $(this).stop(true).sfOut(o.speed, function(){$(this).remove();});});
				if( !o.rendered ) $(this).sfIn(o.speed);
				if( !o.sticky ) $(this).delay(o.duration).sfOut(o.speed, function(){$(this).remove();});
			});
		}
	});

})(jQuery);