package buddy ;
import buddy.internal.SuiteRunner;
import buddy.reporting.Reporter;
import haxe.rtti.Meta;
import promhx.Deferred;
import promhx.Promise;
import buddy.BuddySuite;
using buddy.tools.AsyncTools;

@:keep // prevent dead code elimination
class SuitesRunner
{
	private var suites : Iterable<Suite>;
	private var reporter : Reporter;
	private var aborted : Bool;

	public function new(buddySuites : Iterable<BuddySuite>, ?reporter : Reporter)
	{
		// Cannot use Lambda here, Java problem in Linux.
		var includeMode = [for (b in buddySuites) for (s in b.suites) if (s.include) s].length > 0;

		this.suites = [for (b in buddySuites) for (s in b.suites) if(!includeMode || s.include) s];
		this.reporter = reporter == null ? new buddy.reporting.ConsoleReporter() : reporter;
	}

	public function run() : Promise<Bool>
	{
		var def = new Deferred<Bool>();
		var defPr = def.promise();

		reporter.start().then(function(ok) {
			if(ok)
			{
				suites.iterateAsyncBool(runSuite)
					.pipe(function(_) return reporter.done(suites, !failed()))
					.then(function(_) def.resolve(ok));
			}
			else
			{
				aborted = true;
				def.resolve(ok);
			}
		});

		return defPr;
	}

	public function failed() : Bool
	{
		var testFail : Suite -> Bool = null;

		testFail = function(s : Suite) {
			var failed = false;
			for (step in s.steps) switch step {
				case TSpec(sp): if (sp.status == TestStatus.Failed) return true;
				case TSuite(s2): if (testFail(s2)) return true;
			}
			return false;
		};

		for (s in suites) if (testFail(s)) return true;
		return false;
	}

	public function statusCode() : Int
	{
		if (aborted) return 1;
		return failed() ? 1 : 0;
	}

	private function runSuite(suite : Suite) : Promise<Suite>
	{
		return new SuiteRunner(suite, reporter).run();
	}
}
