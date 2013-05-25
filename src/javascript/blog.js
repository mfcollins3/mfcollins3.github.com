$(document).ready(function () {
	$.jstree._themes = '/javascript/jstree/themes/';
	$('#categoryTree').jstree({
		core: {},
		plugins: ['json_data', 'themes'],
		json_data: {
			ajax: {
				url: '/data/categories.json'
			}
		},
		themes: {
			theme: 'default'
		}
	});
});