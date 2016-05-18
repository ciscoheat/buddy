package buddy;
import buddy.internal.GenerateMain;
import buddy.reporting.Reporter;
import haxe.CallStack;
import haxe.CallStack.StackItem;
import haxe.Constraints.Function;
import haxe.Log;
import haxe.PosInfos;
import haxe.rtti.Meta;
import promhx.Deferred;
import promhx.Promise;
import buddy.BuddySuite;
import buddy.tools.AsyncTools in BuddyAsync;

#if utest
import utest.Assert;
import utest.Assertation;
#end

using Lambda;
using AsyncTools;

#if python
@:pythonImport("sys")
extern class PythonSys {
	public static function setrecursionlimit(i : Int) : Void;
} 
#end

private typedef Tests<T : Function> = {
	buddySuite: BuddySuite,
	testSuite: TestSuite,
	run: T
}

private typedef SyncTestResult = {
	error : Dynamic,
	step : Step
}

private typedef SyncSuiteResult = {
	error : Dynamic,
	suite : Suite
}

@:keep // Prevent dead code elimination, since SuitesRunner is created dynamically
class SuitesRunner
{
	// Used in Should
	public static var currentTest : Should.SpecAssertion;
	
	public var unrecoverableError : Dynamic = null;
	public var unrecoverableErrorStack : Array<StackItem> = null;
	
	private var allTestsPassed : Bool = false;
	private var buddySuites : Iterable<BuddySuite>;
	private var reporter : Reporter;
	private var runCompleted : Deferred<SuitesRunner>;
	
	private var oldLog : Dynamic -> ?PosInfos -> Void;

	///////////////////////////////////////////////////////////////////////
	
	public static function posInfosToStack(p : Null<PosInfos>) : Array<StackItem> {
		return p == null
			? [StackItem.FilePos(null, "", 0)]
			: [StackItem.FilePos(null, p.fileName, p.lineNumber)];
	}

	public function new(buddySuites : Iterable<BuddySuite>, ?reporter : Reporter) {
		this.buddySuites = buddySuites;
		this.reporter = reporter == null ? new buddy.reporting.ConsoleReporter() : reporter;
		this.oldLog = Log.trace;
	}
	
	public function run() : Promise<SuitesRunner> {
		#if python
		PythonSys.setrecursionlimit(100000);
		#end

		runCompleted = new Deferred<SuitesRunner>();
		var runCompletedPromise = runCompleted.promise();

		runDescribes(function(err) {
			if (err != null) haveUnrecoverableError(err);
			else startRun();
		});
		
		return runCompletedPromise;
	}
	
	private function runDescribes(cb : Dynamic -> Void) : Void {
		var asyncQueue = new Array<Tests<(Void -> Void) -> Void>>();
		var syncQueue = new Array<Tests<Void -> Void>>();
		
		function processSuiteDescribes(suite : BuddySuite) {
			while (!suite.describeQueue.empty()) {
				var current = suite.describeQueue.pop();
				
				switch current.spec {
					case Async(f): asyncQueue.push({
						buddySuite: suite,
						testSuite: current.suite,
						run: f
					});
						
					case Sync(f): syncQueue.push({
						buddySuite: suite,
						testSuite: current.suite,
						run: f
					});
				}
			}
		}
		
		function processCompleted(err : Dynamic) {
			if (err != null) return cb(err);

			// If includes exists, start pruning the Suite tree.
			if (Reflect.hasField(Meta.getType(BuddySuite), "includeMode")) startIncludeMode();
			cb(null);
		}
		
		function processBuddySuites() : Void {
			// Process the queue of describe calls
			for (buddySuite in buddySuites) processSuiteDescribes(buddySuite);
			
			if(syncQueue.length > 0) {
				try for (test in syncQueue) {
					test.buddySuite.currentSuite = test.testSuite;
					test.run();
				} catch (err : Dynamic) {
					return processCompleted(err);
				}
				
				syncQueue = [];
				processBuddySuites();
			} else if(asyncQueue.length > 0) {
				AsyncTools.aEachSeries(asyncQueue, function(test : Tests<(Void -> Void) -> Void>, cb : Dynamic -> Void) {
					test.buddySuite.currentSuite = test.testSuite;
					test.run(function() cb(null));
				}, function(err) {
					if (err != null) return processCompleted(err);
					asyncQueue = [];
					processBuddySuites();
				});
			} else
				cb(null);
		}
		
		processBuddySuites();
	}
	
	public function failed() return !allTestsPassed;
	public function statusCode() return failed() ? 1 : 0;

	/////////////////////////////////////////////////////////////////////////////

	private function startRun() : Void {
		reporter.start().then(function(go) {
			if (!go) {
				reporter.done([], false).then(function(_) runCompleted.resolve(this));
				return;
			}
			
			var beforeEachStack = [[]];
			var afterEachStack = [[]];
			
			AsyncTools.aMapSeries(buddySuites, function(buddySuite, done) { 
				mapTestSuite(
					buddySuite, 
					buddySuite.suite, 
					beforeEachStack, 
					afterEachStack, 
				function(err, suite) {
					// Errors outside it()
					if (err != null) {
						suite.error = err;
						suite.stack = CallStack.exceptionStack();
					}
					done(null, suite);
				});
			}, function(err, suites) {
				if (err != null) haveUnrecoverableError(err);
				else {
					allTestsPassed = !suites.exists(function(suite) return !suite.passed());
					reporter.done(suites, allTestsPassed).then(function(_) runCompleted.resolve(this));
				}
			});
		});
	}

	private function startIncludeMode() {
		// Filter out all tests not marked with @include
		function traverse(suite : TestSuite) : Bool {
			suite.specs = suite.specs.filter(function(spec) {
				switch spec {
					case Describe(suite, included):
						if (included) return true;
						else return traverse(suite);
					case It(desc, _, included):
						return included;
				}
			});
			return suite.specs.length > 0;
		}
		
		buddySuites = buddySuites.filter(function(buddySuite) {
			var suiteMeta = Meta.getType(Type.getClass(buddySuite));
			if (Reflect.hasField(suiteMeta, "include")) return true;
			
			return traverse(buddySuite.suite);
		});
	}
	
	private function mapTestSuite(
		buddySuite : BuddySuite, 
		testSuite : TestSuite, 
		beforeEachStack : Array<Array<TestFunc>>,
		afterEachStack : Array<Array<TestFunc>>,
		done : Dynamic -> Suite -> Void
	) : Void {
		var currentSuite = buddy.tests.SelfTest.lastSuite = new Suite(testSuite.description);
		
		beforeEachStack.push(testSuite.beforeEach.array());
		afterEachStack.unshift(testSuite.afterEach.array());

		var allSync = isSync(testSuite.beforeAll) && isSync(testSuite.afterAll);
		var result : SyncSuiteResult = null;
		var syncResultCount = 0;
		
		// === Run beforeAll
		runTestFuncs(testSuite.beforeAll, function(err) {
			if (err != null) {
				if (isSync(testSuite.beforeAll)) result = { error: err, suite: null };
				else done(err, currentSuite);
				return;
			}
			
			// === Map TestSpec -> Step
			AsyncTools.aMapSeries(testSuite.specs, function(testSpec : TestSpec, cb : Dynamic -> Step -> Void) {
				var result2 = mapTestSpec(buddySuite, testSuite, beforeEachStack, afterEachStack, testSpec, cb);
				if (result2 != null) {
					syncResultCount++;
					cb(result2.error, result2.step);
				}
			}, function(err : Dynamic, testSteps : Array<Step>) {
				allSync = allSync && testSteps.length == syncResultCount;
				
				if (err != null) {
					if (!allSync) done(err, currentSuite);
					else result = { error: err, suite: null };
					return;
				}
				
				// === Run afterAll
				runTestFuncs(testSuite.afterAll, function(err) {
					if (err != null) {
						if (!allSync) done(err, currentSuite);
						else result = { error: err, suite: null };
						return;
					}
					
					currentSuite.steps = testSteps;
					beforeEachStack.pop();
					afterEachStack.shift();

					if (!allSync) done(null, currentSuite);
					else result = { error: null, suite: currentSuite };
				});
			});
		});
		
		if (result != null) done(result.error, result.suite);
	}

	private function runTestFuncs(funcs : Iterable<TestFunc>, done : Dynamic -> Void) {
		var syncQ = [];
		var asyncQ = [];
		
		for(func in funcs) switch func {
			case Async(f): asyncQ.push(f);			
			case Sync(f): syncQ.push(f);
		}

		try for (f in syncQ) f()
		catch (err : Dynamic) return done(err);

		AsyncTools.aEachSeries(asyncQ, function(f, done) {
			f(function() done());
		}, done);
	}

	private function flatten<T>(arr : Array<Array<T>>) : Array<T> {
		return [for(a in arr) for(b in a) b];
	}
	
	private function isSync(funcs : Iterable<TestFunc>) : Bool {
		for (f in funcs) switch f {
			case Async(_): return false;
			case Sync(_):
		}
		return true;
	}

	private	function mapTestSpec(
		buddySuite : BuddySuite, 
		testSuite : TestSuite, 
		beforeEachStack : Array<Array<TestFunc>>,
		afterEachStack : Array<Array<TestFunc>>,
		testSpec : TestSpec,
		done : Dynamic -> Step -> Void
	) 
		: Null<SyncTestResult> 
	{
		var hasCompleted = false;
		var oldFail : ?Dynamic -> ?PosInfos -> Void = null;
		
		oldFail = buddySuite.fail = function(err : Dynamic = "Exception", ?p : PosInfos) {
			// Test if it still references the same suite.
			if (!hasCompleted && oldFail == buddySuite.fail) {
				done(err, null);
			}
		}
		var oldPending = buddySuite.pending = function(?message : String, ?p : PosInfos) {
			done("Cannot call pending here.", null);
		}

		switch testSpec {
			case Describe(testSuite, _): 
				// === Map TestSuite -> Suite
				mapTestSuite(buddySuite, testSuite, beforeEachStack, afterEachStack, function(err : Dynamic, newSuite : Suite) {
					if (err != null) done(err, null);
					else done(null, TSuite(newSuite));
				});
				return null;
				
			case It(desc, test, _):
				// Assign top-level spec var here, so it can be used in reporting.
				//trace("Starting it: " + desc);
				var spec = buddy.tests.SelfTest.lastSpec = new Spec(desc);
				
				var beforeEach = flatten(beforeEachStack);
				var afterEach = flatten(afterEachStack);					
				
				var eachIsSync = isSync(beforeEach) && isSync(afterEach);

				var returnSync = if(test == null) eachIsSync else switch test {
					case Sync(_): eachIsSync;
					case Async(_): false;
				}
				
				// Log traces for each Spec, so they can be outputted in the reporter
				if(!BuddySuite.useDefaultTrace) Log.trace = function(v, ?pos : PosInfos) {
					if(pos == null) spec.traces.push(Std.string(v));
					else spec.traces.push(pos.fileName + ":" + pos.lineNumber + ": " + v);
				};
				
				function reportFailure(error : Dynamic, stack : Array<StackItem>) : Void {
					if (hasCompleted) return;
					spec.status = Failed;
					spec.failures.push(new Failure(error, stack));
				}
				
				function specCompleted(status : SpecStatus) : Null<SyncTestResult> {
					if (hasCompleted) return null;
					hasCompleted = true;		
					
					if(spec.status == Unknown) spec.status = status;
					
					// Restore Log and set Suites fail function to null
					if(!BuddySuite.useDefaultTrace) Log.trace = oldLog;
					buddySuite.fail = oldFail;
					buddySuite.pending = oldPending;
					
					var syncResult = null;
					
					// === Run afterEach
					runTestFuncs(afterEach, function(err : Dynamic) {
						if (returnSync) {
							syncResult = {error: err, step: err == null ? TSpec(spec) : null};
							reporter.progress(spec);
						} else {
							if (err != null) done(err, null);
							else reporter.progress(spec).then(function(_) {
								done(null, TSpec(spec));
							});
						}
					});
					
					return syncResult;
				}

				// Test if spec is Pending (has only description)
				if (test == null) {
					return specCompleted(Pending);
				}

				// Create a test function that will be used in Should
				// note that multiple successfull tests doesn't mean the Spec is completed.
				SuitesRunner.currentTest = function(testStatus : Bool, error : Dynamic, stack : Array<StackItem>) {
					if (testStatus != true) reportFailure(error, stack);
				}
				
				// Set up utest if available
				#if utest
				Assert.results = new List<Assertation>();

				function checkUtestResults() {
					for (a in Assert.results) switch a {
						case Success(_):										
						case Warning(msg):
							spec.traces.push(msg);
						case Failure(e, pos):
							reportFailure(e, posInfosToStack(pos));
						case Error(e, stack), SetupError(e, stack), TeardownError(e, stack), AsyncError(e, stack):
							reportFailure(e, stack);
						case TimeoutError(e, stack):
							reportFailure(e, stack);
					}
				}
				#end
				
				#if (!php && !macro)
				// Set up timeout for the current spec
				if(!returnSync && buddySuite.timeoutMs > 0) {
					BuddyAsync.wait(buddySuite.timeoutMs)
						.catchError(function(e : Dynamic) { 
							reportFailure(e, CallStack.exceptionStack());
							specCompleted(Failed);
						})
						.then(function(_) {
							reportFailure('Timeout after ${buddySuite.timeoutMs} ms', []);
							specCompleted(Failed);
						});
				}
				#end
				
				////////////////////////////////////////////////////////////////////////////
				
				var _syncResult : SyncTestResult = null;
				
				function setSyncResult(status) {
					if (!returnSync || _syncResult != null) return; 
					_syncResult = status;
				}
				
				// Set up fail and pending function
				buddySuite.fail = function(err : Dynamic = "Manually", ?p : PosInfos) {
					reportFailure(err, posInfosToStack(p));
					setSyncResult(specCompleted(Failed));
				}

				buddySuite.pending = function(?message : String, ?p : PosInfos) {
					var msg = p.fileName + ":" + p.lineNumber + (message != null ? ': $message' : '');
					spec.traces.push(msg);
					setSyncResult(specCompleted(Pending));
				}
				
				// === Run beforeEach
				runTestFuncs(beforeEach, function(err) {
					if (err != null) {
						if(returnSync) setSyncResult({ error: err, step: null });
						else done(err, null);
						return;
					}

					function runTestFunc(func : TestFunc, done : Dynamic -> Void) {
						try switch func {
							case Async(f): f(function() done(null));
							case Sync(f): f(); done(null);
						} catch (e : Dynamic) {
							done(e);
						}
					}
					
					runTestFunc(test, function(err) {
						#if utest
						checkUtestResults();
						#end
						if (err != null) {
							reportFailure(err, CallStack.exceptionStack());
							setSyncResult(specCompleted(Failed));
						}
						else
							setSyncResult(specCompleted(Passed));
					});
				});

				//trace(_syncResult);
				return _syncResult;
		}
	}	

	public function haveUnrecoverableError(err) {
		unrecoverableError = err;
		unrecoverableErrorStack = CallStack.exceptionStack();
		runCompleted.resolve(this);
	}
}
