$(document).ready(function () {
	$.getJSON('/data/events.json', function (data) {
		$('#eventList').html(Handlebars.templates.events(data));
	});
});