package ;
import BDDSuite;

typedef SpecAssertion = Bool -> String -> Void;

class ShouldInt
{
	static public function should(i : Int, assert : SpecAssertion)
	{
		return new Equal<Int>(i, assert);
	}
}

class ShouldString
{
	static public function should(str : String, assert : SpecAssertion)
	{
		return new Equal<String>(str, assert);
	}
}

class Equal<T>
{
	var value : T;
	var assert : SpecAssertion;

	public function new(value : T, assert : SpecAssertion)
	{
		this.value = value;
		this.assert = assert;
	}

	public function equal(test : T) : Void
	{
		assert(value == test, 'Expected $value, was $test');
	}
}
