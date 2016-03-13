package buddy;
import buddy.reporting.Reporter;
import haxe.rtti.Meta;
import promhx.Deferred;
import promhx.Promise;
import buddy.BuddySuite;
using buddy.tools.AsyncTools;

@:keep // prevent dead code elimination
class SuitesRunner
{
	private var suites : Iterable<BuddySuite>;
	private var reporter : Reporter;
	private var aborted : Bool;

	public function new(buddySuites : Iterable<BuddySuite>, ?reporter : Reporter)
	{
		// Cannot use Lambda here, Java problem in Linux.
		//var includeMode = [for (b in buddySuites) for (s in b.suites) if (s.include) s].length > 0;

		this.suites = buddySuites;
		//this.reporter = reporter == null ? new buddy.reporting.ConsoleReporter() : reporter;
	}

	private function forEachSeries<T>(iterable : Iterable<T>, cb : T -> (Void -> Void) -> Void, done : Void -> Void) {
		var iterator = iterable.iterator();
					
		(function next() {
			if (!iterator.hasNext()) done();
			else cb(iterator.next(), next);
		})();
	}

	private function runDescribes(cb : Void -> Void) {
		forEachSeries(suites, function(suite, cb) {
			forEachSeries(suite.describeQueue, function(wait, cb) {
				suite.currentSuite = wait.suite;
						
				switch wait.spec {
					case Async(f): f(cb);
					case Sync(f): f(); cb();
				}
			}, cb);
		}, cb);
	}
	
	
	public function run() : Promise<Bool>
	{
		var def = new Deferred<Bool>();
		var defPr = def.promise();
		
		runDescribes(function() {

			/*
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
			*/

			def.resolve(true);
		});
		
		return defPr;
	}

	public function failed() return false;
	
	/*
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

	private function runSuite(suite : Suite) : Promise<Suite>
	{
		return new SuiteRunner(suite, reporter).run();
	}
	*/

	public function statusCode() : Int
	{
		if (aborted) return 1;
		return failed() ? 1 : 0;
	}

}
