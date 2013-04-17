$(document).ready(function () {
	$('#eventsCalendar').fullCalendar({
		events: '/data/events.json'
	});
});