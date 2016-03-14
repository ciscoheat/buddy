package buddy;
import buddy.reporting.Reporter;
import haxe.CallStack.StackItem;
import haxe.Log;
import haxe.PosInfos;
import haxe.rtti.Meta;
import promhx.Deferred;
import promhx.Promise;
import buddy.BuddySuite;
using buddy.tools.AsyncTools;

@:keep // prevent dead code elimination
class SuitesRunner
{
	public static var currentTest : Should.SpecAssertion;
	
	private var suites : Iterable<BuddySuite>;
	private var reporter : Reporter;
	private var aborted : Bool;

	public function new(buddySuites : Iterable<BuddySuite>, ?reporter : Reporter)
	{
		// Cannot use Lambda here, Java problem in Linux.
		//var includeMode = [for (b in buddySuites) for (s in b.suites) if (s.include) s].length > 0;

		this.suites = buddySuites;
		this.reporter = reporter == null ? new buddy.reporting.ConsoleReporter() : reporter;
	}

	private function mapSeries<T, T2, Err>(
		iterable : Iterable<T>, 
		cb : T -> (Null<Err> -> Null<T2> -> Void) -> Void, 
		done : Null<Err> -> Null<Array<T2>> -> Void) 
	{
		var iterator = iterable.iterator();
		var output = [];
		
		(function next() {
			if (!iterator.hasNext()) done(null, output);
			else cb(iterator.next(), function(err, mapped) { 
				if (err == null) {
					output.push(mapped); 
					next();
				}
				else done(err, output);
			});
		})();
	}

	private function forEachSeries<T, Err>(
		iterable : Iterable<T>, 
		cb : T -> (Null<Err> -> Void) -> Void, 
		done : Null<Err> -> Void) 
	{
		var iterator = iterable.iterator();
					
		(function next(err : Null<Err>) {
			if (err != null) done(err);
			else if (!iterator.hasNext()) done(null);
			else cb(iterator.next(), next);
		})(null);
	}

	private function runDescribes(cb : Dynamic -> Void) {
		forEachSeries(suites, function(suite, cb) {
			forEachSeries(suite.describeQueue, function(current, cb) {
				suite.currentSuite = current.suite;
						
				// TODO: Errors when in describe phase?
				switch current.spec {
					case Async(f): f(function() cb(null));
					case Sync(f): f(); cb(null);
				}
			}, cb);
		}, cb);
	}
	
	
	public function run() : Promise<Bool>
	{
		var def = new Deferred<Bool>();
		var defPr = def.promise();
		var allTestsPassed = true;
		
		runDescribes(function(err : Dynamic) {
			if (err != null) throw err;

			function runTestFunc<T>(func : TestFunc, done : T -> Void) {
				switch func {
					case Async(f): f(function() done(null));
					case Sync(f): f(); done(null);
				}
			}
			
			var mapTestSpec : TestSuite -> TestSpec -> (Dynamic -> TestStep -> Void) -> Void = null;

			function mapTestSuite(testSuite : TestSuite, done : Dynamic -> Suite -> Void) {
				// Run beforeAll
				forEachSeries(testSuite.beforeAll, runTestFunc, function(err) {
					// TODO: Error handling
					mapSeries(testSuite.specs, mapTestSpec.bind(testSuite), function(err, testSteps) {
						forEachSeries(testSuite.afterAll, runTestFunc, function(err) {
							done(null, new Suite(testSuite.description, testSteps));
						});
					});
				});
			}

			mapTestSpec = function(testSuite : TestSuite, spec : TestSpec, done : Dynamic -> TestStep -> Void) {
				var oldLog = Log.trace;

				function runAfterEach(err : Dynamic, result : TestStep) {
					Log.trace = oldLog;
					forEachSeries(testSuite.afterEach, runTestFunc, function(err) done(err, result));
				}
				
				forEachSeries(testSuite.beforeEach, runTestFunc, function(err) {
					switch spec {				
						
						case Describe(testSuite): 
							mapTestSuite(testSuite, function(err, suite) {
								runAfterEach(null, TSuite(suite));
							});
						case It(desc, test): 
							var spec = new Spec(desc);
							var oldLog = Log.trace;
							
							Log.trace = function(v, ?pos : PosInfos) {
								spec.traces.push(pos.fileName + ":" + pos.lineNumber + ": " + Std.string(v));
							};

							var hasCompleted = false;

							function specCompleted() {
								hasCompleted = true;
								reporter.progress(spec).then(function(spec)
									runAfterEach(null, TSpec(spec))
								);
							}
							
							if (test == null) {
								spec.status = Pending;
								return specCompleted();
							}
		
							// Create a test that will be used in Should
							SuitesRunner.currentTest = function(testStatus : Bool, error : String, stack : Array<StackItem>) {
								if (hasCompleted || testStatus == true) return;
								
								allTestsPassed = false;
								
								spec.status = Failed;
								spec.error = error;
								spec.stack = stack;
								specCompleted();
							}
							
							runTestFunc(test, function(err) {
								// TODO: Error handling
								if (!hasCompleted) {
									spec.status = Passed;
									spec.error = null;
									spec.stack = null;							
									specCompleted();
								}
							});
					}
				});
			}
		
			mapSeries([for (s in suites) s.suite], mapTestSuite, function(err, suites) {
				// TODO: Error handling, reporter
				if (err != null) throw err;
				
				reporter.done(suites, allTestsPassed).then(function(_) def.resolve(allTestsPassed));
			});

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
