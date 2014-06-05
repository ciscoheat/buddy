package ;
import BDDSuite;
import neko.Lib;

class ConsoleReporter implements BDDReporter
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

	public function done(suites : List<Suite>)
	{
		Lib.println("");
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
	}
}
