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

class BeforeAfter
{
	public var async(default, null) : Bool;
	@:allow(buddy.internal.SuiteRunner) private var run : Action;

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

	@:allow(buddy.internal.SuiteRunner) @:allow(buddy.BuddySuite) private var before : List<BeforeAfter>;
	@:allow(buddy.internal.SuiteRunner) @:allow(buddy.BuddySuite) private var after : List<BeforeAfter>;

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

	@:allow(buddy.internal.SuiteRunner) private var run : Action;

	@:allow(buddy.internal.SuiteRunner) private function setStatus(s : TestStatus, err : String)
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

@:autoBuild(buddy.internal.SuiteBuilder.build())
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

