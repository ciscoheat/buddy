package buddy.tests ;
import buddy.BuddySuite;
import buddy.Buddy;
using buddy.Should;

#if neko
import neko.vm.Thread;
#elseif cs
import cs.system.timers.ElapsedEventHandler;
import cs.system.timers.ElapsedEventArgs;
import cs.system.timers.Timer;
#elseif java
import java.util.concurrent.FutureTask;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
#elseif cpp
import cpp.vm.Thread;
#else
import haxe.Timer;
#end

class AllTests implements Buddy {}

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

		describe("Testing should.not", {
			it("should invert the test condition", {
				"a".should.not.be("b");
				"a".should.not.not.be("a");
				(123).should.not.beLessThan(100);
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

			#if neko
			before(function(done) {
				Thread.create(function() {
					Sys.sleep(0.1);
					a = 1;
					done();
				});
			});
			#elseif (js || flash)
			before(function(done) {
				Timer.delay(function() { a = 1; done(); }, 1);
			});
			#elseif cs
			before(function(done) {
				var t = new Timer(10);
				t.add_Elapsed(new ElapsedEventHandler(function(sender : Dynamic, e : ElapsedEventArgs) {
					t.Stop();
					a = 1;
					done();
				}));

				t.Start();
			});
			#elseif java
			before(function(done) {
				var executor = Executors.newFixedThreadPool(1);
				var call = new AsyncCallable(function() { a = 1; executor.shutdown(); done(); } );

				executor.execute(new FutureTask(call));
			});
			#elseif cpp
			before(function(done) {
				Thread.create(function() {
					Sys.sleep(0.1);
					a = 1;
					done();
				});
			});
			#else
				#error
			#end

			it("should set the variable a to 1 in before, even though it's an async operation", {
				a.should.be(1);
			});
		});
	}
}
#end

#if java
private class AsyncCallable implements Callable<String>
{
	private var done : Void -> Void;

	public function new(done : Void -> Void)
	{
		this.done = done;
	}

	public function call() : String
	{
		Sys.sleep(0.1);
		done();
		return "done";
	}
}
#end
