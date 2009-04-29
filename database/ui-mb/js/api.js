/**
 * A convenience wrapper around the protomine API
 */

var Api = function(baseUrl) {
	var that = this;
	
	this.getObjects = getThingsMethod("Object");
	this.getTags    = getThingsMethod("Tag");
	
	this.getObject = getThingMethod("Object");
	this.getTag    = getThingMethod("Tag");
	
	this.objectUrl = function(objectId) {
		return baseUrl+"object/"+objectId;
	};

	function getThingsMethod(name) {
		var nameLower = name.toLowerCase();
		return function(callback) {
			var result = [], pending = 0;
		
			$.getJSON(baseUrl+nameLower+".json", {},
				function(data) {
					pending = data[nameLower+"Ids"].length;
					$(data[nameLower+"Ids"]).each(function(i, entry) {
						that["get"+name](entry[nameLower+"Id"], function(data) {
							result[i] = data;
							pending--;
							if ( !pending ) {
								callback(result);
							}
						});
					});
				}
			);
		}
	};
	
	function getThingMethod(name) {
		var name = name.toLowerCase();
		return function(id, callback) {
			$.getJSON(baseUrl+name+"/"+id+".json", {},
				function(data) {
					callback(data[name]);
				}
			);
		};
	}
};