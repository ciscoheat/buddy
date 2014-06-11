package buddy.reporting ;

import buddy.BuddySuite;
import buddy.reporting.Reporter;

#if nodejs
import buddy.internal.sys.NodeJs;
typedef Sys = NodeJs;
#elseif js
import buddy.internal.sys.Js;
typedef Sys = Js;
#elseif flash
import buddy.internal.sys.Flash;
typedef Sys = Flash;
#end

class ConsoleReporter implements Reporter
{
	public function new() {}

	public function start() {}

	public function progress(spec : Spec)
	{
		Sys.print(switch(spec.status) {
			case TestStatus.Failed: "X";
			case TestStatus.Passed: ".";
			case TestStatus.Pending: "P";
			case TestStatus.Unknown: "?";
		});
	}

	public function done(suites : Iterable<Suite>)
	{
		Sys.println("");

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
			Sys.println(s.name);
			for (sp in s.specs)
			{
				if (sp.status == TestStatus.Failed)
					Sys.println("  " + sp.description + " (FAILED: " + sp.error + ")");
				else
					Sys.println("  " + sp.description + " (" + sp.status + ")");
			}
		}

		Sys.println('$total specs, $failures failures, $pending pending');
	}
}

