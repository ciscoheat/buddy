package ;

import BDDSuite;
import neko.Lib;
using Should;

class Main
{
	static function main()
	{
		var t = new TestAfterAndBefore();
		t.run().then(function(_) { done(t); });
	}

	static function done(t : TestAfterAndBefore)
	{
		for (s in t.suites)
		{
			Lib.println(s.name);
			for (sp in s.specs)
			{
				if (sp.status == TestStatus.Failed)
					Lib.println("  " + sp.description + " (FAILED: " + sp.error + ")");
				else
					Lib.println("  " + sp.description + " (" + sp.status + ")");
			}
		}
	}
}

class TestAfterAndBefore extends BDDSuite
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
				a.should().equal(1);
			});
		});

		describe("When testing after", {
			it("should not set 'testAfter' in the first spec", {
				testAfter.should().equal(null);
			});

			it("should call after before the second spec, and set 'testAfter'", {
				testAfter.should().equal("after executed");
			});

			after({
				testAfter = "after executed";
			});
		});
	}
}
