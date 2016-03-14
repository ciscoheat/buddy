package buddy.reporting;

import promhx.Deferred;
import promhx.Promise;

import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.BuddySuite.TestStatus;

using Lambda;
using StringTools;

class TraceReporter implements Reporter
{
	public function new() {}

	public function start()
	{
		return resolveImmediately(true);
	}

	public function progress(spec:Spec)
	{
		// No progress is shown, it would generate too much noise.
		return resolveImmediately(spec);
	}

	public function done(suites : Iterable<Suite>, status : Bool)
	{
		println("");

		var total = 0;
		var failures = 0;
		var pending = 0;

		var countTests : Suite -> Void = null;
		var printTests : Suite -> Int -> Void = null;

		countTests = function(s : Suite) {
			for (sp in s.steps) switch sp {
				case TSpec(sp):
					total++;
					if (sp.status == TestStatus.Failed) failures++;
					else if (sp.status == TestStatus.Pending) pending++;
				case TSuite(s):
					countTests(s);
			}
		};

		suites.iter(countTests);

		printTests = function(s : Suite, indentLevel : Int)
		{
			var print = function(str : String) println(str.lpad(" ", str.length + indentLevel * 2));

			print(s.description);
			for (step in s.steps) switch step
			{
				case TSpec(sp):
					if (sp.status == TestStatus.Failed)
					{
						print("  " + sp.description + " (FAILED: " + sp.error + ")");

						printTraces(sp);

						if (sp.stack == null || sp.stack.length == 0) continue;

						// Display the exception stack
						for (s in sp.stack) switch s {
							case FilePos(_, file, line) if (file.indexOf("buddy/internal/") != 0):
								print('    @ $file:$line');
							case _:
						}
					}
					else
					{
						print("  " + sp.description + " (" + sp.status + ")");
						printTraces(sp);
					}
				case TSuite(s):
					printTests(s, indentLevel+1);
			}
		};

		suites.iter(printTests.bind(_, 0));

		println('$total specs, $failures failures, $pending pending');

		return resolveImmediately(suites);
	}

	function printTraces(spec : Spec)
	{
		for (t in spec.traces)
			println("    " + t);
	}

	private function print(s : String)
	{
		// Override when needed.
	}

	private function println(s : String)
	{
		trace(s);
	}

	private function resolveImmediately<T>(o : T) : Promise<T>
	{
		var def = new Deferred<T>();
		var pr = def.promise();
		def.resolve(o);
		return pr;
	}
}