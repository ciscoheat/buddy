package ;
import AllTests;

class Main
{
	static function main()
	{
		var suites = [new TestBasicFeatures(), new TestAsync()];
		var reporter = new ConsoleReporter();

		var testsRunning = true;
		new BDDSuiteRunner(suites, reporter).run().then(function(_) { testsRunning = false; });
		while(testsRunning)	Sys.sleep(0.1);
	}
}

