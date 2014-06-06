package buddy ;
import buddy.reporting.Reporter;
import promhx.Deferred;
import promhx.Promise;
import buddy.Should;
using buddy.tools.AsyncTools;

private typedef Action = (Void -> Void) -> SpecAssertion -> Void;

enum TestStatus
{
	Unknown;
	Passed;
	Pending;
	Failed;
}

private class BeforeAfter
{
	public var async(default, null) : Bool;
	@:allow(buddy.SuiteRunner) private var run : Action;

	public function new(run : Action, async = false)
	{
		this.run = run;
		this.async = async;
	}
}

class Suite
{
	public var name(default, null) : String;
	public var specs(default, null) : List<Spec>;

	@:allow(buddy.SuiteRunner) @:allow(buddy.BuddySuite) private var before : List<BeforeAfter>;
	@:allow(buddy.SuiteRunner) @:allow(buddy.BuddySuite) private var after : List<BeforeAfter>;

	public function new(name : String)
	{
		this.name = name;
		this.specs = new List<Spec>();
		this.before = new List<BeforeAfter>();
		this.after = new List<BeforeAfter>();
	}
}

class Spec
{
	public var suite(default, null) : Suite;
	public var description(default, null) : String;
	public var async(default, null) : Bool;
	public var status(default, null) : TestStatus;
	public var error(default, null) : String;

	@:allow(buddy.SuiteRunner) private var run : Action;

	@:allow(buddy.SuiteRunner) private function setStatus(s : TestStatus, err : String)
	{
		this.status = s;
		this.error = err;
	}

	public function new(suite : Suite, description : String, run : Action, async = false, pending = false)
	{
		this.suite = suite;
		this.description = description;
		this.run = run;
		this.async = async;

		if (run == null) this.status = TestStatus.Pending;
		else this.status = pending ? TestStatus.Pending : TestStatus.Unknown;
	}
}

@:autoBuild(buddy.internal.BDDSuiteBuilder.build())
class BuddySuite
{
	public var suites(default, null) : List<Suite>;

	public function new()
	{
		this.suites = new List<Suite>();
	}

	///// Private API /////

	private function describe(name : String, addSpecs : Void -> Void)
	{
		suites.add(new Suite(name));
		addSpecs();
	}

	private function before(init : Action)
	{
		syncBefore(init, true);
	}

	private function after(deinit : Action)
	{
		syncAfter(deinit, true);
	}

	private function it(desc : String, test : Action = null)
	{
		syncIt(desc, test, true);
	}

	private function xit(desc : String, test : Action = null)
	{
		syncXit(desc, test, true);
	}

	///// Hidden syncronous handlers /////

	@:noCompletion private function syncBefore(init : Action, async = false)
	{
		suites.last().before.add(new BeforeAfter(init, async));
	}

	@:noCompletion private function syncAfter(deinit : Action, async = false)
	{
		suites.last().after.add(new BeforeAfter(deinit, async));
	}

	@:noCompletion private function syncIt(desc : String, test : Action, async = false)
	{
		var suite = suites.last();
		suite.specs.add(new Spec(suite, desc, test, async));
	}

	@:noCompletion private function syncXit(desc : String, test : Action, async = false)
	{
		var suite = suites.last();
		suite.specs.add(new Spec(suite, desc, test, async, true));
	}
}

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