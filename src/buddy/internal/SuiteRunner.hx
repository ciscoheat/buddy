package buddy.internal;
import buddy.BuddySuite;
import buddy.reporting.Reporter;
import promhx.Deferred;
import promhx.Promise;
using buddy.tools.AsyncTools;

class SuiteRunner
{
	var suite : Suite;
	var reporter : Reporter;

	public function new(suite : Suite, reporter : Reporter)
	{
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

		if (spec.status != TestStatus.Unknown)
		{
			specDone.resolve(spec);
			return specPr;
		}

		// Test = The it part only
		var itDone = new Deferred<{status : TestStatus, error : String}>();
		var itPromise = itDone.promise();

		var hasStatus = false;
		var status = function(s, error)
		{
			hasStatus = true;
			if (!s && !itPromise.isResolved())
				itDone.resolve({ status: TestStatus.Failed, error: error });
		};

		var done = function()
		{
			if (!itPromise.isResolved())
				itDone.resolve({ status: hasStatus ? TestStatus.Passed : TestStatus.Pending, error: null });
		};

		suite.before.iterateAsyncBool(runBeforeAfter)
			.pipe(function(_) { spec.run(done, status); if (!spec.async) done(); return itPromise; } )
			.pipe(function(result)
			{
				spec.setStatus(result.status, result.error);
				if(reporter != null) reporter.progress(spec);

				return suite.after.iterateAsyncBool(runBeforeAfter);
			})
			.then(function(_) { specDone.resolve(spec); } );

		return specPr;
	}
}