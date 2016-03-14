package buddy;
import buddy.reporting.Reporter;
import haxe.CallStack;
import haxe.CallStack.StackItem;
import haxe.Log;
import haxe.PosInfos;
import haxe.rtti.Meta;
import promhx.Deferred;
import promhx.Promise;
import buddy.BuddySuite;

#if utest
import utest.Assert;
import utest.Assertation;
#end

using buddy.tools.AsyncTools;

@:keep // prevent dead code elimination
class SuitesRunner
{
	public static var currentTest : Should.SpecAssertion;
	
	private var buddySuites : Iterable<BuddySuite>;
	private var reporter : Reporter;
	private var aborted : Bool;
	private var allTestsPassed = true;

	public function new(buddySuites : Iterable<BuddySuite>, ?reporter : Reporter)
	{
		// Cannot use Lambda here, Java problem in Linux.
		//var includeMode = [for (b in buddySuites) for (s in b.suites) if (s.include) s].length > 0;

		this.buddySuites = buddySuites;
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
		forEachSeries(buddySuites, function(suite, cb) {
			(function processQueue() {
				if (suite.describeQueue.isEmpty()) return cb(null);
				
				var current = suite.describeQueue.pop();
				suite.currentSuite = current.suite;
				
				// TODO: Errors when in describe phase?
				switch current.spec {
					case Async(f): f(processQueue);
					case Sync(f): f(); processQueue();
				}
			})();
		}, cb);
	}	
	
	public function run() : Promise<Bool>
	{
		var def = new Deferred<Bool>();
		var defPr = def.promise();
		
		runDescribes(function(err : Dynamic) {
			// TODO: Error handling

			function runTestFunc<T>(func : TestFunc, done : T -> Void) {
				switch func {
					case Async(f): f(function() done(null));
					case Sync(f): f(); done(null);
				}
			}
			
			var mapTestSpec : BuddySuite -> TestSuite -> TestSpec -> (Dynamic -> TestStep -> Void) -> Void = null;

			function mapTestSuite(buddySuite : BuddySuite, testSuite : TestSuite, done : Dynamic -> Suite -> Void) {				
				// Run beforeAll
				forEachSeries(testSuite.beforeAll, runTestFunc, function(err) {
					// TODO: Error handling
					mapSeries(testSuite.specs, mapTestSpec.bind(buddySuite, testSuite), function(err, testSteps) {
						forEachSeries(testSuite.afterAll, runTestFunc, function(err) {
							var suite = buddy.tests.SelfTest.lastSuite = new Suite(testSuite.description, testSteps);
							done(null, suite);
						});
					});
				});
			}

			mapTestSpec = function(buddySuite : BuddySuite, testSuite : TestSuite, testSpec : TestSpec, done : Dynamic -> TestStep -> Void) {
				var oldLog = Log.trace;
				var spec : Spec = null;

				function runAfterEach(err : Dynamic, result : TestStep) {
					Log.trace = oldLog;
					buddySuite.fail = null;
					
					forEachSeries(testSuite.afterEach, runTestFunc, function(err) 
						if (spec != null) reporter.progress(spec).then(function(_) done(err, result))
						else done(err, result)
					);
				}
				
				forEachSeries(testSuite.beforeEach, runTestFunc, function(err) {
					switch testSpec {						
						case Describe(testSuite): 
							mapTestSuite(buddySuite, testSuite, function(err, suite) {
								runAfterEach(null, TSuite(suite));
							});
							
						case It(desc, test): 
							spec = buddy.tests.SelfTest.lastSpec = new Spec(desc);
							var hasCompleted = false;
							
							Log.trace = function(v, ?pos : PosInfos) {
								spec.traces.push(pos.fileName + ":" + pos.lineNumber + ": " + Std.string(v));
							};

							function specCompleted(status : TestStatus, error : String, stack : Array<StackItem>) {
								if (hasCompleted) return;
								hasCompleted = true;
								
								spec.status = status;
								spec.error = error;
								spec.stack = stack;
								
								runAfterEach(null, TSpec(spec));
							}

							// Test if spec is Pending (has only description)
							if (test == null) {
								return specCompleted(Pending, null, null);
							}
		
							// Create a test that will be used in Should
							SuitesRunner.currentTest = function(testStatus : Bool, error : String, stack : Array<StackItem>) {
								if (hasCompleted || testStatus == true) return;
								
								allTestsPassed = false;
								specCompleted(Failed, error, stack);
							}
							
							// Set up utest if available
							#if utest
							Assert.results = new List<Assertation>();

							function checkUtestResults() {
								for (a in Assert.results) switch a {
									case Success(_):										
									case Warning(_):
									case Failure(e, pos):
										var stack = [StackItem.FilePos(null, pos.fileName, pos.lineNumber)];
										specCompleted(Failed, Std.string(e), stack);
										break;
									case Error(e, stack), SetupError(e, stack), TeardownError(e, stack), AsyncError(e, stack):
										specCompleted(Failed, Std.string(e), stack);
										break;
									case TimeoutError(e, stack):
										specCompleted(Failed, Std.string(e), stack);
										break;
								}
							}
							#end
							
							// Set up timeout for the current spec
							var timeout = buddySuite.timeoutMs;
							AsyncTools.wait(timeout)
								.catchError(function(e : Dynamic) if (e != null) throw e)
								.then(function(_) specCompleted(Failed, 'Timeout after $timeout ms', null));
							
							// Set up fail function
							buddySuite.fail = function(err : Dynamic = "Manually", ?p : PosInfos) {
								var stackItem = [StackItem.FilePos(null, p.fileName, p.lineNumber)];
								specCompleted(Failed, Std.string(err), stackItem);
							}
								
							try {
								runTestFunc(test, function(err) {
									// TODO: Error handling
									#if utest
									checkUtestResults();
									#end
									specCompleted(Passed, null, null);
								});
							} catch (e : Dynamic) {
								specCompleted(Failed, Std.string(e), CallStack.exceptionStack());
							}
					}
				});
			}
		
			mapSeries(buddySuites, function(buddySuite, done) {
				mapTestSuite(buddySuite, buddySuite.suite, done);
			}, function(err, suites) {
				// TODO: Error handling
				reporter.done(suites, allTestsPassed).then(function(_) def.resolve(allTestsPassed));
			});
		});
		
		return defPr;
	}

	public function failed() return !allTestsPassed;

	public function statusCode() : Int
	{
		if (aborted) return 1;
		return failed() ? 1 : 0;
	}
}
