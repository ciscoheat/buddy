package buddy ;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.reporting.Reporter;
import haxe.CallStack;
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

enum TestStep
{
	TSuite(s : Suite);
	TSpec(s : Spec);
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
	@:allow(buddy.BuddySuite) public var parent(default, null) : Suite;
	@:allow(buddy.BuddySuite) public var include(default, null) : Bool;
	@:allow(buddy.BuddySuite) public var steps(default, null) : List<TestStep>;

	public var specs(get, never) : List<Spec>;
	private function get_specs() {
		var output = new List<Spec>();
		for(step in steps) switch step {
			case TSpec(s): output.add(s);
			case _:
		};
		return output;
	}

	public var suites(get, never) : List<Suite>;
	private function get_suites() {
		var output = new List<Suite>();
		for(step in steps) switch step {
			case TSuite(s): output.add(s);
			case _:
		};
		return output;
	}

	@:allow(buddy.internal.SuiteRunner) @:allow(buddy.BuddySuite) private var before : List<BeforeAfter>;
	@:allow(buddy.internal.SuiteRunner) @:allow(buddy.BuddySuite) private var after : List<BeforeAfter>;

	public function new(name : String, buddySuite : BuddySuite)
	{
		if (name == null) throw "Suite requires a name.";
		if (buddySuite == null) throw "Suite requires a BuddySuite.";

		this.name = name;
		this.buddySuite = buddySuite;

		this.before = new List<BeforeAfter>();
		this.after = new List<BeforeAfter>();
		this.steps = new List<TestStep>();
	}
}

class Spec
{
	public var suite(default, null) : Suite;
	public var description(default, null) : String;
	public var async(default, null) : Bool;
	public var status(default, null) : TestStatus;
	public var error(default, null) : String;
	@:allow(buddy.internal.SuiteRunner) public var stack(default, null) : Null<Array<StackItem>>;
	@:allow(buddy.internal.SuiteRunner) public var traces(default, null) : List<String>;

	@:allow(buddy.BuddySuite) private var include(default, null) : Bool;
	@:allow(buddy.internal.SuiteRunner) private var run : Action;

	@:allow(buddy.internal.SuiteRunner) private function setStatus(s : TestStatus, err : String, stack : Array<StackItem>)
	{
		this.status = s;
		this.error = err;
		this.stack = stack;
	}

	public function new(suite : Suite, description : String, run : Action, async = false, pending = false)
	{
		this.suite = suite;
		this.description = description;
		this.run = run;
		this.async = async;
		this.traces = new List<String>();

		if (run == null) this.status = TestStatus.Pending;
		else this.status = (pending ? TestStatus.Pending : TestStatus.Unknown);
	}
}

@:autoBuild(buddy.internal.SuiteBuilder.build())
class BuddySuite
{
	public var suites(default, null) : List<Suite>;

	@:allow(buddy.internal.SuiteRunner) @:allow(buddy.BuddySuite) private var befores : List<BeforeAfter>;
	@:allow(buddy.internal.SuiteRunner) @:allow(buddy.BuddySuite) private var afters : List<BeforeAfter>;

	// If set, suites are only included if marked by @include or if one of its specs are marked with @include
	public static var includeMode : Bool;

	public static var exclude(default, never) : String = "exclude";
	public static var include(default, never) : String = "include";

	// List of Suites that are currently created
	private var suiteStack : List<Suite>;

	/**
	 * Milliseconds before an async spec timeout with an error. Default is 5000 (5 sec).
	 */
	public var timeoutMs(default, default) : Int;

	public function new()
	{
		this.suites = new List<Suite>();
		this.befores = new List<BeforeAfter>();
		this.afters = new List<BeforeAfter>();
		this.suiteStack = new List<Suite>();

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
		if(suiteStack.isEmpty())
			suites.add(suite);
		else
		{
			var current = suiteStack.first();

			suite.parent = current;
			current.steps.add(TestStep.TSuite(suite));
		}

		if (includeMode && !suite.include)
		{
			// If suite hasn't @include set then test if it has specs marked with @include.
			// It should be done above addSpecs() so the child suites can be included if needed.
			suite.steps = suite.steps.filter(function(step) switch step {
				case TSpec(s): return s.include;
				case _: return true;
			});

			if (suite.steps.length > 0 || suite.parent.include)
				suite.include = true;
		}

		suiteStack.push(suite);
		addSpecs();
		suiteStack.pop();
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

	@:noCompletion private function beforeDescribe(init : Action)
	{
		syncBeforeDescribe(init, true);
	}

	@:noCompletion private function afterDescribe(init : Action)
	{
		syncAfterDescribe(init, true);
	}

	///// Hidden syncronous handlers /////

	@:noCompletion private function syncBeforeDescribe(init : Action, async = false)
	{
		befores.add(new BeforeAfter(init, async));
	}

	@:noCompletion private function syncAfterDescribe(init : Action, async = false)
	{
		afters.add(new BeforeAfter(init, async));
	}

	@:noCompletion private function syncBefore(init : Action, async = false)
	{
		suiteStack.first().before.add(new BeforeAfter(init, async));
	}

	@:noCompletion private function syncAfter(deinit : Action, async = false)
	{
		suiteStack.first().after.add(new BeforeAfter(deinit, async));
	}

	@:noCompletion private function syncIt(desc : String, test : Action, async = false, include = false)
	{
		var suite = suiteStack.first();
		var spec = new Spec(suite, desc, test, async);

		spec.include = include;
		suite.steps.add(TestStep.TSpec(spec));
	}

	@:noCompletion private function syncXit(desc : String, test : Action, async = false)
	{
		var suite = suiteStack.first();
		var spec = new Spec(suite, desc, test, async, true);

		suite.steps.add(TestStep.TSpec(spec));
	}
}

