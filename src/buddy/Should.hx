package buddy;
import buddy.Should.ShouldIterable;
import haxe.PosInfos;
import haxe.CallStack;
#if python
import python.internal.UBuiltins;
import python.lib.Builtins;
#end

using Lambda;
using StringTools;

/**
 * A function that specifies the status for a spec with an optional error message and stack.
 */
typedef SpecAssertion = Bool -> String -> Array<StackItem> -> Void;

/**
 * This must be the first class in this package, since it overrides all other assertions otherwise.
 */
class ShouldDynamic extends Should<Dynamic>
{
	static public function should(d : Dynamic)
	{
		return new ShouldDynamic(d);
	}

	public var not(get, never) : ShouldDynamic;
	private function get_not() { return new ShouldDynamic(value, !inverse); }
}

class ShouldInt extends Should<Int>
{
	static public function should(i : Int)
	{
		return new ShouldInt(i);
	}

	public function new(value : Int, inverse = false)
	{
		super(value, inverse);
	}

	public var not(get, never) : ShouldInt;
	private function get_not() { return new ShouldInt(value, !inverse); }

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
	static public function should(i : Float)
	{
		return new ShouldFloat(i);
	}

	public function new(value : Float, inverse = false)
	{
		super(value, inverse);
	}

	public var not(get, never) : ShouldFloat;
	private function get_not() { return new ShouldFloat(value, !inverse); }

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

	public function beCloseTo(expected : Float, precision : Null<Float> = 2, ?p : PosInfos)
	{
		// For some reason, precision must be of a Nullable type in flash or it will be 0 sometimes?!
		var expr = Math.abs(expected - value) < (Math.pow(10, -precision) / 2);

		test(expr, p,
			'Expected close to ${quote(expected)}, was ${quote(value)}',
			'Expected ${quote(value)} not to be close to ${quote(expected)}'
		);
	}
}

class ShouldDate extends Should<Date>
{
	static public function should(i : Date)
	{
		return new ShouldDate(i);
	}

	public function new(value : Date, inverse = false)
	{
		super(value, inverse);
	}

	public var not(get, never) : ShouldDate;
	private function get_not() { return new ShouldDate(value, !inverse); }

	//////////

	public function beOn(expected : Date, ?p : PosInfos)
	{
		test(value.getTime() == expected.getTime(), p,
			'Expected date equal to ${quote(expected)}, was ${quote(value)}',
			'Expected date not equal to ${quote(expected)}'
		);
	}

	public function beBefore(expected : Date, ?p : PosInfos)
	{
		test(value.getTime() < expected.getTime(), p,
			'Expected date before ${quote(expected)}, was ${quote(value)}',
			'Expected date not before ${quote(expected)}, was ${quote(value)}'
		);
	}

	public function beAfter(expected : Date, ?p : PosInfos)
	{
		test(value.getTime() > expected.getTime(), p,
			'Expected date after ${quote(expected)}, was ${quote(value)}',
			'Expected date not after ${quote(expected)}, was ${quote(value)}'
		);
	}

	public function beOnStr(expected : String, ?p : PosInfos)
		return beOn(Date.fromString(expected), p);

	public function beBeforeStr(expected : String, ?p : PosInfos)
		return beBefore(Date.fromString(expected), p);
		
	public function beAfterStr(expected : String, ?p : PosInfos)
		return beAfter(Date.fromString(expected), p);
}

class ShouldString extends Should<String>
{
	static public function should(str : String)
	{
		return new ShouldString(str);
	}

	public function new(value : String, inverse = false)
	{
		super(value, inverse);
	}

	public var not(get, never) : ShouldString;
	private function get_not() { return new ShouldString(value, !inverse); }

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
	static public function should<T>(value : Iterable<T>)
	{
		return new ShouldIterable<T>(value);
	}

	public function new(value : Iterable<T>, inverse = false)
	{
		super(value, inverse);
	}

	public var not(get, never) : ShouldIterable<T>;
	private function get_not() { return new ShouldIterable<T>(value, !inverse); }

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
	var inverse : Bool;

	public function new(value : Void -> Void, inverse = false)
	{
		this.value = value;
		this.inverse = inverse;
	}

	public var not(get, never) : ShouldFunctions;
	private function get_not() { return new ShouldFunctions(value, !inverse); }

	static public function should(value : Void -> Void)
	{
		return new ShouldFunctions(value);
	}

	/**
	 * Will call the specified method and test if it throws a specific value.
	 */
	public function throwValue<T>(v : T, ?p : PosInfos) : Null<T>
	{
		var caught = false;
		var exception : T = null;
		
		try { value(); }
		catch (e : Dynamic)
		{
			exception = e;
			caught = e == v;
		}

		test(caught, p,
			'Expected ${quote(value)} to throw ${quote(v)}',
			'Expected ${quote(value)} not to throw ${quote(v)}'
		);
		
		return exception;
	}

	/**
	 * Will call the specified method and test if it throws a specific type.
	 */
	public function throwType<T>(type : Class<T>, ?p : PosInfos) : Null<T>
	{
		var caught = false;
		var name : String = Type.getClassName(type);
		var exceptionName : String = null;
		var exception : T = null;

		try { value(); }
		catch (e : Dynamic)
		{
			exception = e;
			exceptionName = Type.getClassName(Type.getClass(e));
			caught = Std.is(e, type);
		}
		
		if (exceptionName == null) exceptionName = "no exception";

		test(caught, p,
			'Expected ${quote(value)} to throw type $name, $exceptionName was thrown instead',
			'Expected ${quote(value)} not to throw type $name'
		);
		
		return exception;
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

	private function test(expr : Bool, p : PosInfos, error : String, errorInverted : String)
	{
		if (SuitesRunner.currentTest == null) throw "SuitesRunner.currentTest was null";
		
		if(!inverse)
			SuitesRunner.currentTest(expr, error, SuitesRunner.posInfosToStack(p));
		else
			SuitesRunner.currentTest(!expr, errorInverted, SuitesRunner.posInfosToStack(p));
	}
}

//////////

class Should<T>
{
	var value : T;
	var inverse : Bool;

	public function new(value : T, inverse = false)
	{
		this.value = value;
		this.inverse = inverse;
	}

	/**
	 * Test for equality between two value types (bool, int, float), or identity for reference types
	 */
	public function be(expected : T, ?p : PosInfos) : Void
	{
		#if python
		// Python arrays compare arrays (list) by item-by-item equality as default.
		var result = UBuiltins.isinstance(value, UBuiltins.list) && UBuiltins.isinstance(expected, UBuiltins.list)
			? Builtins.id(cast value) == Builtins.id(cast expected)
			: value == expected;
		#else
		var result = value == expected;
		#end
		test(result, p,
			'Expected ${quote(expected)}, was ${quote(value)}',
			'Didn\'t expect ${quote(expected)} but was equal to that'
		);
	}

	public function beType(type : Dynamic, ?p : PosInfos)
	{
		test(Std.is(value, type), p,
			'Expected ${quote(value)} to be type ${quote(type)}',
			'Expected ${quote(value)} not to be type ${quote(type)}'
		);
	}
	
	private function quote(v : Dynamic)
	{
		return Std.is(v, String) ? '"$v"' : Std.string(v);
	}

	private function test(expr : Bool, p : PosInfos, error : String, errorInverted : String)
	{
		if (SuitesRunner.currentTest == null) throw "SuitesRunner.currentTest was null";
		
		if(!inverse)
			SuitesRunner.currentTest(expr, error, SuitesRunner.posInfosToStack(p));
		else
			SuitesRunner.currentTest(!expr, errorInverted, SuitesRunner.posInfosToStack(p));
	}
}
