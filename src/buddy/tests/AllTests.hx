package buddy.tests ;

import buddy.BuddySuite;
import buddy.tests.AllTests.ColorTree;
import buddy.tools.AsyncTools;
import buddy.CompilationShould;
#if !java
import tink.core.Future;
#end

import haxe.CallStack;
import haxe.Int64;
import promhx.Deferred;
import promhx.Promise;
import Slambda.fn;
import utest.Assert;

#if (haxe_ver >= 4.1)
import Std.isOfType;
#else
import Std.is as isOfType;
#end


using buddy.Should;
using Slambda;
using StringTools;

#if !flash
@colorize
#end
class AllTests implements Buddy<[
	TestBasicFeatures,
	TestExclude,
	FailTest,
	#if (!php && !interp)
	TestAsync,
	FailTestAsync,
	#if !java
	TinkAwaitTest,
	#end
	BeforeAfterDescribe2,
	CallDoneTest,
	#end
	UtestUsage,
	TestExceptionHandling,
	BeforeAfterDescribe,
	BeforeAfterDescribe3,
	NestedBeforeAfter,
	SimpleNestedBeforeAfter,
	CompilationFailTest,
	HugeTest
]> {}

class EmptyTestClass { public function new() {} }

enum Color { Red; Green; Blue; }

enum ColorTree { Leaf(c : Color); Node(l : ColorTree, r : ColorTree); }

class ThrowInConstructor
{
	public function new() {
		throw "ThrowInConstructor";
	}
}

class TestBasicFeatures extends BuddySuite
{
	private var testAfter : String = "";

	public function new()
	{
		var top = 0;
		
		beforeAll({
			top++;
		});

		describe("Testing before", {
			var a = 0;

			beforeEach({
				a = 1;
			});

			it("should set the variable a to 1 in the before function", {				
				a.should.be(1);
				a = 2;
			});

			it("'before' should be run before every 'it' specification", {
				a.should.be(1);
			});
		});

		describe("Testing top-level beforeAll", {
			it("should be possible to set beforeAll before a top-level describe", {
				top.should.be(1);
			});
		});

		describe("Testing after", {
			it("should not set the property testAfter in this first spec", {
				testAfter.should.be("");
			});

			afterEach({
				testAfter = "after executed";
			});
		});

		describe("Testing dynamics", function() {
			var obj1 = { id: 1 };
			var obj2 = { id: 2 };
			var color1 = Red;
			var color2 = Green;

			it("should compare objects with be()", {
				obj1.should.be(obj1);
				obj1.should.not.be(obj2);
				Red.should.equal( Red );
				Red.should.not.equal( Green );
			});

			it("should compare types with beType()", {
				"str".should.beType(String);
				new EmptyTestClass().should.beType(EmptyTestClass);
				color1.should.beType(Color);
				color2.should.not.beType(Int);

				isOfType([1, 2, 3], Array).should.be(true);
				// Problem on C#:
				//[1, 2, 3].should.beType(Array);
			});

			it("should compare objects correctly when cast to Dynamic", {
				var arr : Dynamic = new Array<String>();
				var fn = function() return arr;
				
				arr.should.be(fn());
				// fn().should.be(arr); // Will fail because it's Unknown<0>, cast to fix.
			});			
		});

		#if (!php && !interp)
		describe("Testing async describe definitions", function(done) {
			var a = 0;

			it("should run specs after done has been called.", {
				a.should().be(1);
			});
			
			// lua fix, needs temp var
			var r = AsyncTools.wait(10);
			r.then(function(_) {
				a = 1;
				done();
			});
		});
		#end

		describe("Testing strings", {
			var str = "abc";

			it("should compare same string value with be()", {
				str.should().be("abc");
				str.should().not.be("cde");
			});

			it("should have a contain() method for matching substrings", {
				str.should().contain("a");
				str.should().contain("abc");
				str.should().not.contain("abcd");
			});

			it("should have a match() method for matching regexps", {
				str.should().match(~/a/);
				str.should().match(~/a\w+/);
				str.should().not.match(~/\d+/);
			});

			it("should have a startWith() method", {
				str.should().startWith("a");
				str.should().startWith("abc");
				str.should().not.startWith("b");
			});

			it("should have an endWith() method", {
				str.should().endWith("c");
				str.should().endWith("abc");
				str.should().not.endWith("b");
			});
		});
		
		describe("Testing Enums", {
			it("should make deep Enum comparisons", {
				var tree = Node(Node(Leaf(Red), Leaf(Green)), Leaf(Blue));				
				tree.should.equal(Node(Node(Leaf(Red), Leaf(Green)), Leaf(Blue)));
				
				switch tree {
					case Node(l, r): 
						l.should.equal(Node(Leaf(Red), Leaf(Green)));
						r.should.equal(Leaf(Blue));
						r.should.not.equal(Leaf(Green));
					case _: 
						fail("Incorrect tree structure for the test.");
				}
			});
		});

		describe("Testing ints", {
			var int = 3;

			it("should have a beLessThan() method", {
				int.should.beLessThan(4);
			});

			it("beLessThan should compare against float", {
				int.should.beLessThan(3.1);
			});

			it("should have a beGreaterThan() method", {
				int.should.beGreaterThan(2);
			});

			it("beGreaterThan should compare against float", {
				int.should.beGreaterThan(2.9);
			});
		});

		describe("Testing Int64", {
			var int64 = Int64.make(1, 1);
			
			it("should have a beLessThan() method", {
				int64.should.beLessThan(Int64.make(2, 0));
			});

			it("should have a beMoreThan() method", {
				int64.should.beGreaterThan(2147483647);
			});
			
			it("should test 'be' with equality, not identity", {
				var one : Int64 = 1000341504;
				var two : Int64 = 1000341504;

				one.should.be(two);
			});
		});

		describe("Testing floats", {
			var number = 3.14;
			var lostSignificance = 3.140000001;

			it("should have a beLessThan() method", {
				number.should.beLessThan(4.23);
			});

			it("beLessThan should compare against int", {
				number.should.beLessThan(cast(4, Int));
			});

			it("should have a beMoreThan() method", {
				number.should.beGreaterThan(2.9);
			});

			it("beMoreThan should compare against int", {
				number.should.beGreaterThan(cast(2, Int));
			});

			it("should have a beCloseTo() method", {
				number.should().beCloseTo(3.14);
				number.should().beCloseTo(3.1, 1);
				(3.1412).should().beCloseTo(3.1411, 3);
				number.should().beCloseTo(3.141);

				number.should().beCloseTo(lostSignificance);
				lostSignificance.should().beCloseTo(number);

				number.should().not.beCloseTo(3.1);
				number.should().not.beCloseTo(3.13);
				number.should().not.beCloseTo(3.15);
				(3.1412).should().not.beCloseTo(3.1417, 3);
			});
		});

		describe("Testing dates", {
			var date : Date;
			
			beforeEach({
				date = Date.fromString("2015-01-02 12:13:14");
			});

			it("should have a beOn() method", {
				date.should.beOn(Date.fromString("2015-01-02 12:13:14"));
			});
			
			it("should have a beOnStr() method", {
				date.should.beOnStr("2015-01-02 12:13:14");
			});

			it("should have a beAfter() method", {
				date.should.beAfter(Date.fromString("2015-01-01 12:13:14"));
			});
			
			it("should have a beAfterStr() method", {
				date.should.beAfterStr("2015-01-02 12:13:13");
			});

			it("should have a beBefore() method", {
				date.should.beBefore(Date.fromString("2016-01-01 12:13:14"));
			});
			
			it("should have a beBeforeStr() method", {
				date.should.beBeforeStr("2015-01-02 12:13:15");
			});						
		});

		describe("Testing Iterable", {
			var a = [1, 2, 3];
			var b = [1, 2, 3];

			var c = new List<Int>();
			c.add(1);
			c.add(2);
			c.add(3);

			it("should compare by identity", {
				a.should().be(a);
				a.should().not.be(b);
			});

			it("should have a contain() method", {
				a.should().contain(1);
				a.should().not.contain(4);
			});

			it("should have a containExactly() method", {
				a.should().containExactly([1, 2, 3]);
				a.should().containExactly(b);
				a.should().containExactly(c); // Different types

				a.should().not.containExactly([3, 2, 1]);
				a.should().not.containExactly([1, 2]);
				a.should().not.containExactly([1, 2, 3, 4]);

				[].should.containExactly([]);
			});

			it("should have a containAll() method", {
				a.should().containAll([1, 2, 3]);
				a.should().containAll(b);
				a.should().containAll([1]);

				a.should().not.containAll([3, 4]);
			});
		});

		describe("Testing functions", {
			var f = function() { return throw "a"; };
			var g = function() { return throw new EmptyTestClass(); };

			var h = function(a : String) { return throw a; };
			var i = function(a : String) { return throw a.toUpperCase(); };

			var j = function(a : String) : String { return throw a; };
			var k = function(a : String) : String { return throw a.toUpperCase(); };

			it("should have a be method", {
				#if !lua
				f.should().be(f);
				#end
				j.should().be(j);
				
				f.should().not.be(function() { throw "a"; });
				j.should().not.be(k);
			});
			
			it("should have a throwValue() method", {
				f.should().throwValue("a");
				var value = f.should().not.throwValue("b");
				
				if(value == null) 
					fail("value shouldn't be null");
				else {
					value.length.should.be(1);

					var char = value.charCodeAt(0);
					if(char == null) fail("char shouldn't be null");
					else char.should.be(97);
				}
			});

			it("should have a throwType() method", {
				var obj = g.should().throwType(EmptyTestClass);
				
				if(obj == null)
					fail("obj shouldn't be null");
				else
					obj.should.beType(EmptyTestClass);
			});

			it("should have a throwType() method that can be used with bind", {
				h.bind("a").should().throwValue("a");
				i.bind("a").should().not.throwValue("a");

				j.bind("a").should().throwValue("a");
				k.bind("a").should().not.throwValue("a");
			});

			it("should work with Slambda", {
				[1, 2, 3].filter.fn(_ > 2).should.containExactly([3]);
				[1, 2, 3].filter.fn(x => x > 1).should.containExactly([2, 3]);
				[1, 1, 1].mapi.fn([i, a] => i + a).should.containExactly([1, 2, 3]);
				[1, 2, 3].filter(fn(_ > 2)).should.containExactly([3]);

				// Disabling due to deprecated library.
				@:nullSafety(Off) ["1", "1", "1"].fold.fn(_2 + Std.parseInt(_1), 10).should.be(13);

				fn('$$_1')().should.be("$_1");

				var attr = function(name : String, cb : String -> Int -> Dynamic) {
					name.should.be("test");
					cb("a", 1).should.be("a-1");
				}
				
				attr.fn("test", _1 + "-" + _2);
				attr.fn("test", [a,b] => a + "-" + b);
			});

			it("should throw a correct exception if an exception is thrown in the constructor", {
				(function() { new ThrowInConstructor(); }).should.throwType(String);
				(function() { new ThrowInConstructor(); }).should.throwValue("ThrowInConstructor");
				(function() { new ThrowInConstructor(); }).should.throwAnything();
			});
		});

		describe("Testing should.not", {
			it("should invert the test condition", {
				"a".should.not.be("b");
				"a".should.not.not.be("a");
				(123).should.not.beLessThan(100);
			});
		});

		@:nullSafety(Off) describe("Testing null", {
			it("should pass even if the var is null", {
				var s : EmptyTestClass = null;
				var d : Dynamic = null;
				var i : Null<Int> = null;
				var b : Null<Bool> = null;
				var f : Null<Float> = null;
				s.should.be(null);
				d.should.be(null);
				i.should.be(null);
				b.should.be(null);
				f.should.be(null);
				
				#if (js || neko || php || python || lua || interp)
				var i : Int = null;
				i.should.be(null);
				#end
				
				#if js
				var undef : Dynamic = js.Lib.undefined;
				undef.should.be(null);
				#end
			});
		});

		describe("Excluding specs with @exclude and xit()", {
			@exclude it("should mark this spec as pending.", {
				true.should.be(false); // Make it fail if it runs
			});

			xit("should mark this as pending too.", {
				true.should.be(false); // Make it fail if it runs
			});

			it("should mark a spec with no body as pending too.");
			it("should mark a spec with an empty block as pending too.", {});
			it("should mark a spec with an empty function as pending too.", function() {});
		});

		xdescribe("Excluding suites with xdescribe()", {
			it("should not display this suite or its specs at all.", {
				true.should.be(false);
			});
		});

		@exclude describe("Excluding suites with @exclude", {
			it("should not display this suite or its specs at all.", {
				true.should.be(false);
			});
		});

		describe("Making specs pending manually", {
			it("can be done with the 'pending' method.", {
				pending("Manually");
			});
			
			afterEach({
				var test = SelfTest.lastSpec;
				SelfTest.passLastSpecIf(test.status == Pending && 
					test.traces.length == 1 &&
					test.traces[0].endsWith("Manually"), "Test wasn't pending with a message");
			});
		});

		describe("Using trace() calls", {
			it("should reroute the trace output to the reporter", {
				trace("Test", "a", "trace");
				trace("Test trace 2");
			});

			var trace1 = ~/AllTests\.hx:[0-9]+:\sTest,a,trace$/;
			var trace2 = ~/AllTests\.hx:[0-9]+:\sTest trace 2$/;

			afterEach({
				var test = SelfTest.lastSpec;
				if (test.traces.length == 2
					&& trace1.match(test.traces[0])
					&& trace2.match(test.traces[1]))
				{
					SelfTest.setLastSpec(Passed);
				} else {
					SelfTest.setLastSpec(Failed);
				}
			});
		});
		
		describe("Multiple 'should' failures in the same spec", {
			it("should report every failure in the spec", {
				(10).should.be(1);
				(11).should.be(1);
			});
			
			afterEach({
				var test = SelfTest.lastSpec;
				if (test.failures.length == 2 &&
					test.failures[0].error == "Expected 1, was 10" &&
					test.failures[1].error == "Expected 1, was 11")
				{
					SelfTest.setLastSpec(Passed);
				} else
					SelfTest.setLastSpec(Failed);
			});
		});

		#if (haxe_ver >= 4)
		describe("Testing before with short lambda", {
			beforeAll(() -> {});
			beforeEach(() -> {});
			beforeEach((done) -> done());
		});

		describe("Testing after with short lambda", {
			afterAll(() -> {});
			afterEach(() -> {});
			afterEach((done) -> done());
		});

		describe("Testing describe with short lambda", () -> {});
		describe("Testing describe with short lambda", () -> {}, false);
		describe("Testing describe with short lambda", (done) -> done());
		describe("Testing describe with short lambda", (done) -> done(), false);

		xdescribe("Testing xdescribe with short lambda", () -> {});
		xdescribe("Testing xdescribe with short lambda", () -> {}, false);
		xdescribe("Testing xdescribe with short lambda", (_) -> {});
		xdescribe("Testing xdescribe with short lambda", (_) -> {}, false);

		describe("Testing it with short lambda", {
			it("Should compile", () -> {});
			it("Should compile", (done) -> done());
		});

		describe("Testing xit with short lambda", {
			xit("Should compile", () -> {});
			xit("Should compile", (_) -> {});
		});
		#end
	}
}

@exclude
class TestExclude extends BuddySuite
{
	public function new()
	{
		describe("Excluding a whole BuddySuite", {
			it("should not not display any suites inside a class marked with @exclude.", {
				true.should.be(false);
			});
		});
	}
}

#if (!php && !interp)
class TestAsync extends BuddySuite
{
	public function new()
	{
		describe("Testing async", {
			var a = 0;

			beforeEach(function(done) {
				a = 0;
				timeoutMs = 10;
				// lua fix, needs temp var
				var r = AsyncTools.wait(1);
				r.then(function(_) { a = 1; done(); } );
			});

			it("should set the variable a to 1 in before, even though it's an async operation", {
				a.should.be(1);
			});

			var timeoutTestDescription = "should timeout with an error after an amount of time specified outside it()";
			it(timeoutTestDescription, function(done) {
				// Wait long enough for all targets to fail properly. (Had problems on flash when wait = 20)
				var r = AsyncTools.wait(100);
				r.then(function(_) {
					true.should.be(true);
					done();
				});
			});

			afterEach({
				var test = SelfTest.lastSpec;
				if(test.description == timeoutTestDescription)
					SelfTest.passLastSpecIf(test.status == Failed, "Didn't timeout");
			});
		});

		describe("An async failing assertion", {
			it("should not throw an AlreadyResolved exception when done is called", function(done) {
				// This test won't assert that the test passed, but it will throw an exception if it fails.
				(1).should.be(2);
				done();
			});

			afterEach({
				var test = SelfTest.lastSpec;
				SelfTest.passLastSpecIf(test.status == Failed && 
					test.failures.length == 1 &&
					test.failures[0].error == "Expected 2, was 1", "Threw an exception when done called after fail");
			});
		});
	}
}
#end

class TestExceptionHandling extends BuddySuite
{
	public function new()
	{
		describe("An exception thrown during testing", {
			this.timeoutMs = 50;
			var throwError = function() throw "Test error!";

			it("should be caught and the current spec will fail.", {
				throwError();
			});

			afterEach({
				var test = SelfTest.lastSpec;
				SelfTest.passLastSpecIf(test.status == Failed && 
					test.failures.length == 1 &&
					test.failures[0].error == "Test error!", "Exception wasn't caught");
			});
		});
	}
}

#if utest
class UtestUsage extends BuddySuite
{
	public function new()
	{
		describe("Using utest for assertions", {
			it("should pass a test when using the Assert class.", {
				var a = { test: {a: 123}, cls: new EmptyTestClass() };
				var b = { test: { a: 123 }, cls: new EmptyTestClass() };

				Assert.isTrue(true);
				Assert.same(a, b);
			});

			var failTestDesc = "should fail a test when using the Assert class.";
			it(failTestDesc, {
				Assert.isTrue(false);
			});

			#if (!php && !interp)
			it("should pass on asynchronous tests.", function(done) {
				// lua fix, needs temp var
				var r = AsyncTools.wait(5);
				r.then(function(_) {
					Assert.match(~/\d{3}/, "abc123");
					done();
				});
			});
			#end

			afterEach({
				var test = SelfTest.lastSpec;
				if(test.description == failTestDesc) {
					SelfTest.passLastSpecIf(test.status == Failed && 
						test.failures.length == 1 &&
						test.failures[0].error == "expected true", "Didn't fail using utest.Assert"
					);
				}
			});
		});

		describe("Using utest for maps", {
			it ("should compare maps correctly", {
				Assert.same([1 => 2], [1 => 2]);
				Assert.same(["a" => 1], ["a" => 1]);
			});
		});
	}
}
#end

class BeforeAfterDescribe extends BuddySuite
{
	public function new()
	{
		var a = 0;

		beforeEach({
			a = 1;
		});

		describe("Using a 'before' and 'after' block outside describe", {
			it("should run the blocks before each describe in the class.", {
				a.should.be(1);
			});
		});

		describe("Using a 'before' and 'after' block outside another describe", {
			it("should run the blocks before and after that describe too.", {
				a.should.be(1);
			});
		});

		afterEach({
			a = 0;
		});
	}
}

#if (!php && !interp)
class BeforeAfterDescribe2 extends BuddySuite
{
	public function new()
	{
		var a = 0;

		afterEach(function(done) {
			a = 1;
			done();
		});

		describe("Using an 'after' block outside describe", {
			it("should not run the after block before the first describe.", {
				a.should.be(0);
			});
		});

		describe("Using an 'after' block outside another describe in the same class", {
			it("should run the after blocks before and after the second describe.", {
				a.should.be(1);
			});
		});
	}
}
#end

class BeforeAfterDescribe3 extends BuddySuite
{
	public function new()
	{
		describe('Using nested describes', function () {
			var a = 0;
			var b = 0;

			beforeEach({
				a = 1;
			});

			it('should not run the specs described after an "it"', function() {
				a = 0;
				b.should.be(0);
			});

			describe('When nesting describes', function () {
				it('should run the inner "before" function before the spec', function() {
					b = 1;
					a.should.be(1);
				});
			});

			it('should have run the specs described before an "it"', function() {
				b.should.be(1);
			});
		});
	}
}

class NestedBeforeAfter extends BuddySuite
{
	public function new()
	{
		var a = -1000;
		var order = [];
		
		beforeAll({
			a = 0; // Level 0
			order.push("BA0");
		});

		beforeEach({
			order.push("BE0");
		});

		describe('Using nested describes with multiple befores', function () {
			beforeAll({ 
				order.push("BA1");
				a++; 				
			});
			
			beforeEach({
				order.push("BE1A");
			});

			beforeEach({
				order.push("BE1B");
			});

			it('should run befores outwards and in, and after inwards and out', function() {
				order.push("IT1");
				true.should.be(true); // Could change in after()
			});

			it('should run the befores defined up to this nested level', function() {
				order.push("IT2");
				a.should.be(1);
			});

			describe('When nesting on another level', function () {
				beforeAll( { 
					order.push("BA2");
					a++; 					
				});
				
				beforeEach({
					order.push("BE2");
				});

				it('should run the before defined up to this level', function () {
					order.push("IT3");
					a.should.be(2);
					
					//trace(CallStack.callStack().map(function(s) return s + "\n"));
				});

				afterEach({
					order.push("AE2");
				});
				
				afterAll( { 
					order.push("AA2");
					a--;
				});
			});
			
			it('should run in correct order when mixing its and describes', {
				order.push("IT4");
				a.should.be(1);
			});

			afterEach({
				order.push("AE1");
			});
			
			afterAll({
				a--;
				order.push("AA1");
			});
		});

		afterEach({
			order.push("AE0");
		});
		
		afterAll({
			order.push("AA0");			
			SelfTest.passLastSpecIf(a == 0 && order.join(",") == 
				"BA0,BA1,BE0,BE1A,BE1B,IT1,AE1,AE0,BE0,BE1A,BE1B,IT2,AE1,AE0," +
				"BA2,BE0,BE1A,BE1B,BE2,IT3,AE2,AE1,AE0,AA2,BE0,BE1A,BE1B,IT4,AE1,AE0,AA1,AA0",
				("Incorrect nested order: " + order)
			);
		});
	}
}

class SimpleNestedBeforeAfter extends BuddySuite
{
	public function new() {
        describe("Using before/after", {
            var test = 0;

            // Will run once in the current describe block
            beforeAll({
                test++;
            });

            // Will run before every "it" in this *and* in any nested describes.
            beforeEach({
                test++;
            });

            it("should be a convenient way to set up tests", {
                test.should.be(2);
            });

			describe("When nesting describes", {
				beforeEach({
					test++;
				});
				
				it("should run all before/afterEach defined here or above", {
					test.should.be(3);
				});
				
				afterEach({
					test--;
				});
			});
			
			it("should run in correct order too", {
				test.should.be(2);
			});

            // Will run after every "it" in this *and* in any nested describes.
            afterEach({
                test--;
            });

            // Will run once as the last thing in the current describe block
            afterAll({
                test--;
            });
        });		
	}
}

class FailTest extends BuddySuite
{
	public function new()
	{
		describe("Failing a test manually", {
			it('can be done by throwing an exception', {
				throw "Exceptionally";
			});

			afterEach({
				var	test = SelfTest.lastSpec;
				SelfTest.passLastSpecIf(test.failures.length == 1 &&
					test.failures[0].error == "Exceptionally", "Didn't fail when exception was thrown");
			});
		});

		describe("Failing a test manually", {
			it('can be done with the fail() method', {
				fail("fail()");
			});

			afterEach({
				var	test = SelfTest.lastSpec;
				SelfTest.passLastSpecIf(test.failures.length == 1 &&
					test.failures[0].error == "fail()", "Didn't fail when fail() was called");
			});
		});
	}
}

#if (!php && !interp)
class FailTestAsync extends BuddySuite
{
	public function new()
	{
		describe("Failing an async test manually", {
			it('can be done by passing the fail method as a callback', function(done) {
				var def = new Deferred();
				var pr = def.promise();

				pr.catchError(fail);
				pr.reject("Rejected");
			});
			
			afterEach({
				var test = SelfTest.lastSpec;
				SelfTest.passLastSpecIf(test.failures.length == 1 &&
					test.failures[0].error == "Rejected", "Didn't fail when using fail as a callback");
			});
		});
	}
}

#if !java
@await
class TinkAwaitTest extends BuddySuite 
{
	@:await public function new() {
		describe("Using tink_await with @await and @async on a BuddySuite", @await function() {
			it("should work properly", @await function(done) {
				var test = new UsingTinkAwait();
				var status : Bool = @:await test.waitForIt();
				status.should.be(true);
				done();
			});
		});
	}
}

class UsingTinkAwait
{
	public function new() {}

	public function waitForIt() {
		return Future.irreversible(function(cb) {
			// lua fix, needs temp var
			var r = AsyncTools.wait(1);
			r.then(cb);
		});
	}
}
#end

class CallDoneTest extends BuddySuite
{
	public function new()
	{
		describe("A test with no assertions and a call to done()", {
			it('should pass, not be marked as pending', function(done) {
				done();
			});
		});
	}
}
#end

class CompilationFailTest extends BuddySuite
{
	public function new()
	{
		describe("A test calling CompilationShould.failFor with an non-compiling expression", {
			it('should pass the test', {
				CompilationShould.failFor(this.is.not.compiling);
			});
		});
		
		describe("A test calling CompilationShould.failFor with an compiling expression", {
			it('should fail the test', {
				CompilationShould.failFor(BuddySuite.useDefaultTrace);
			});
			
			afterEach({
				var test = SelfTest.lastSpec;
				SelfTest.passLastSpecIf(test.failures.length == 1 && test.status == Failed, 
					"Failed when calling 'CompilationShould.failFor' with a valid expression."
				);
			});
		});
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////

class HugeTest extends BuddySuite
{
	public function new()
	{
		describe("Testing many and deep tests synchronously", {
			it('should not cause a stack overflow', { (true).should.be(true); });
			describe("Testing many and deep tests synchronously", {	
				it('should not cause a stack overflow', { (true).should.be(true); });				
			});
			
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {	
					it('should not cause a stack overflow', { (true).should.be(true); }); 					
				});
			});
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
				});
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); } );
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
									describe("Testing many and deep tests synchronously", {
										it('should not cause a stack overflow', { (true).should.be(true); } );
										describe("Testing many and deep tests synchronously", {
											it('should not cause a stack overflow', { (true).should.be(true); } );
										});						
										describe("Testing many and deep tests synchronously", {
											it('should not cause a stack overflow', { (true).should.be(true); } );
										});						
										describe("Testing many and deep tests synchronously", {
											it('should not cause a stack overflow', { (true).should.be(true); } );
										});						
										describe("Testing many and deep tests synchronously", {
											it('should not cause a stack overflow', { (true).should.be(true); } );
											describe("Testing many and deep tests synchronously", {
												it('should not cause a stack overflow', { (true).should.be(true); } );
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
													
													describe("Testing many and deep tests synchronously", {
														it('should not cause a stack overflow', { (true).should.be(true); } );
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});								
													});						
													describe("Testing many and deep tests synchronously", {
														it('should not cause a stack overflow', { (true).should.be(true); } );
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});						
														describe("Testing many and deep tests synchronously", {
															it('should not cause a stack overflow', { (true).should.be(true); } );
														});								
													});						
													
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});								
											});						
											describe("Testing many and deep tests synchronously", {
												it('should not cause a stack overflow', { (true).should.be(true); } );
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});						
												describe("Testing many and deep tests synchronously", {
													it('should not cause a stack overflow', { (true).should.be(true); } );
												});								
											});						
											
										});						
										describe("Testing many and deep tests synchronously", {
											it('should not cause a stack overflow', { (true).should.be(true); } );
										});						
										describe("Testing many and deep tests synchronously", {
											it('should not cause a stack overflow', { (true).should.be(true); } );
										});						
										describe("Testing many and deep tests synchronously", {
											it('should not cause a stack overflow', { (true).should.be(true); } );
										});						
										describe("Testing many and deep tests synchronously", {
											it('should not cause a stack overflow', { (true).should.be(true); } );
										});						
										describe("Testing many and deep tests synchronously", {
											it('should not cause a stack overflow', { (true).should.be(true); } );
										});								
									});						
									
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});								
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});							
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
					});
				});
			});		
		});
		

		
		
		describe("Testing many and deep tests synchronously", {
			it('should not cause a stack overflow', { (true).should.be(true); });
			describe("Testing many and deep tests synchronously", {	
				it('should not cause a stack overflow', { (true).should.be(true); });				
			});
			
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {	
					it('should not cause a stack overflow', { (true).should.be(true); }); 					
				});
			});
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
				});
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); } );
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});								
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});							
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
					});
				});
			});		
		});
		describe("Testing many and deep tests synchronously", {
			it('should not cause a stack overflow', { (true).should.be(true); });
			describe("Testing many and deep tests synchronously", {	
				it('should not cause a stack overflow', { (true).should.be(true); });				
			});
			
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {	
					it('should not cause a stack overflow', { (true).should.be(true); }); 					
				});
			});
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
				});
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); } );
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});								
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});							
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
					});
				});
			});		
		});
		describe("Testing many and deep tests synchronously", {
			it('should not cause a stack overflow', { (true).should.be(true); });
			describe("Testing many and deep tests synchronously", {	
				it('should not cause a stack overflow', { (true).should.be(true); });				
			});
			
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {	
					it('should not cause a stack overflow', { (true).should.be(true); }); 					
				});
			});
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
				});
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); } );
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});								
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});							
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
					});
				});
			});		
		});
		describe("Testing many and deep tests synchronously", {
			it('should not cause a stack overflow', { (true).should.be(true); });
			describe("Testing many and deep tests synchronously", {	
				it('should not cause a stack overflow', { (true).should.be(true); });				
			});
			
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {	
					it('should not cause a stack overflow', { (true).should.be(true); }); 					
				});
			});
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
				});
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); } );
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});								
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});							
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
					});
				});
			});		
		});
		describe("Testing many and deep tests synchronously", {
			it('should not cause a stack overflow', { (true).should.be(true); });
			describe("Testing many and deep tests synchronously", {	
				it('should not cause a stack overflow', { (true).should.be(true); });				
			});
			
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {	
					it('should not cause a stack overflow', { (true).should.be(true); }); 					
				});
			});
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
				});
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); } );
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});								
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});							
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
					});
				});
			});		
		});
		describe("Testing many and deep tests synchronously", {
			it('should not cause a stack overflow', { (true).should.be(true); });
			describe("Testing many and deep tests synchronously", {	
				it('should not cause a stack overflow', { (true).should.be(true); });				
			});
			
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {	
					it('should not cause a stack overflow', { (true).should.be(true); }); 					
				});
			});
			describe("Testing many and deep tests synchronously", {
				it('should not cause a stack overflow', { (true).should.be(true); });
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
				});
				describe("Testing many and deep tests synchronously", {
					it('should not cause a stack overflow', { (true).should.be(true); });
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); });
					});
					describe("Testing many and deep tests synchronously", {
						it('should not cause a stack overflow', { (true).should.be(true); } );
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});						
								describe("Testing many and deep tests synchronously", {
									it('should not cause a stack overflow', { (true).should.be(true); } );
								});								
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});						
							describe("Testing many and deep tests synchronously", {
								it('should not cause a stack overflow', { (true).should.be(true); } );
							});							
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
						describe("Testing many and deep tests synchronously", {
							it('should not cause a stack overflow', { (true).should.be(true); } );
						});						
					});
				});
			});		
		});
		
	}
}
