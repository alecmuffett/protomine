/**
 * Object screen
 */

var ObjectScreen = function(main) {
	var scope = $("#object-screen");
	var list = $("dl", scope);
	
	var that = this;
	
	this.show = function(objectId) {	
		this.loading();
	
		main.api.getObject(objectId, function(object) {
			list.html(
				'<dt>name</dt><dd>'+object.objectName+'</dd>'+
				'<dt>description</dt><dd>'+(object.objectDescription||'&nbsp;')+'</dd>'+
				'<dt>tags</dt><dd>'+(object.objectTags||'&nbsp;')+'</dd>'+
				'<dt>type</dt><dd>'+object.objectType+'</dd>'+
				'<dt>data</dt><dd>'+htmlForObject(object)+'</a></dd>'
			);
			
			that.showScreen("object");
		});
	};
	
	function htmlForObject(object) {
		var result;
		var url = main.api.objectUrl(object.objectId);
		
		switch (object.objectType) {
			case "image/png":
			case "image/jpeg":
			case "image/gif":
				result = '<img src="'+url+'" />';
				break;
			case "text/plain":
			case "text/html":
				result = '<iframe src="'+url+'" width="100%" height="400" />';
				break;
			default:
				result = '<a href="'+url+'">data...</a>';
				break;
		}
		
		return result;
	}
}

ObjectScreen.prototype = BaseScreen;