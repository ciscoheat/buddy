package buddy;
import buddy.Should.ShouldIterable;
using Lambda;

/*
X toBe(b);
X toBe(false);
X toBeCloseTo(e, 0);
- toBeDefined();
- toBeFalsy();
X toBeGreaterThan(0);
X toBeLessThan(e);
- toBeNull();
- toBeTruthy();
- toBeUndefined();
X toContain("bar");
X toEqual("I");
toHaveBeenCalled();
toHaveBeenCalledWith(456, 'another param');
toHaveBeenCalledWith(jasmine.any(Number), jasmine.any(Function));
toHaveBeenCalledWith(jasmine.objectContaining({
X toMatch(/bar/);
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

	public function new(value : Int, assert : SpecAssertion, inverse = false)
	{
		super(value, assert, inverse);
	}

	public var not(get, never) : ShouldInt;
	private function get_not() { return new ShouldInt(value, assert, !inverse); }

	//////////

	public function beLessThan(expected : Int)
	{
		assert(inverse ? value >= expected : value < expected, 'Expected less than $expected, was $value');
	}

	public function beGreaterThan(expected : Int)
	{
		assert(inverse ? value <= expected : value > expected, 'Expected greater than $expected, was $value');
	}
}

class ShouldFloat extends Should<Float>
{
	static public function should(i : Float, assert : SpecAssertion)
	{
		return new ShouldFloat(i, assert);
	}

	public function new(value : Float, assert : SpecAssertion, inverse = false)
	{
		super(value, assert, inverse);
	}

	public var not(get, never) : ShouldFloat;
	private function get_not() { return new ShouldFloat(value, assert, !inverse); }

	//////////

	public function beLessThan(expected : Float)
	{
		assert(inverse ? value >= expected : value < expected, 'Expected less than $expected, was $value');
	}

	public function beGreaterThan(expected : Float)
	{
		assert(inverse ? value <= expected : value > expected, 'Expected greater than $expected, was $value');
	}

	public function beCloseTo(expected : Float, precision : Int = 2)
	{
		var test = Math.abs(expected - value) < (Math.pow(10, -precision) / 2);

		if(inverse)
			assert(!test, 'Expected $value not to be close to $expected');
		else
			assert(test, 'Expected close to $expected, was $value');
	}
}

class ShouldString extends Should<String>
{
	static public function should(str : String, assert : SpecAssertion)
	{
		return new ShouldString(str, assert);
	}

	public function new(value : String, assert : SpecAssertion, inverse = false)
	{
		super(value, assert, inverse);
	}

	public var not(get, never) : ShouldString;
	private function get_not() { return new ShouldString(value, assert, !inverse); }

	//////////

	public function contain(substring : String)
	{
		var test = value.indexOf(substring) >= 0;

		if(inverse)
			assert(!test, 'Expected "$value" not to contain "$substring"');
		else
			assert(test, 'Expected "$value" to contain "$substring"');
	}

	public function match(regexp : EReg)
	{
		var test = regexp.match(value);

		if (inverse)
			assert(!test, 'Expected "$value" not to match regular expression');
		else
			assert(test, 'Expected "$value" to match regular expression');
	}
}

class ShouldIterable<T> extends Should<Iterable<T>>
{
	static public function should<T>(value : Iterable<T>, assert : SpecAssertion)
	{
		return new ShouldIterable<T>(value, assert);
	}

	public function new(value : Iterable<T>, assert : SpecAssertion, inverse = false)
	{
		super(value, assert, inverse);
	}

	public var not(get, never) : ShouldIterable<T>;
	private function get_not() { return new ShouldIterable<T>(value, assert, !inverse); }

	//////////

	public function contain(o : T)
	{
		var test = Lambda.exists(value, function(el) { return el == o; });

		if(inverse)
			assert(!test, 'Expected $value not to contain "$o"');
		else
			assert(test, 'Expected $value to contain "$o"');
	}

	/**
	 * Test if iterable contains all of the following values.
	 */
	public function containAll(values : Iterable<T>)
	{
		var test = true;

		// Having problem with java compilation for Lambda, using a simpler version:
		for (a in values)
		{
			if (!value.exists(function(v) { return v == a; } ))
			{
				test = false;
				break;
			}
		}

		if(inverse)
			assert(!test, 'Expected $value to not contain all of $values');
		else
			assert(test, 'Expected $value to contain all of $values');
	}

	/**
	 * Test if iterable contains exactly the following values and in the same iteration order.
	 */
	public function containExactly(values : Iterable<T>)
	{
		var a = value.iterator();
		var b = values.iterator();
		var test = true;

		while (a.hasNext() || b.hasNext())
		{
			if (a.next() != b.next())
			{
				test = false;
				break;
			}
		}

		if(inverse)
			assert(!test, 'Expected "$value" to not contain exactly "$values"');
		else
			assert(test, 'Expected "$value" to contain exactly "$values"');
	}
}

// Some problem with C++ forces this class not to be derived from Should<T>
class ShouldFunctions
{
	var value : Void -> Void;
	var assert : SpecAssertion;
	var inverse : Bool;

	public function new(value : Void -> Void, assert : SpecAssertion, inverse = false)
	{
		this.value = value;
		this.assert = assert;
		this.inverse = inverse;
	}

	public var not(get, never) : ShouldFunctions;
	private function get_not() { return new ShouldFunctions(value, assert, !inverse); }

	static public function should(value : Void -> Void, assert : SpecAssertion)
	{
		return new ShouldFunctions(value, assert);
	}

	/**
	 * Will call the specified method and test if it throws a specific value.
	 */
	public function throwValue(v : Dynamic)
	{
		var test = false;
		try { value(); }
		catch (e : Dynamic)
		{
			test = e == v;
		}

		if(inverse)
			assert(!test, 'Expected $value not to throw "$v"');
		else
			assert(test, 'Expected $value to throw "$v"');
	}

	/**
	 * Will call the specified method and test if it throws a specific type.
	 */
	public function throwType(type : Class<Dynamic>)
	{
		var test = false;
		var name : String = null;

		try { value(); }
		catch (e : Dynamic)
		{
			name = Type.getClassName(type);
			test = Std.is(e, type);
		}

		if(inverse)
			assert(!test, 'Expected $value not to throw type $name');
		else
			assert(test, 'Expected $value to throw type $name');
	}

	/**
	 * Test for equality between two value types (bool, int, float), or identity for reference types
	 */
	public function be(expected : Void -> Void) : Void
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

//////////

class Should<T>
{
	var value : T;
	var assert : SpecAssertion;
	var inverse : Bool;

	public function new(value : T, assert : SpecAssertion, inverse = false)
	{
		this.value = value;
		this.assert = assert;
		this.inverse = inverse;
	}

	/**
	 * Test for equality between two value types (bool, int, float), or identity for reference types
	 */
	public function be(expected : T) : Void
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
