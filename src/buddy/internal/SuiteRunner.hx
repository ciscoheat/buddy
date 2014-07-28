package buddy.internal;
import buddy.BuddySuite;
import buddy.reporting.Reporter;
import haxe.CallStack;
import haxe.Log;
import haxe.PosInfos;
import promhx.Deferred;
import promhx.Promise;

#if utest
import utest.Assert;
import utest.Assertation;
#end

using buddy.tools.AsyncTools;

class SuiteRunner
{
	var buddySuite : BuddySuite;
	var suite : Suite;
	var reporter : Reporter;

	public function new(suite : Suite, reporter : Reporter)
	{
		this.buddySuite = suite.buddySuite;
		this.suite = suite;
		this.reporter = reporter;
	}

	public function run() : Promise<Suite>
	{
		var traceFunc = Log.trace;
		var def = new Deferred<Suite>();
		var pr = def.promise();

		buddySuite.befores.iterateAsyncBool(runBeforeAfter)
			.pipe(function(_) return suite.steps.iterateAsyncBool(runSteps))
			.pipe(function(_) return buddySuite.afters.iterateAsyncBool(runBeforeAfter))
			.then(function(_) { Log.trace = traceFunc; def.resolve(suite); });

		return pr;
	}

	private function runBeforeAfter(b : BeforeAfter) : Promise<BeforeAfter>
	{
		var def = new Deferred<BeforeAfter>();
		var pr = def.promise();
		var done = function() { def.resolve(b); };

		b.run(done, function(s, err, stack) {});
		if (!b.async) done();

		return pr;
	}

	private function runSteps(step : TestStep) : Promise<TestStep>
	{
		var stepDone = new Deferred<TestStep>();
		var stepPr = stepDone.promise();

		switch step {
			case TSpec(spec): runSpec(spec).then(function(_) stepDone.resolve(step));
			case TSuite(s): new SuiteRunner(s, reporter).run().then(function(_) stepDone.resolve(step));
		}

		return stepPr;
	}

	private function runSpec(spec : Spec) : Promise<Spec>
	{
		// Spec = The whole spec (before, it, after)
		var specDone = new Deferred<Spec>();
		var specPr = specDone.promise();

		specPr.pipe(function(s) {
			return this.reporter != null ? reporter.progress(s) : specPr;
		});

		if (spec.status != TestStatus.Unknown)
		{
			specDone.resolve(spec);
			return specPr;
		}

		// It = The it part only
		var itDone = new Deferred<{status: TestStatus, error: String, stack: Array<StackItem>}>();
		var itPromise = itDone.promise();

		// The function that sets test status
		var hasStatus = false;
		var status = function(s, error, stack)
		{
			hasStatus = true;
			if (!s && !itPromise.isResolved())
				itDone.resolve( { status: TestStatus.Failed, error: error, stack: stack } );
		};

		// The function that should be called when an async operation has completed.
		var done = function()
		{
			#if utest
			for (a in Assert.results)
			{
				switch a {
					case Success(_):
						hasStatus = true;
					case Failure(e, pos):
						var stack = [StackItem.FilePos(null, pos.fileName, pos.lineNumber)];
						status(false, Std.string(e), stack);
						break;
					case Error(e, stack), SetupError(e, stack), TeardownError(e, stack), AsyncError(e, stack):
						status(false, Std.string(e), stack);
						break;
					case TimeoutError(e, stack):
						status(false, Std.string(e), stack);
						break;
					case Warning(_):
				}
			}
			#end

			if (!itPromise.isResolved())
				itDone.resolve( { status: hasStatus ? TestStatus.Passed : TestStatus.Pending, error: null, stack: null } );
		};

		Log.trace = function(v, ?pos : PosInfos) {
			spec.traces.add(pos.fileName + ":" + pos.lineNumber + ": " + Std.string(v));
		};

		var errorTimeout : Promise<Bool> = null;
		suite.before.iterateAsyncBool(runBeforeAfter)
			.pipe(function(_)
			{
				if (spec.async)
				{
					var timeout = buddySuite.timeoutMs;
					errorTimeout = AsyncTools.wait(timeout);

					// This promise will be rejected if done is called before timeout occurs.
					errorTimeout
						.catchError(function(e : Dynamic) if(e != null) throw e)
						.then(function(_) {
							status(false, 'Timeout after $timeout ms', null);
						});
				}

				try {
					#if utest
					Assert.results = new List<Assertation>();
					#end
					spec.run(done, status);
					if (!spec.async) done();
				}
				catch (e : Dynamic) {
					status(false, Std.string(e), CallStack.exceptionStack());
				}

				return itPromise;
			})
			.pipe(function(result)
			{
				if (errorTimeout != null)
				{
					errorTimeout.reject(null);
					errorTimeout = null;
				}

				spec.setStatus(result.status, result.error, result.stack);
				return suite.after.iterateAsyncBool(runBeforeAfter);
			})
			.then(function(_) { specDone.resolve(spec); } );

		return specPr;
	}
}