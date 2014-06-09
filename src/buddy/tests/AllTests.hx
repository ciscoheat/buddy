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

		describe("Testing ints", {
			var number = 3;

			it("should have a beLessThan method", {
				number.should.beLessThan(4);
			});

			it("beLessThan should compare against float", {
				number.should.beLessThan(3.1);
			});

			it("should have a beMoreThan method", {
				number.should.beGreaterThan(2);
			});

			it("beMoreThan should compare against float", {
				number.should.beGreaterThan(2.9);
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
		describe("When testing async", {
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

			it("should set the variable a to 1 in before even though it's an async operation", {
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
