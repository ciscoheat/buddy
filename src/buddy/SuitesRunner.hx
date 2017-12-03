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
	private var includeMode : Bool;
	
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
		this.includeMode = buddySuites.exists(function(suite) { 
			var metaData = Meta.getType(Type.getClass(suite));
			return Reflect.hasField(metaData, "includeMode");
		});
	}
	
	public function run() : Promise<SuitesRunner> {
		#if python
		PythonSys.setrecursionlimit(100000);
		#end

		runCompleted = new Deferred<SuitesRunner>();
		var runCompletedPromise = runCompleted.promise();

		runDescribes(function(err) {
			if (err != null) {
				haveUnrecoverableError(err);
				return;
			}
			
			if (includeMode) startIncludeMode();
			startRun();
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
		
		function processBuddySuites() : Void {
			// Process the queue of describe calls
			for (buddySuite in buddySuites) processSuiteDescribes(buddySuite);
			
			if(syncQueue.length > 0) {
				try for (test in syncQueue) {
					test.buddySuite.currentSuite = test.testSuite;
					test.run();
				} catch (err : Dynamic) {
					return cb(err);
				}
				
				syncQueue = [];
				processBuddySuites();
			} else if(asyncQueue.length > 0) {
				AsyncTools.aEachSeries(asyncQueue, function(test : Tests<(Void -> Void) -> Void>, cb : Dynamic -> Void) {
					test.buddySuite.currentSuite = test.testSuite;
					test.run(function() cb(null));
				}, function(err) {
					if (err != null) return cb(err);
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
		// lua fix, needs temp var
		var r = reporter.start();
		r.then(function(go) {
			if (!go) {
				var r = reporter.done([], false);
				r.then(function(_) runCompleted.resolve(this));
				return;
			}
			
			var beforeEachStack = [[]];
			var afterEachStack = [[]];
			
			AsyncTools.aMapSeries(buddySuites, function(buddySuite, done) { 
				function suiteDone(err : Dynamic, suite : Suite) {
					if (err == null && suite == null) return;
					// Errors outside it()
					if (err != null) {
						suite.error = err;
						suite.stack = CallStack.exceptionStack();
					}
					done(err, suite);
				}
				
				var syncSuite = mapTestSuite(
					buddySuite, 
					buddySuite.suite, 
					beforeEachStack, 
					afterEachStack, 
					suiteDone
				);
				if (syncSuite != null) {
					suiteDone(syncSuite.error, syncSuite.suite);
				}
				
			}, function(err, suites) {
				if (err != null) haveUnrecoverableError(err);
				else {
					allTestsPassed = !suites.exists(function(suite) return !suite.passed());
					var r = reporter.done(suites, allTestsPassed);
					r.then(function(_) runCompleted.resolve(this));
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
					case It(desc, _, included, _):
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
	) : Null<SyncSuiteResult> {
		var currentSuite = buddy.tests.SelfTest.lastSuite = new Suite(testSuite.description);
		
		beforeEachStack.push(testSuite.beforeEach.array());
		afterEachStack.unshift(testSuite.afterEach.array());

		var allSync = isSync(testSuite.beforeAll) && isSync(testSuite.afterAll);
		var result : SyncSuiteResult = null;
		var syncResultCount = 0;
		
		// === Run beforeAll
		runTestFuncs(testSuite.beforeAll, function(err) {
			if (err != null) {
				if (isSync(testSuite.beforeAll)) result = { error: err, suite: currentSuite };
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
				// It's important to return currentSuite as well in this function, not null.
				
				allSync = allSync && testSteps.length == syncResultCount;
				
				if (err != null) {
					if (allSync) result = { error: err, suite: currentSuite }; 
					else done(err, currentSuite);
					return;
				}
				
				// === Run afterAll
				runTestFuncs(testSuite.afterAll, function(err) {
					if (err != null) {
						if (allSync) result = { error: err, suite: currentSuite };
						else done(err, currentSuite);
						return;
					}
					
					currentSuite.steps = testSteps;
					beforeEachStack.pop();
					afterEachStack.shift();

					if (allSync) result = { error: null, suite: currentSuite };
					else done(null, currentSuite);
				});
			});
		});
		
		if (result != null) done(null, null);		
		return result;
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
			default:
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
				var result = mapTestSuite(buddySuite, testSuite, beforeEachStack, afterEachStack, function(err : Dynamic, newSuite : Suite) {
					if (err == null && newSuite == null) return;
					if (err != null) done(err, null);
					else done(null, TSuite(newSuite));
				});
				if (result != null) return { error: result.error, step: TSuite(result.suite) };
				else return null;
				
			case It(desc, test, _, pos):
				// Assign top-level spec var here, so it can be used in reporting.
				//trace("Starting it: " + desc);
				var spec = buddy.tests.SelfTest.lastSpec = new Spec(desc, pos.fileName);
				
				var beforeEach = flatten(beforeEachStack);
				var afterEach = flatten(afterEachStack);					
				
				var eachIsSync = isSync(beforeEach) && isSync(afterEach);

				var returnSync = if(test == null) eachIsSync else switch test {
					case Sync(_): eachIsSync;
					case Async(_): false;
				}
				
				// Log traces for each Spec, so they can be outputted in the reporter
				if(!BuddySuite.useDefaultTrace) Log.trace = function(v : Dynamic, ?pos : PosInfos) {
					if (pos == null) 
						spec.traces.push(Std.string(v));
					else {
						var output = pos.customParams != null
							? Std.string(v) + "," + pos.customParams.map(function(v2) return Std.string(v2)).join(',')
							: Std.string(v);
						
						spec.traces.push(pos.fileName + ":" + pos.lineNumber + ": " + output);
					}
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
							else {
								// lua fix, needs temp var
								var r = reporter.progress(spec);
								r.then(function(_) {
									done(null, TSpec(spec));
								});
							}
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
						#if (utest >= "1.7.1")
						case Ignore(reason):
							spec.traces.push("Assertation ignored: " + reason);
						#end
					}
				}
				#end
				
				#if (!php && !macro && !interp)
				// Set up timeout for the current spec
				if(!returnSync && buddySuite.timeoutMs > 0) {
					// lua fix, needs temp var
					var r = BuddyAsync.wait(buddySuite.timeoutMs);
					r.catchError(function(e : Dynamic) { 
						reportFailure(e, CallStack.exceptionStack());
						specCompleted(Failed);
					});
					r.then(function(_) {
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
