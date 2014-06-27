package buddy.internal;
import buddy.BuddySuite;
import buddy.reporting.Reporter;
import haxe.CallStack;
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
		return suite.specs.iterateAsync(runSpec, suite);
	}

	private function runBeforeAfter(b : BeforeAfter) : Promise<BeforeAfter>
	{
		var def = new Deferred<BeforeAfter>();
		var pr = def.promise();
		var done = function() { def.resolve(b); };

		b.run(done, function(s : Bool, err : String) {});
		if (!b.async) done();

		return pr;
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
		var itDone = new Deferred<{status : TestStatus, error : String}>();
		var itPromise = itDone.promise();

		// The function that sets test status
		var hasStatus = false;
		var status = function(s, error)
		{
			hasStatus = true;
			if (!s && !itPromise.isResolved())
				itDone.resolve( { status: TestStatus.Failed, error: error } );
		};

		// The function that should be called when an async operation has completed.
		var done = function()
		{
			#if utest
			for (a in Assert.results)
			{
				switch a {
					case Success(_): hasStatus = true;
					case Failure(e, _):
						status(false, Std.string(e));
						break;
					case Error(e, stack), SetupError(e, stack), TeardownError(e, stack), AsyncError(e, stack):
						spec.stack = stack;
						status(false, Std.string(e));
						break;
					case TimeoutError(e, stack):
						spec.stack = stack;
						status(false, Std.string(e));
						break;
					case Warning(_):
				}
			}
			#end

			if (!itPromise.isResolved())
				itDone.resolve( { status: hasStatus ? TestStatus.Passed : TestStatus.Pending, error: null } );
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
							status(false, 'Timeout after $timeout ms');
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
					spec.stack = CallStack.exceptionStack();
					status(false, Std.string(e));
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

				spec.setStatus(result.status, result.error);
				return suite.after.iterateAsyncBool(runBeforeAfter);
			})
			.then(function(_) { specDone.resolve(spec); } );

		return specPr;
	}
}