package buddy ;
import buddy.reporting.Reporter;
import haxe.CallStack;
import haxe.PosInfos;
import haxe.ds.GenericStack;
import haxe.rtti.Meta;
import haxecontracts.Contract;
import haxecontracts.HaxeContracts;
import promhx.Deferred;
import promhx.Promise;
import buddy.Should;

using buddy.tools.AsyncTools;
using Lambda;

// Final status of a Spec
enum SpecStatus {
	Unknown;
	Passed;
	Pending;
	Failed;
}

// An alias for backwards compatibility
@:deprecated("TestStatus is deprecated, please rename to SpecStatus")
typedef TestStatus = SpecStatus;

// A completed test step inside a Describe (Either a Suite or a Spec)
enum Step {
	TSuite(s : Suite);
	TSpec(s : Spec);
}

// A completed test suite ("Describe")
class Suite
{
	public var description(default, null) : String;
	@:allow(buddy.SuitesRunner) public var steps(default, null) = new Array<Step>();

	public var specs(get, never) : Array<Spec>;
	private function get_specs() {
		var output = [];
		for(step in steps) switch step {
			case TSpec(s): output.push(s);
			case _:
		}
		return output;
	}

	public var suites(get, never) : Array<Suite>;
	private function get_suites() {
		var output = [];
		for(step in steps) switch step {
			case TSuite(s): output.push(s);
			case _:
		}
		return output;
	}

	public function new(description : String, steps : Iterable<Step>) {
		if (description == null) throw "Suite requires a description.";
		if (steps == null) throw "Suite steps cannot be null.";
		
		this.description = description;
		this.steps = steps.array();
	}
}

// A completed spec ("It")
class Spec
{
	public var description(default, null) : String;
	@:allow(buddy.SuitesRunner) public var status(default, null) : SpecStatus = Unknown;
	@:allow(buddy.SuitesRunner) public var error(default, null) : String;
	@:allow(buddy.SuitesRunner) public var stack(default, null) = new Array<StackItem>();
	@:allow(buddy.SuitesRunner) public var traces(default, null) = new Array<String>();

	//@:allow(buddy.BuddySuite) private var include(default, null) : Bool;

	public function new(description : String) {
		if(description == null) throw "Spec must have a description.";
		this.description = description;
	}
}

///// Classes and enums starting with "Test" represents the system before testing is completed.
///// While testing, they are transformed into Spec and Suite.

enum TestFunc {
	Async(f : (Void -> Void) -> Void);
	Sync(f : Void -> Void);
}

enum TestSpec {
	Describe(suite : TestSuite);
	It(description : String, test : Null<TestFunc>);
}

class TestSuite
{
	public var description(default, null) : String;
	
	public var beforeAll = new List<TestFunc>();
	public var beforeEach = new List<TestFunc>();
	
	public var specs = new List<TestSpec>();
	
	public var afterEach = new List<TestFunc>();
	public var afterAll = new List<TestFunc>();	
	
	public function new(description : String) {
		if(description == null) throw "TestSuite must have a description. Can be empty.";
		this.description = description;
	}
}

@:autoBuild(buddy.internal.SuiteBuilder.build())
class BuddySuite
{
	// If set, suites are only included if marked by @include or if one of its specs are marked with @include
	public static var includeMode = false;

	public static var exclude(default, never) = "exclude";
	public static var include(default, never) = "include";

	/**
	 * Milliseconds before an async spec timeout with an error. Default is 5000 (5 sec).
	 */
	public var timeoutMs(default, default) = 5000;

	/**
	 * Top-level test suite
	 */
	public var suite : TestSuite;
	
	// For building the test suite structure. Used in SuitesRunner
	@:allow(buddy.SuitesRunner) var currentSuite(default, default) : TestSuite;
	
	@:allow(buddy.SuitesRunner) var describeQueue(default, null) 
		= new List<{ suite: TestSuite, spec: TestFunc }>();

	//public var include(default, default) = false;
	
	public function new() {
		suite = currentSuite = new TestSuite("");
	}

	///// Private API /////

	private function describe(description : String, spec : TestFunc) {
		var suite = new TestSuite(description);
		
		currentSuite.specs.add(TestSpec.Describe(suite));
		// Will be looped through in SuitesRunner:
		describeQueue.add({ suite: suite, spec: spec });
	}
		
	private function xdescribe(description : String, spec : TestFunc) {
		// Do nothing, suite is excluded.
	}

	@:deprecated("Use beforeEach instead.")
	private function before(init : TestFunc) beforeEach(init);

	@:deprecated("Use afterEach instead.")
	private function after(init : TestFunc) afterEach(init);

	private function beforeEach(init : TestFunc) currentSuite.beforeEach.add(init);
	private function beforeAll(init : TestFunc) currentSuite.beforeAll.add(init);
	private function afterEach(init : TestFunc) currentSuite.afterEach.add(init);
	private function afterAll(init : TestFunc) currentSuite.afterAll.add(init);
	
	private function it(desc : String, spec : TestFunc) {
		currentSuite.specs.add(TestSpec.It(desc, spec));
	}

	/**
	 * Creates a pending Spec.
	 */
	private function xit(desc : String, ?spec : TestFunc) {
		currentSuite.specs.add(TestSpec.It(desc, null));
	}

	/**
	 * Fails the current Spec.
	 */
	@:allow(buddy.SuitesRunner) private var fail : ?Dynamic -> ?PosInfos -> Void;
}
