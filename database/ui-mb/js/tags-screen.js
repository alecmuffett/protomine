/**
 * List tags screen
 */

var TagsScreen = function(main) {
	var scope = $("#tags-screen");
	var list = $("ul", scope);
	
	var that = this;
			
	this.show = function() {
		var html = [];
	
		this.loading();
	
		main.api.getTags(function(tags) {
			var html = [];
			renderTags(buildNestedTree(tags), html);

			list.replaceWith(html.join(""));
			
			that.showScreen("tags");
		});
	}
	
	function buildNestedTree(tags) {
		var tree = {}, helperTree = {};

		$(tags).each(function(i, tag) {
			helperTree[tag.tagName] = helperTree[tag.tagName] || {};
			if (tag.tagImplies) {
				helperTree[tag.tagImplies] = helperTree[tag.tagImplies] || {};
				helperTree[tag.tagImplies][tag.tagName] = helperTree[tag.tagName];
			} else {
				tree[tag.tagName] = helperTree[tag.tagName];
			}
		});

		return tree;
	}
	
	function renderTags(tags, result) {
		var ul = false;
		for (var i in tags) {
			if (tags.hasOwnProperty(i)) {
				if (!ul) {
					ul = true;
					result.push("<ul>")
				}
				renderTag(i, tags[i], result);
			}
		}
		if (ul) {
			result.push("</ul>")
		}
	};
	
	function renderTag(tag, implies, result) {
		result.push('<li>');
		result.push(tag);
		renderTags(implies, result);
		result.push('</li>');
	};
}

TagsScreen.prototype = BaseScreen;