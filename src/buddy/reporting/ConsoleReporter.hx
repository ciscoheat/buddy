package buddy.reporting ;
import buddy.BuddySuite;
import buddy.reporting.Reporter;
import neko.Lib;

class ConsoleReporter implements Reporter
{
	public function new() {}

	public function start() {}

	public function progress(spec : Spec)
	{
		Lib.print(switch(spec.status) {
			case TestStatus.Failed: "X";
			case TestStatus.Passed: ".";
			case TestStatus.Pending: "*";
			case TestStatus.Unknown: "?";
		});
	}

	public function done(suites : Iterable<Suite>)
	{
		Lib.println("");

		var total = 0;
		var failures = 0;
		var pending = 0;
		for (s in suites)
		{
			for (sp in s.specs)
			{
				total++;
				if (sp.status == TestStatus.Failed) failures++;
				else if (sp.status == TestStatus.Pending) pending++;
			}
		}

		for (s in suites)
		{
			Lib.println(s.name);
			for (sp in s.specs)
			{
				if (sp.status == TestStatus.Failed)
					Lib.println("  " + sp.description + " (FAILED: " + sp.error + ")");
				else
					Lib.println("  " + sp.description + " (" + sp.status + ")");
			}
		}

		Lib.println('$total specs, $failures failures, $pending pending');
	}
}
