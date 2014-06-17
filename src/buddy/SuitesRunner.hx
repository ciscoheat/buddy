package buddy ;
import buddy.internal.SuiteRunner;
import buddy.reporting.Reporter;
import haxe.rtti.Meta;
import promhx.Deferred;
import promhx.Promise;
import buddy.BuddySuite;
using buddy.tools.AsyncTools;
using Lambda;

class SuitesRunner
{
	private var suites : Iterable<Suite>;
	private var reporter : Reporter;

	public function new(buddySuites : Iterable<BuddySuite>, reporter : Reporter)
	{
		var includeMode = buddySuites.exists(function(b) return b.suites.exists(function(s) return s.include));
		this.suites = [for (b in buddySuites) for (s in b.suites) if(!includeMode || s.include) s];
		this.reporter = reporter;
	}

	public function run() : Promise<Bool>
	{
		var def = new Deferred<Bool>();
		var defPr = def.promise();

		reporter.start().then(function(ok) {
			if(ok)
			{
				suites.iterateAsyncBool(runSuite)
					.pipe(function(_) return reporter.done(suites))
					.then(function(_) def.resolve(ok));
			}
			else
				def.resolve(ok);
		});

		return defPr;
	}

	public function failed() : Bool
	{
		for(s in suites) for (sp in s.specs)
			if (sp.status == TestStatus.Failed) return true;

		return false;
	}

	public function statusCode() : Int
	{
		return failed() ? 1 : 0;
	}

	private function runSuite(suite : Suite) : Promise<Suite>
	{
		return new SuiteRunner(suite, reporter).run();
	}
}
