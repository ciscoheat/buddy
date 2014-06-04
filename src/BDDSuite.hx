package ;
import promhx.Deferred;
import promhx.Promise;
using AsyncTools;

typedef Action = (Void -> Void) -> Void;

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
	@:allow(SuiteRunner) private var run : Action;

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

	@:allow(SuiteRunner) @:allow(BDDSuite) private var before : List<BeforeAfter>;
	@:allow(SuiteRunner) @:allow(BDDSuite) private var after : List<BeforeAfter>;

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
	public var description(default, null) : String;
	public var async(default, null) : Bool;
	public var status(default, null) : TestStatus;

	@:allow(SuiteRunner) private var run : Action;
	@:allow(SuiteRunner) private function setStatus(s : TestStatus) { this.status = s; };

	public function new(description : String, run : Action, async = false, pending = false)
	{
		this.description = description;
		this.run = run;

		if (run == null) this.status = TestStatus.Pending;
		else this.status = pending ? TestStatus.Pending : TestStatus.Unknown;
	}
}

@:autoBuild(BDDSuiteBuilder.build())
class BDDSuite
{
	public static var current(default, default) : BDDSuite = new BDDSuite();
	public var suites(default, null) : List<Suite>;

	public function new()
	{
		suites = new List<Suite>();
	}

	///// Public API /////

	public function run() : Promise<BDDSuite>
	{
		return suites.iterateAsync(function(s) { return new SuiteRunner(s).run(); }, this);
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
		suites.last().specs.add(new Spec(desc, test, async));
	}

	@:noCompletion private function syncXit(desc : String, test : Action, async = false)
	{
		suites.last().specs.add(new Spec(desc, test, async, true));
	}
}

private class SuiteRunner
{
	var suite : Suite;

	public function new(suite : Suite)
	{
		this.suite = suite;
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

		b.run(done);
		if (!b.async) done();

		return pr;
	}

	private function runSpec(spec : Spec) : Promise<Spec>
	{
		// Spec = The whole spec (before, it, after)
		var specDone = new Deferred<Spec>();
		var specPr = specDone.promise();

		// Test = The it part only
		var itDone = new Deferred<Bool>();
		var itPromise = itDone.promise();
		var done = function() { itDone.resolve(true); };

		// Only run tests that are not executed yet.
		if (spec.status == TestStatus.Unknown)
		{
			suite.before.iterateAsyncBool(runBeforeAfter)
				.pipe(function(_) { spec.run(done); if (!spec.async) done(); return itPromise; } )
				.pipe(function(_) { spec.setStatus(TestStatus.Passed); return suite.after.iterateAsyncBool(runBeforeAfter); } )
				.then(function(_) { specDone.resolve(spec); } )
				.catchError(function(_) { spec.setStatus(TestStatus.Failed); specDone.resolve(spec); } );
		}
		else
		{
			specDone.resolve(spec);
		}

		return specPr;
	}
}