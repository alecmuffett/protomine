/**
 * MineClient! is a demo GUI for the protomine implemented as a single page application with jQuery
 * Mathias Baert
 */
$(document).ready(function() {
	new (function() {
		this.api = null;
		this.screens = {};
		
		var that = this;
	
		initApp();
		initMenu();
	
		function initApp() {
			$("body > div").hide();
			
			that.screens.start   = new StartScreen(that);
			that.screens.objects = new ObjectsScreen(that);
			that.screens.object  = new ObjectScreen(that);
			that.screens.tags    = new TagsScreen(that);
				
			that.screens.start.show(function(options) {
				that.api = new Api(options.apiUrl);
				that.screens.objects.show();
			});
		}
		
		function initMenu() {
			$("#objects-link").click(function(){that.screens.objects.show()});
			$("#tags-link").click(function(){that.screens.tags.show()});
		}
	})();
});