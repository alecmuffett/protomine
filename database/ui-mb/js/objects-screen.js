/**
 * List objects screen
 */

var ObjectsScreen = function(main) {
	var scope = $("#objects-screen");
	var list = $("dl", scope);
	
	var that = this;
	
	init();
	
	function init() {
		$("dt", scope).live("click", function() {
			main.screens.object.show($(this).attr("objectid"));
		});
	}
	
	this.show = function() {
		var html = [];
	
		this.loading();
	
		main.api.getObjects(function(objects) {
			$(objects).each(function(i, object) {
				html.push('<dt objectid="'+object.objectId+'">'+object.objectName+'</dt><dd>'+object.objectDescription+'</dd>');
			});
			list.html(html.join(""));
			
			that.showScreen("objects");
		});	
	}
}

ObjectsScreen.prototype = BaseScreen;