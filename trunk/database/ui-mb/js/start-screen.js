/**
 * Start screen
 */

var StartScreen = function(main) {
	var scope = $("#show-object-screen");
	var list = $("dl", scope);
	
	var that = this;
	
	this.show = function(callback) {
		var scope = $("#start-screen");

		this.showScreen("start", true);

		$("input[type=text]", scope).keyup(function(ev) {
			if (ev.keyCode==13) {
				submit();
			}
		});

		$("input[type=button]", scope).click(submit);
		
		function submit(ev) {
			var apiUrl = $("input#mine-url", scope).val() + "/api/";
			callback({apiUrl:apiUrl});
		};
	}
}

StartScreen.prototype = BaseScreen;