package buddy.tests ;
import buddy.BuddySuite;
import buddy.Buddy;
import buddy.tools.AsyncTools;
using buddy.Should;
using Lambda;
using StringTools;

class AllTests implements Buddy {}

class EmptyTestClass { public function new() {} }

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
			});
		});

		describe("Testing after", {
			it("should not set the property testAfter in this first spec", {
				testAfter.should.be(null);
			});

			it("should run the after function before this spec, and set testAfter", {
				testAfter.should.be("after executed");
			});

			after({
				testAfter = "after executed";
			});
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
		});

		describe("Testing ints", {
			var number = 3;

			it("should have a beLessThan() method", {
				number.should.beLessThan(4);
			});

			it("beLessThan should compare against float", {
				number.should.beLessThan(3.1);
			});

			it("should have a beMoreThan() method", {
				number.should.beGreaterThan(2);
			});

			it("beMoreThan should compare against float", {
				number.should.beGreaterThan(2.9);
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
			var f = function() { throw "a"; };
			var g = function() { throw new EmptyTestClass(); };

			var h = function(a : String) { throw a; };
			var i = function(a : String) { throw a.toUpperCase(); };

			var j = function(a : String) : String { throw a; };
			var k = function(a : String) : String { throw a.toUpperCase(); };

			it("should have a be method", {
				f.should().be(f);
				f.should().not.be(function(){});
			});

			it("should have a throwValue() method", {
				f.should().throwValue("a");
				f.should().not.throwValue("b");
			});

			it("should have a throwType() method", {
				g.should().throwType(EmptyTestClass);
				g.should().not.throwType(String);
			});

			it("should have a throwType() method that can be used with bind", {
				h.bind("a").should().throwValue("a");
				i.bind("a").should().not.throwValue("a");

				j.bind("a").should().throwValue("a");
				k.bind("a").should().not.throwValue("a");
			});
		});

		describe("Testing should.not", {
			it("should invert the test condition", {
				"a".should.not.be("b");
				"a".should.not.not.be("a");
				(123).should.not.beLessThan(100);
			});
		});

		describe("Excluding specs with @exclude and xit()", {
			@exclude it("should mark this spec as pending.", {
				true.should.be(false); // Make it fail if it runs
			});

			xit("should mark this as pending too.", {
				true.should.be(false); // Make it fail if it runs
			});

			it("should set specs marked with @exclude to Pending", {
				var suite = this.suites.find(function(s) { return s.name == "Excluding specs with @exclude and xit()"; } );
				suite.specs[0].status.should.be(TestStatus.Pending);
				suite.specs[1].status.should.be(TestStatus.Pending);
			});
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

		describe("Excluding suites with @exclude and xdescribe()", {
			it("should not display suites or their specs at all.", {
				this.suites.find(function(s) { return s.name == "Excluding suites with xdescribe()"; } ).should.be(null);
				this.suites.find(function(s) { return s.name == "Excluding suites with @exclude"; } ).should.be(null);
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
			var timeoutErrorTestDone : Void -> Void = null;

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
				// No done() call in this spec, timeout will take care of it, going to "after" automatically.
				timeoutErrorTest = this.suites.first().specs.find(function(s) {
					return s.description.indexOf(timeoutTestDescription) == 0;
				});
				timeoutErrorTest.status.should.be(TestStatus.Unknown);

				AsyncTools.wait(20).then(function(_) {
					if (timeoutErrorTest.status == TestStatus.Failed)
						Reflect.setProperty(timeoutErrorTest, "status", TestStatus.Passed);

					timeoutErrorTest = null;
					timeoutErrorTestDone();
				});
			});

			after(function(done) {
				if (timeoutErrorTest != null)
					timeoutErrorTestDone = done;
				else
					done();
			});
		});
	}
}
#end
