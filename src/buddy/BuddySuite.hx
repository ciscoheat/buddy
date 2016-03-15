package buddy ;
import buddy.reporting.Reporter;
import haxe.CallStack;
import haxe.PosInfos;
import haxe.ds.GenericStack;
import haxe.rtti.Meta;
import promhx.Deferred;
import promhx.Promise;
import buddy.Should;

#if cpp
import hxcpp.StaticStd;
import hxcpp.StaticRegexp;
#end

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
	@:allow(buddy.SuitesRunner) public var error(default, null) : String;
	@:allow(buddy.SuitesRunner) public var stack(default, null) = new Array<StackItem>();

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
	
	/**
	 * Returns true if this suite and all below it passed.
	 */
	public function passed() : Bool {
		if (specs.exists(function(spec) return spec.status == Failed)) return false;
		return !suites.exists(function(suite) return !suite.passed());
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
	Describe(suite : TestSuite, included : Bool);
	It(description : String, test : Null<TestFunc>, included : Bool);
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
	///// Internal vars /////
	
	/**
	 * Top-level test suite, used in reporting.
	 */ 
	@:allow(buddy.SuitesRunner) public var suite(default, null) : TestSuite;
	
	// For building the test suite structure.
	@:noCompletion @:allow(buddy.SuitesRunner) var currentSuite(default, default) : TestSuite;	
	@:noCompletion @:allow(buddy.SuitesRunner) var describeQueue(default, null) 
		= new List<{ suite: TestSuite, spec: TestFunc }>();

	///// Buddy API /////

	public function new() {
		suite = currentSuite = new TestSuite("");
	}

	/**
	 * Milliseconds before a spec timeout with an error. Default is 5000 (5 sec).
	 */
	public var timeoutMs(default, null) = 1000;

	/**
	 * Defines a test Suite, containing Specs and other Suites.
	 * @param	description Name that will be reported
	 * @param	spec A block or function of additional defines
	 * @param	hasInclude Only used internally
	 */
	private function describe(description : String, spec : TestFunc, _hasInclude = false) : Void {
		var suite = new TestSuite(description);
		
		currentSuite.specs.add(TestSpec.Describe(suite, _hasInclude));
		// Will be looped through in SuitesRunner:
		describeQueue.add({ suite: suite, spec: spec });
	}
		
	/**
	 * Defines a test Suite, but will not include it in any test execution.
	 * @param	description Name that will be reported
	 * @param	spec A block or function of additional defines
	 * @param	hasInclude Only used internally
	 */
	private function xdescribe(description : String, spec : TestFunc, _hasInclude = false) : Void {
		// Do nothing, suite is excluded.
	}

	/**
	 * Deprecated, use beforeEach instead.
	 */
	@:deprecated("Use beforeEach instead.")
	private function before(init : TestFunc) : Void beforeEach(init);

	/**
	 * Deprecated, use afterEach instead.
	 */
	@:deprecated("Use afterEach instead.")
	private function after(init : TestFunc) : Void afterEach(init);

	/**
	 * Defines a function that will be run before each underlying Suite or Spec.
	 */
	private function beforeEach(init : TestFunc) : Void currentSuite.beforeEach.add(init);
	
	/**
	 * Defines a function that will be run once at the beginning of the current Suite.
	 */
	private function beforeAll(init : TestFunc) : Void currentSuite.beforeAll.add(init);

	/**
	 * Defines a function that will be run after each underlying Suite or Spec.
	 */
	private function afterEach(init : TestFunc) : Void currentSuite.afterEach.add(init);
	
	/**
	 * Defines a function that will be run once at the end of the current Suite.
	 */
	private function afterAll(init : TestFunc) : Void currentSuite.afterAll.add(init);

	/**
	 * Defines a Spec, a test of conditions. Should is used for verifying the test itself.
	 * @param	desc Test description
	 * @param	spec A block or function of tests, or leave out for pending
	 * @param	hasInclude Only used internally
	 */
	private function it(desc : String, ?spec : TestFunc, _hasInclude = false) : Void {
		if (currentSuite == suite) throw "Cannot use 'it' outside of a describe block.";
		currentSuite.specs.add(TestSpec.It(desc, spec, _hasInclude));
	}

	/**
	 * Defines a pending Spec.
	 * @param	desc Test description
	 * @param	spec A block or function of tests, or leave out
	 * @param	hasInclude Only used internally
	 */
	private function xit(desc : String, ?spec : TestFunc, _hasInclude = false) : Void {
		if (currentSuite == suite) throw "Cannot use 'it' outside of a describe block.";
		currentSuite.specs.add(TestSpec.It(desc, null, _hasInclude));
	}

	/**
	 * Fails the current Spec, with an optional error message.
	 */
	@:allow(buddy.SuitesRunner) private var fail : ?Dynamic -> ?PosInfos -> Void;
}
