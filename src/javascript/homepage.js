$(document).ready(function () {
	$.getJSON('/data/events.json', function (data) {
		$('#events').html(Handlebars.templates.events(data));
	});
});