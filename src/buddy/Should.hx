package buddy;
import buddy.Should.ShouldIterable;
import haxe.PosInfos;
import haxe.CallStack;
import haxe.Int64;
#if python
import python.internal.UBuiltins;
import python.lib.Builtins;
#end

#if (haxe_ver >= 4.1)
import Std.isOfType;
#else
import Std.is as isOfType;
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
@:keep class ShouldDynamic extends Should<Dynamic>
{
	static public function should(d : Dynamic)
	{
		return new ShouldDynamic(d);
	}

	public var not(get, never) : ShouldDynamic;
	private function get_not() { return new ShouldDynamic(value, !inverse); }
}

@:keep class ShouldEnum extends Should<EnumValue>
{
	static public function should(e : EnumValue)
	{
		return new ShouldEnum(e);
	}

	public function new(value : EnumValue, inverse = false)
	{
		super(value, inverse);
	}

	public var not(get, never) : ShouldEnum;
	private function get_not() { return new ShouldEnum(value, !inverse); }

	//////////

	@:deprecated("Use should.equal instead for enum comparisons")
	override public function be(expected : EnumValue, ?p : PosInfos) : Void {
		equal(expected, p);
	}

	public function equal(expected : EnumValue, ?p : PosInfos)
	{
		test(Type.enumEq(value, expected), p,
			'Expected ${quote(expected)}, was ${quote(value)}',
			'Didn\'t expect ${quote(value)} but was equal to that'
		);
	}
}

@:keep class ShouldInt extends Should<Null<Int>>
{
	static public function should(i : Null<Int>)
	{
		return new ShouldInt(i);
	}

	public function new(value : Null<Int>, inverse = false)
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

	public function beLessThanOrEqualTo(expected : Int, ?p : PosInfos)
	{
		test(value <= expected, p,
			'Expected less than or equal to ${quote(expected)}, was ${quote(value)}',
			'Expected not less than or equal to ${quote(expected)}, was ${quote(value)}'
		);
	}

	public function beGreaterThan(expected : Int, ?p : PosInfos)
	{
		test(value > expected, p,
			'Expected greater than ${quote(expected)}, was ${quote(value)}',
			'Expected not greater than ${quote(expected)}, was ${quote(value)}'
		);
	}

	public function beGreaterThanOrEqualTo(expected : Int, ?p : PosInfos)
	{
		test(value >= expected, p,
			'Expected greater than or equal to ${quote(expected)}, was ${quote(value)}',
			'Expected not greater than or equal to ${quote(expected)}, was ${quote(value)}'
		);
	}
}

@:keep class ShouldInt64 extends Should<Int64>
{
	static public function should(i : Int64)
	{
		return new ShouldInt64(i);
	}

	public function new(value : Int64, inverse = false)
	{
		super(value, inverse);
	}

	public var not(get, never) : ShouldInt64;
	private function get_not() { return new ShouldInt64(value, !inverse); }

	//////////

	public override function be(expected : Int64, ?p : PosInfos) : Void
	{
		var result = Int64.compare(expected, value) == 0;
		test(result, p,
			'Expected ${quote(expected)}, was ${quote(value)}',
			'Didn\'t expect ${quote(expected)} but was equal to that'
		);
	}

	public function beLessThan(expected : Int64, ?p : PosInfos)
	{
		test(value < expected, p,
			'Expected less than ${quote(expected)}, was ${quote(value)}',
			'Expected not less than ${quote(expected)}, was ${quote(value)}'
		);
	}

	public function beGreaterThan(expected : Int64, ?p : PosInfos)
	{
		test(value > expected, p,
			'Expected greater than ${quote(expected)}, was ${quote(value)}',
			'Expected not greater than ${quote(expected)}, was ${quote(value)}'
		);
	}
}

@:keep class ShouldFloat extends Should<Null<Float>>
{
	static public function should(i : Null<Float>)
	{
		return new ShouldFloat(i);
	}

	public function new(value : Null<Float>, inverse = false)
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
		// Also, haxe 4 -> C# breaks here when inlining the two vars
		var diff = Math.abs(expected - value);
		var threshold = Math.pow(10, -precision) / 2;
		var expr = diff < threshold;

		test(expr, p,
			'Expected close to ${quote(expected)}, was ${quote(value)}',
			'Expected ${quote(value)} not to be close to ${quote(expected)}'
		);
	}
}

@:keep class ShouldDate extends Should<Date>
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

@:keep class ShouldIterable<T> extends Should<Iterable<T>>
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

@:keep class ShouldString extends Should<String>
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
		if (value == null) return fail(
			'Expected string to contain ${quote(substring)} but string was null',
			'Expected string not to contain ${quote(substring)} but string was null',
			p);

		test(value.indexOf(substring) >= 0, p,
			'Expected ${quote(value)} to contain ${quote(substring)}',
			'Expected ${quote(value)} not to contain ${quote(substring)}'
		);
	}

	public function startWith(substring : String, ?p : PosInfos)
	{
		if (value == null) return fail(
			'Expected string to start with ${quote(substring)} but string was null',
			'Expected string not to start with ${quote(substring)} but string was null',
			p);

		test(value.startsWith(substring), p,
			'Expected ${quote(value)} to start with ${quote(substring)}',
			'Expected ${quote(value)} not to start with ${quote(substring)}'
		);
	}

	public function endWith(substring : String, ?p : PosInfos)
	{
		if (value == null) return fail(
			'Expected string to end with ${quote(substring)} but string was null',
			'Expected string not to end with ${quote(substring)} but string was null',
			p);

		test(value.endsWith(substring), p,
			'Expected ${quote(value)} to end with ${quote(substring)}',
			'Expected ${quote(value)} not to end with ${quote(substring)}'
		);
	}

	public function match(regexp : EReg, ?p : PosInfos)
	{
		if (value == null) return fail(
			'Expected string to match regular expression but string was null',
			'Expected string not to match regular expression but string was null',
			p);

		test(regexp.match(value), p,
			'Expected ${quote(value)} to match regular expression',
			'Expected ${quote(value)} not to match regular expression'
		);
	}
}

// Some problem with C++ forces this class not to be derived from Should<T>
@:keep class ShouldFunctions
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
	 * Will call the specified method and test if it throws anything.
	 */
	public function throwAnything(?p : PosInfos) : Null<Dynamic>
	{
		var caught = false;
		var exception : Dynamic = null;

		try { value(); }
		catch (e : Dynamic) { exception = e; caught = true; };

		test(caught, p,
			'Expected ${quote(value)} to throw anything, nothing was thrown',
			'Expected ${quote(value)} not to throw anything, ${quote(exception)} was thrown'
		);

		return exception;
	}

	/**
	 * Will call the specified method and test if it throws a specific value.
	 */
	public function throwValue<T>(v : T, ?p : PosInfos) : Null<T>
	{
		var exception : Dynamic = null;

		try { value(); }
		catch (e : Dynamic) {
			var cause : Dynamic = null;
			#if java
			// Handles exceptions that sneaks into the runtime,
			// like exceptions thrown in the constructor.
			if(isOfType(e, java.lang.Throwable)) {
				cause = cast(e, java.lang.Throwable).getCause();

				if(cause != null && Type.getClassName(Type.getClass(cause)) == "haxe.lang.HaxeException")
					cause = cause.getObject();
			}
			#end
			exception = cause == null ? e : cause;
		}

		var isCaught = exception == v;		
		test(isCaught, p,
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
		var exception : Dynamic = null;

		try { value(); }
		catch (e : Dynamic) {
			var cause : Dynamic = null;
			#if java
			// Handles exceptions that sneaks into the runtime,
			// like exceptions thrown in the constructor.
			if(isOfType(e, java.lang.Throwable)) {
				cause = cast(e, java.lang.Throwable).getCause();

				if(cause != null && Type.getClassName(Type.getClass(cause)) == "haxe.lang.HaxeException")
					cause = cause.getObject();
			}
			#end
			exception = cause == null ? e : cause;
		}

		var typeName : String = Type.getClassName(type);

		var exceptionName = exception == null ? null : Type.getClassName(Type.getClass(exception));
		if (exceptionName == null) exceptionName = "no exception";

		var isCaught = isOfType(exception, type);
		test(isCaught, p,
			'Expected ${quote(value)} to throw type $typeName, $exceptionName was thrown instead',
			'Expected ${quote(value)} not to throw type $typeName'
		);

		return exception;
	}

	/**
	 * Test for equality between two value types (bool, int, float and string), or identity for reference types
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
		if (isOfType(v, String)) return '"$v"';
		if (isOfType(v, List)) return Std.string(Lambda.array(v));
		return Std.string(v);
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

@:keep class Should<T>
{
	var value : T;
	var inverse : Bool;

	public function new(value : T, inverse = false)
	{
		this.value = value;
		this.inverse = inverse;
	}

	/**
	 * Test for equality between "expected" value types (bool, int, int64, float, string), identity for other (reference) types
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
		test(isOfType(value, type), p,
			'Expected ${quote(value)} to be type ${quote(type)}',
			'Expected ${quote(value)} not to be type ${quote(type)}'
		);
	}

	private function quote(v : Dynamic)
	{
		if (isOfType(v, String)) return '"$v"';
		if (isOfType(v, List)) return Std.string(Lambda.array(v));
		return Std.string(v);
	}

	private function fail(error : String, errorInverted : String, p : PosInfos)
	{
		SuitesRunner.currentTest(false, inverse ? errorInverted : error, SuitesRunner.posInfosToStack(p));
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
