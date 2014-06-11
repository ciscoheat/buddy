package buddy ;
import buddy.internal.SuiteRunner;
import buddy.reporting.Reporter;
import promhx.Deferred;
import promhx.Promise;
import buddy.BuddySuite;
using buddy.tools.AsyncTools;

class SuitesRunner
{
	private var suites : Iterable<BuddySuite>;
	private var reporter : Reporter;

	public function new(suites : Iterable<BuddySuite>, reporter : Reporter)
	{
		this.suites = suites;
		this.reporter = reporter;
	}

	public function run() : Promise<Bool>
	{
		var def = new Deferred<Bool>();
		var defPr = def.promise();

		reporter.start().then(function(ok) {
			if(ok)
			{
				suites.iterateAsyncBool(runBuddySuite)
					.pipe(function(_) return reporter.done([for (b in suites) for (s in b.suites) s]))
					.then(function(_) def.resolve(ok));
			}
			else
				def.resolve(ok);
		});

		return defPr;
	}

	public function failed() : Bool
	{
		for (buddy in suites) for(s in buddy.suites) for (sp in s.specs)
			if (sp.status == TestStatus.Failed) return true;

		return false;
	}

	public function statusCode() : Int
	{
		return failed() ? 1 : 0;
	}

	private function runBuddySuite(buddySuite : BuddySuite) : Promise<BuddySuite>
	{
		var run = runSuite.bind(_, buddySuite);
		return buddySuite.suites.iterateAsync(run, buddySuite);
	}

	private function runSuite(suite : Suite, buddySuite : BuddySuite) : Promise<Suite>
	{
		return new SuiteRunner(buddySuite, suite, reporter).run();
	}
}
