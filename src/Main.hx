package ;

import BDDSuite;
import neko.Lib;
using Should;

class Main
{
	static function main()
	{
		var t = new TestClass();
		t.run().then(function(_) { done(t); });
	}

	static function done(t : TestClass)
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

/*
class Test1 implements BDDSuite
{
	@describe("A test suite") function _()
	{
		var a;

		@before {
			a = 1;
		}

		@it("contains spec with an expectation") {
			a.should.be(1);
		}
	}
}
*/

class TestClass extends BDDSuite
{
	public function new()
	{
		describe("A test suite", {
			var a;

			before({
				trace("Before");
				a = 1;
			});

			it("should definitely set a = 1", {
				a.should().equal(1);
				trace("Running!");
			});

			after({
				trace("After");
			});
		});
	}
}
