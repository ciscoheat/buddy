package buddy.tests ;
import buddy.BuddySuite;
import buddy.Buddy;
import haxe.Timer;
using buddy.Should;

#if neko
import neko.vm.Thread;
#end

class AllTests implements Buddy {}

class TestBasicFeatures extends BuddySuite
{
	private var testAfter : String;

	public function new()
	{
		describe("When testing before", {
			var a = 0;

			before({
				a = 1;
			});

			it("should set the variable a to 1 in before", {
				a.should.equal(1);
			});
		});

		describe("When testing after", {
			it("should not set 'testAfter' in the first spec", {
				testAfter.should.equal(null);
			});

			it("should call after before the second spec, and set 'testAfter'", {
				testAfter.should.equal("after executed");
			});

			after({
				testAfter = "after executed";
			});
		});

		describe("When testing ints", {
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

		describe("When testing should().not", {
			it("should invert the test condition", {
				"a".should.not.equal("b");
			});
		});
	}
}

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
				Timer.delay(function() { a = 1; }, 1);
			});
			#else
				#error
			#end

			it("should set the variable a to 1 in before even though it's an async operation", {
				a.should.equal(1);
			});
		});
	}
}
