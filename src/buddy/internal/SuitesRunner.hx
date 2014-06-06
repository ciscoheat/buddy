package buddy.internal ;
import buddy.reporting.Reporter;
import promhx.Deferred;
import promhx.Promise;
import buddy.BuddySuite;
using buddy.tools.AsyncTools;

class SuitesRunner
{
	private var suites : Array<Suite>;
	private var reporter : Reporter;

	public function new(suites : Iterable<BuddySuite>, reporter : Reporter)
	{
		this.suites = [for(s in suites) for(su in s.suites) su];
		this.reporter = reporter;
	}

	public function run() : Promise<SuitesRunner>
	{
		var def = new Deferred<SuitesRunner>();
		var defPr = def.promise();

		reporter.start();
		suites.iterateAsyncBool(runSuite).then(function(_) { reporter.done(suites); def.resolve(this); });

		return defPr;
	}

	private function runSuite(suite : Suite) : Promise<Suite>
	{
		return new SuiteRunner(suite, reporter).run();
	}
}
