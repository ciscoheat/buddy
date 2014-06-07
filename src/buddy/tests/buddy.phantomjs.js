var page = require('webpage').create();

page.open('index.html', function(status) {
    if (status !== 'success') {
        console.log('Error: Unable to access network!');
		phantom.exit();
    } else {
		setInterval(function() {
			var result = page.evaluate(function() { return document.body.innerText; });
			if(!/\d specs, \d failures, \d pending/.test(result)) return;

			var data = result.split(/[\r\n]+/);
			for(var line in data) {
				console.log(data[line]);
			}
			phantom.exit();
		}, 10);
    }
});
