$(document).ready(function() {
	createStoryJS({
		width: '100%',
		height: '600',
		type: 'timeline',
		embed_id: 'my-timeline',
		source: '/data/mytimeline.json',
		css: '/css/TimelineJS/timeline.css',
		js: '/javascript/TimelineJS/timeline-min.js'
	});
});