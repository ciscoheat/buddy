package buddy.tests ;

import buddy.BuddySuite;
import buddy.Buddy;
import buddy.tools.AsyncTools;
import haxe.Timer;
import promhx.Deferred;
import promhx.Promise;

import Slambda.fn;
import utest.Assert;

using buddy.Should;
using Slambda;
using StringTools;

// Cannot use interface syntax for Java until
// https://github.com/HaxeFoundation/haxe/issues/4286 is fixed
@:build(buddy.GenerateMain.withSuites([
	TestBasicFeatures,
	TestExclude,
	//FailTest,
	#if !php
	TestAsync,
	//FailTestAsync,
	#end
	UtestUsage,
	TestExceptionHandling,
	/*
	BeforeAfterDescribe,
	BeforeAfterDescribe2,
	BeforeAfterDescribe3,
	NestedBeforeAfter,
	CallDoneTest
	*/
])) class AllTests {}

class EmptyTestClass { public function new() {} }

enum Color { Red; Green; Blue; }

class TestBasicFeatures extends BuddySuite
{
	private var testAfter : String;

	public function new()
	{
		describe("Testing before", {
			var a = 0;

			before({
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

		describe("Testing after", {
			it("should not set the property testAfter in this first spec", {
				testAfter.should.be(null);
			});

			after({
				testAfter = "after executed";
			});
		});

		describe("Testing dynamics", function(done) {
			var obj1 = { id: 1 };
			var obj2 = { id: 2 };
			var color1 = Red;
			var color2 = Green;

			it("should compare objects with be()", {
				obj1.should.be(obj1);
				obj1.should.not.be(obj2);
				Red.should.be( Red );
				Red.should.not.be( Green );
			});
			
			it("should compare types with beType()", {
				"str".should.beType(String);
				new EmptyTestClass().should.beType(EmptyTestClass);
				color1.should.beType(Color);
				color2.should.not.beType(Int); 
				
				Std.is([1, 2, 3], Array).should.be(true);
				// Problem on C#:
				//[1, 2, 3].should.beType(Array);
			});

			it("should compare objects correctly when cast to Dynamic", {
				var arr : Dynamic = new Array<String>();
				var fn = function() return arr;
				
				arr.should.be(fn());
				// fn().should.be(arr); // Will fail because it's Unknown<0>, cast to fix.
			});
			
			Timer.delay(done, 10);
		});

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

		describe("Testing ints", {
			var int = 3;

			it("should have a beLessThan() method", {
				int.should.beLessThan(4);
			});

			it("beLessThan should compare against float", {
				int.should.beLessThan(3.1);
			});

			it("should have a beMoreThan() method", {
				int.should.beGreaterThan(2);
			});

			it("beMoreThan should compare against float", {
				int.should.beGreaterThan(2.9);
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
				number.should().beCloseTo(3.141);

				number.should().beCloseTo(lostSignificance);
				lostSignificance.should().beCloseTo(number);

				number.should().not.beCloseTo(3.1);
				number.should().not.beCloseTo(3.13);
				number.should().not.beCloseTo(3.15);
			});
		});

		describe("Testing dates", {
			var date : Date;
			
			before({
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
			var a = [1,2,3];
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
				f.should().be(f);
				j.should().be(j);
				
				f.should().not.be(function() { throw "a"; });
				j.should().not.be(k);
			});
			
			it("should have a throwValue() method", {
				f.should().throwValue("a");
				var value = f.should().not.throwValue("b");
				
				value.length.should.be(1);
				value.charCodeAt(0).should.be(97);
			});

			it("should have a throwType() method", {
				var obj = g.should().throwType(EmptyTestClass);
				
				g.should().not.throwType(String);
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
				
				["1", "1", "1"].fold.fn(_2 + Std.parseInt(_1), 10).should.be(13);

				fn('$$_1')().should.be("$_1");

				var attr = function(name : String, cb : String -> Int -> Dynamic) {
					name.should.be("test");
					cb("a", 1).should.be("a-1");
				}
				
				attr.fn("test", _1 + "-" + _2);
				attr.fn("test", [a,b] => a + "-" + b);
			});			
		});

		describe("Testing should.not", {
			it("should invert the test condition", {
				"a".should.not.be("b");
				"a".should.not.not.be("a");
				(123).should.not.beLessThan(100);
			});
		});

		describe("Testing null", {
			it("should pass even if the var is null", {
				var s : EmptyTestClass = null;
				s.should.be(null);
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
			it("should mark a spec with an empty body as pending too.", {});
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

		describe("Using trace() calls", {
			it("should reroute the trace output to the reporter", {
				trace("Test trace");
				trace("Test trace 2");
			});

			after({
				var test = SelfTest.lastSpec;
				if (test.traces[0].startsWith("AllTests.hx")
					&& test.traces.length == 2
					&& test.traces[0].endsWith("Test trace")
					&& test.traces[1].endsWith("Test trace 2"))
				{
					SelfTest.setLastSpec(Passed);
				} else {
					SelfTest.setLastSpec(Failed);
				}
			});
		});
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

#if !php
class TestAsync extends BuddySuite
{
	public function new()
	{
		describe("Testing async", {
			var a;
			var timeoutErrorTest : Spec;
			var timeoutErrorTestDone : ?Bool -> Void = null;

			before(function(done) {
				a = 0;
				timeoutMs = 10;
				AsyncTools.wait(1).then(function(_) { a = 1; done(); } );
			});

			it("should set the variable a to 1 in before, even though it's an async operation", {
				a.should.be(1);
			});

			var timeoutTestDescription = "should timeout with an error after an amount of time specified outside it()";
			it(timeoutTestDescription, function(done) {
				// Wait long enough for all targets to fail properly. (Had problems on flash when wait = 20)
				AsyncTools.wait(100).then(function(_) {
					true.should.be(true);
					done();
				});
			});

			after({
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

			after({
				var test = SelfTest.lastSpec;
				if (test.status == TestStatus.Failed && test.error == "Expected 2, was 1")
					SelfTest.setLastSpec(Passed);
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

			after({
				var test = SelfTest.lastSpec;
				SelfTest.passLastSpecIf(test.status == Failed && test.error == "Test error!", "Exception wasn't caught");
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

			#if !php
			it("should pass on asynchronous tests.", function(done) {
				AsyncTools.wait(5).then(function(_) {
					Assert.match(~/\d{3}/, "abc123");
					done();
				});
			});
			#end

			after({
				var test = SelfTest.lastSpec;
				if(test.description == failTestDesc) {
					SelfTest.passLastSpecIf(
						test.status == Failed && test.error == "expected true", "Didn't fail using utest.Assert"
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

/*
class BeforeAfterDescribe extends BuddySuite
{
	public function new()
	{
		var a = 0;

		before({
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

		after({
			a = 0;
		});
	}
}

class BeforeAfterDescribe2 extends BuddySuite
{
	public function new()
	{
		var a = 0;

		after(function(done) {
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

class BeforeAfterDescribe3 extends BuddySuite
{
	public function new()
	{
		describe('Using nested describes', function () {
			var a = 0;

			before({
				a = 1;
			});

			it('should not run the specs described after an "it"', function() {
				this.suites.first().suites.first().specs.first().status.should.be(TestStatus.Unknown);
			});

			describe('When nesting describes', function () {
				var desc = 'should run the inner "before" function before the spec';
				it(desc, function() {
					a.should.be(1);
				});

				it('should list the specs in the nested suite', function () {
					var test = this.suites.first().suites.first().specs.first();
					test.description.should.be(desc);
				});
			});

			it('should have run the specs described before an "it"', function() {
				this.suites.first().suites.first().specs.first().status.should.be(TestStatus.Passed);
			});
		});
	}
}

class NestedBeforeAfter extends BuddySuite
{
	public function new()
	{
		var a = 0;
		var order = "";
		var runAfterTest = false;

		before({
			a = 0; // Level 0
			order = "0";
			runAfterTest = false;
		});

		describe('Using nested describes with multiple befores', function () {
			before({
				a++; // Level 1
				order += "1";
			});

			it('should run befores outwards and in, and after inwards and out', function() {
				true.should.be(true); // Could change in after()
			});

			it('should run the befores defined up to this nested level', function() {
				a.should.be(1);
			});

			describe('When nesting on another level', function () {
				before({
					a++; // Level 2
					order += "2";
				});

				it('should run the before defined up to this level', function () {
					runAfterTest = true;
					a.should.be(2);
				});

				after({
					a--;
					order += "2";
				});
			});

			after({
				a--;
				order += "1";
			});
		});

		// The 'after' order is important here since they will be executed in reverse order.
		after({
			if (runAfterTest)
			{
				var test = this.suites.first().specs.first();
				Reflect.setProperty(test, "status", a == -1 && order == "012210" ? TestStatus.Passed : TestStatus.Failed);
			}
		});

		after({
			a--;
			order += "0";
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

			after({
				var test = this.suites.first().specs.first();
				Reflect.setProperty(test, "status", test.error == "Exceptionally" ? TestStatus.Passed : TestStatus.Failed);
			});
		});

		describe("Failing a test manually", {
			it('can be done with the fail() method', {
				fail("fail()");
			});

			after({
				var test = this.suites.last().specs.last();
				Reflect.setProperty(test, "status", test.error == "fail()" ? TestStatus.Passed : TestStatus.Failed);
			});
		});
	}
}

#if !php
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
		});

		after({
			var test = this.suites.first().specs.first();
			Reflect.setProperty(test, "status", test.error == "Rejected" ? TestStatus.Passed : TestStatus.Failed);
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
*/