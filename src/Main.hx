package ;

import BDDSuite;
import haxe.Timer;
import neko.Lib;
import neko.vm.Thread;
using Should;

class Main
{
	static function main()
	{
		var suites = [new TestBasicFeatures(), new TestAsync()];
		var reporter = new ConsoleReporter();

		var testsRunning = true;
		new BDDSuiteRunner(suites, reporter).run().then(function(_) { testsRunning = false; });
		while(testsRunning)	Sys.sleep(0.1);
	}
}

class TestBasicFeatures extends BDDSuite
{
	private var testAfter : String;

	public function new()
	{
		describe("When testing before", {
			var a;

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
			it("should have a beLessThan method", {
				(3).should.beLessThan(4);
			});

			it("beLessThan should compare against float", {
				3.should.beLessThan(3.1);
			});

			it("should have a beMoreThan method", {
				3.should.beGreaterThan(2);
			});

			it("beMoreThan should compare against float", {
				(3).should.beGreaterThan(2.9);
			});
		});

		describe("When testing should().not", {
			it("should invert the test condition", {
				"a".should.not.equal("b");
			});
		});
	}
}

class TestAsync extends BDDSuite
{
	public function new()
	{
		describe("When testing async", {
			var a;

			before(function(done) {
				Thread.create(function() {
					Sys.sleep(0.1);
					a = 1;
					done();
				});
			});

			it("should set the variable a to 1 in before even though it's an async operation", {
				a.should.equal(1);
			});
		});
	}
}
