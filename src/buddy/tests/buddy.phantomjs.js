var page = require('webpage').create();

page.open('bin/index.html', function(status) {
    if (status !== 'success') {
        console.log('Error: Unable to access network!');
		phantom.exit(1);
    } else {
		setInterval(function() {
			var result = page.evaluate(function() { return document.body.innerText; });
			if(!/\d+ specs, \d+ failures, \d+ pending/.test(result)) return;

			console.log(result);

			var failed = /\d+ specs, [1-9]\d* failures, \d+ pending/.test(result);
			phantom.exit(failed ? 1 : 0);
		}, 100);
    }
});
