package ;
import BDDSuite;

/*
toBe(b);
toBe(false);
toBeCloseTo(e, 0);
toBeDefined();
toBeFalsy();
toBeGreaterThan(0);
toBeLessThan(e);
toBeNull();
toBeTruthy();
toBeUndefined();
toContain("bar");
toEqual("I");
toHaveBeenCalled();
toHaveBeenCalledWith(456, 'another param');
toHaveBeenCalledWith(jasmine.any(Number), jasmine.any(Function));
toHaveBeenCalledWith(jasmine.objectContaining({
toMatch(/bar/);
toThrow();
toThrowError("quux");
*/

/**
 * A function that specifies the status for a spec with an optional error message.
 */
typedef SpecAssertion = Bool -> String -> Void;

class ShouldInt extends Should<Int>
{
	static public function should(i : Int, assert : SpecAssertion)
	{
		return new ShouldInt(i, assert);
	}

	public function beLessThan(expected : Float)
	{
		assert(inverse ? value >= expected : value < expected, 'Expected less than $expected, was $value');
	}

	public function beGreaterThan(expected : Float)
	{
		assert(inverse ? value <= expected : value > expected, 'Expected greater than $expected, was $value');
	}

	public function new(value : Int, assert : SpecAssertion)
	{
		super(value, assert);
	}
}

class ShouldString extends Should<String>
{
	static public function should(str : String, assert : SpecAssertion)
	{
		return new ShouldString(str, assert);
	}

	public function new(value : String, assert : SpecAssertion)
	{
		super(value, assert);
	}
}

class Should<T>
{
	var value : T;
	var assert : SpecAssertion;
	var inverse : Bool;

	public var not(get, never) : Should<T>;

	private function get_not()
	{
		return new Should(value, assert, !inverse);
	}

	public function new(value : T, assert : SpecAssertion, inverse = false)
	{
		this.value = value;
		this.assert = assert;
		this.inverse = inverse;
	}

	public function equal(expected : T) : Void
	{
		if (Std.is(expected, String))
		{
			if(!inverse)
				assert(value == expected, 'Expected "$expected", was "$value"');
			else
				assert(value != expected, 'Expected not "$expected" but was equal to that');
		}
		else
		{
			if(!inverse)
				assert(value == expected, 'Expected $expected, was $value');
			else
				assert(value != expected, 'Expected not $expected but was equal to that');
		}
	}
}
