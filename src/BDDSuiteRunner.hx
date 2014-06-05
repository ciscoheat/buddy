package ;
import promhx.Deferred;
import promhx.Promise;
import BDDSuite;
using AsyncTools;

class BDDSuiteRunner
{
	private var suites : Array<Suite>;
	private var reporter : BDDReporter;

	public function new(suites : Iterable<BDDSuite>, reporter : BDDReporter)
	{
		this.suites = [for(s in suites) for(su in s.suites) su];
		this.reporter = reporter;
	}

	public function run() : Promise<BDDSuiteRunner>
	{
		var def = new Deferred<BDDSuiteRunner>();
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
