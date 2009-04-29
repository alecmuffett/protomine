/**
 * Screen base object
 */

var BaseScreen = {
	showScreen : function(name, hideMenu) {
		$("body > div.shown")
			.hide()
			.removeClass("shown");
			
		$("#"+name+"-screen")
			.show()
			.addClass("shown");
			
		if (hideMenu) {
			$("#menu").hide();
		} else {
			$("#menu").show();
		}
	},
	loading : function() {
		this.showScreen("loading", true);
	}
}