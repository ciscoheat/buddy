package buddy ;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
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
	public var buddySuite(default, null) : BuddySuite;
	@:allow(buddy.BuddySuite) public var include(default, null) : Bool;
	@:allow(buddy.BuddySuite) public var specs(default, null) : Array<Spec>;

	@:allow(buddy.internal.SuiteRunner) @:allow(buddy.BuddySuite) private var before : List<BeforeAfter>;
	@:allow(buddy.internal.SuiteRunner) @:allow(buddy.BuddySuite) private var after : List<BeforeAfter>;

	public function new(name : String, buddySuite : BuddySuite)
	{
		this.name = name;
		this.buddySuite = buddySuite;

		this.specs = new Array<Spec>();
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
	@:allow(buddy.BuddySuite) public var include(default, null) : Bool;

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

	// If set, suites are only included if marked by @include or if one of its specs are marked with @include
	public static var includeMode : Bool;

	public static var exclude(default, never) : String = "exclude";
	public static var include(default, never) : String = "include";

	/**
	 * Milliseconds before an async spec timeout with an error. Default is 5000 (5 sec).
	 */
	public var timeoutMs(default, default) : Int;

	public function new()
	{
		this.suites = new List<Suite>();
		this.timeoutMs = 5000;
	}

	///// Private API /////

	private function describe(name : String, addSpecs : Void -> Void)
	{
		addSuite(new Suite(name, this), addSpecs);
	}

	private function xdescribe(name : String, addSpecs : Void -> Void)
	{}

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

	///// Hidden "include" handlers /////

	@:noCompletion private function addSuite(suite : Suite, addSpecs : Void -> Void)
	{
		suites.add(suite);
		addSpecs();

		if (!includeMode) return;

		if (!suite.include)
		{
			// If current suite has specs marked with @include, add them only.
			suite.specs = suite.specs.filter(function(sp) return sp.include);
			if (suite.specs.length > 0) suite.include = true;
		}

		suites = suites.filter(function(s) return s.include);
	}

	@:noCompletion private function describeInclude(name : String, addSpecs : Void -> Void)
	{
		includeMode = true;
		var suite = new Suite(name, this);
		suite.include = true;

		addSuite(suite, addSpecs);
	}

	@:noCompletion private function itInclude(desc : String, test : Action = null)
	{
		includeMode = true;
		syncIt(desc, test, true, true);
	}

	@:noCompletion private function syncItInclude(desc : String, test : Action = null)
	{
		includeMode = true;
		syncIt(desc, test, false, true);
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

	@:noCompletion private function syncIt(desc : String, test : Action, async = false, include = false)
	{
		var suite = suites.last();
		var spec = new Spec(suite, desc, test, async);

		spec.include = include;
		suite.specs.push(spec);
	}

	@:noCompletion private function syncXit(desc : String, test : Action, async = false)
	{
		var suite = suites.last();
		var spec = new Spec(suite, desc, test, async, true);

		suite.specs.push(spec);
	}
}

