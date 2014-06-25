package buddy;
import buddy.Should.ShouldIterable;
import haxe.PosInfos;
using Lambda;
using StringTools;

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
- toThrow();
X toThrowError("quux");
*/

/**
 * A function that specifies the status for a spec with an optional error message.
 */
typedef SpecAssertion = Bool -> String -> Void;

/**
 * This must be the first class in this package, since it overrides all other assertions otherwise.
 */
class ShouldDynamic extends Should<Dynamic>
{
	static public function should<T>(d : T, assert : SpecAssertion)
	{
		return new ShouldDynamic(d, assert);
	}

	public var not(get, never) : ShouldDynamic;
	private function get_not() { return new ShouldDynamic(value, assert, !inverse); }
}

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

	public function beLessThan(expected : Int, ?p : PosInfos)
	{
		test(value < expected, p,
			'Expected less than ${quote(expected)}, was ${quote(value)}',
			'Expected not less than ${quote(expected)}, was ${quote(value)}'
		);
	}

	public function beGreaterThan(expected : Int, ?p : PosInfos)
	{
		test(value > expected, p,
			'Expected greater than ${quote(expected)}, was ${quote(value)}',
			'Expected not greater than ${quote(expected)}, was ${quote(value)}'
		);
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

	public function beLessThan(expected : Float, ?p : PosInfos)
	{
		test(value < expected, p,
			'Expected less than ${quote(expected)}, was ${quote(value)}',
			'Expected not less than ${quote(expected)}, was ${quote(value)}'
		);
	}

	public function beGreaterThan(expected : Float, ?p : PosInfos)
	{
		test(value > expected, p,
			'Expected greater than ${quote(expected)}, was ${quote(value)}',
			'Expected not greater than ${quote(expected)}, was ${quote(value)}'
		);
	}

	public function beCloseTo(expected : Float, precision : Int = 2, ?p : PosInfos)
	{
		var expr = Math.abs(expected - value) < (Math.pow(10, -precision) / 2);

		test(expr, p,
			'Expected close to ${quote(expected)}, was ${quote(value)}',
			'Expected ${quote(value)} not to be close to ${quote(expected)}'
		);
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

	public function contain(substring : String, ?p : PosInfos)
	{
		test(value.indexOf(substring) >= 0, p,
			'Expected ${quote(value)} to contain ${quote(substring)}',
			'Expected ${quote(value)} not to contain ${quote(substring)}'
		);
	}

	public function startWith(substring : String, ?p : PosInfos)
	{
		test(value.startsWith(substring), p,
			'Expected ${quote(value)} to start with ${quote(substring)}',
			'Expected ${quote(value)} not to start with ${quote(substring)}'
		);
	}

	public function endWith(substring : String, ?p : PosInfos)
	{
		test(value.endsWith(substring), p,
			'Expected ${quote(value)} to end with ${quote(substring)}',
			'Expected ${quote(value)} not to end with ${quote(substring)}'
		);
	}

	public function match(regexp : EReg, ?p : PosInfos)
	{
		test(regexp.match(value), p,
			'Expected ${quote(value)} to match regular expression',
			'Expected ${quote(value)} not to match regular expression'
		);
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

	public function contain(o : T, ?p : PosInfos)
	{
		test(Lambda.exists(value, function(el) return el == o), p,
			'Expected ${quote(value)} to contain ${quote(o)}',
			'Expected ${quote(value)} not to contain ${quote(o)}'
		);
	}

	/**
	 * Test if iterable contains all of the following values.
	 */
	public function containAll(values : Iterable<T>, ?p : PosInfos)
	{
		var expr = true;

		// Having problem with java compilation for Lambda, using a simpler version:
		for (a in values)
		{
			if (!value.exists(function(v) { return v == a; } ))
			{
				expr = false;
				break;
			}
		}

		test(expr, p,
			'Expected ${quote(value)} to contain all of ${quote(values)}',
			'Expected ${quote(value)} not to contain all of ${quote(values)}'
		);
	}

	/**
	 * Test if iterable contains exactly the following values and in the same iteration order.
	 */
	public function containExactly(values : Iterable<T>, ?p : PosInfos)
	{
		var a = value.iterator();
		var b = values.iterator();
		var expr = true;

		while (a.hasNext() || b.hasNext())
		{
			if (a.next() != b.next())
			{
				expr = false;
				break;
			}
		}

		test(expr, p,
			'Expected ${quote(value)} to contain exactly ${quote(values)}',
			'Expected ${quote(value)} not to contain exactly ${quote(values)}'
		);
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
	public function throwValue(v : Dynamic, ?p : PosInfos)
	{
		var expr = false;
		try { value(); }
		catch (e : Dynamic)
		{
			expr = e == v;
		}

		test(expr, p,
			'Expected ${quote(value)} to throw ${quote(v)}',
			'Expected ${quote(value)} not to throw ${quote(v)}'
		);
	}

	/**
	 * Will call the specified method and test if it throws a specific type.
	 */
	public function throwType(type : Class<Dynamic>, ?p : PosInfos)
	{
		var expr = false;
		var name : String = null;

		try { value(); }
		catch (e : Dynamic)
		{
			name = Type.getClassName(type);
			expr = Std.is(e, type);
		}

		test(expr, p,
			'Expected ${quote(value)} to throw type $name',
			'Expected ${quote(value)} not to throw type $name'
		);
	}

	/**
	 * Test for equality between two value types (bool, int, float), or identity for reference types
	 */
	public function be(expected : Void -> Void, ?p : PosInfos) : Void
	{
		test(value == expected, p,
			'Expected ${quote(expected)}, was ${quote(value)}',
			'Didn\'t expect ${quote(expected)} but was equal to that'
		);
	}

	private function quote(v : Dynamic)
	{
		return Std.is(v, String) ? '"$v"' : Std.string(v);
	}

	private function posInfo(p : PosInfos)
	{
		return ' @ ${p.fileName}:${p.lineNumber}';
	}

	private function test(expr : Bool, p : PosInfos, error : String, errorInverted : String)
	{
		if(!inverse)
			assert(expr, error + posInfo(p));
		else
			assert(!expr, error + posInfo(p));
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
	public function be(expected : T, ?p : PosInfos) : Void
	{
		test(value == expected, p,
			'Expected ${quote(expected)}, was ${quote(value)}',
			'Didn\'t expect ${quote(expected)} but was equal to that'
		);
	}

	private function quote(v : Dynamic)
	{
		return Std.is(v, String) ? '"$v"' : Std.string(v);
	}

	private function posInfo(p : PosInfos)
	{
		return ' @ ${p.fileName}:${p.lineNumber}';
	}

	private function test(expr : Bool, p : PosInfos, error : String, errorInverted : String)
	{
		if(!inverse)
			assert(expr, error + posInfo(p));
		else
			assert(!expr, errorInverted + posInfo(p));
	}
}
