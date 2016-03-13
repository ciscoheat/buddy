package buddy.internal ;
#if macro
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.ExprTools;

class SuiteBuilder
{
	private static function debugDisplay(e : Expr)
	{
		var file = sys.io.File.write("e:\\temp\\buddy.txt", false);
		file.writeString(Std.string(e.expr));
		file.writeString("\r\n\r\n" + e.toString());
		file.close();
	}

	private static function injectAsync(e : Expr)
	{
		switch(e.expr)
		{
			// Fix autocomplete for should without parenthesis
			case EDisplay(e2, isCall):

				switch(e2)
				{
					case macro $a.should:
						var change = macro $a.should(untyped __status);
						e2.expr = change.expr;

					case _:
				}

			case _:
		}
		
		switch(e)
		{
			case macro $a.should().$b, macro $a.should.$b:
				// Need to use untyped here for some unknown macro reason...
				var change = macro $a.should(untyped __status).$b;
				e.expr = change.expr;

			///// Describe

			case macro describe($s, function($n) $f):
				var change = macro describe($s, buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro describe($s, function() $f), macro describe($s, $f):
				var change = macro describe($s, buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro xdescribe($s, function() $f), macro xdescribe($s, $f), macro @exclude describe($s, $f):
				var change = macro xdescribe($s, buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			///// Before/After

			case macro before(function($n) $f), macro beforeEach(function($n) $f):
				var change = macro beforeEach(buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro before(function() $f), macro before($f), macro beforeEach(function() $f), macro beforeEach($f):
				var change = macro beforeEach(buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro after(function($n) $f), macro afterEach(function($n) $f):
				var change = macro afterEach(buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro after(function() $f), macro after($f), macro afterEach(function() $f), macro afterEach($f):
				var change = macro afterEach(buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			///// It

			case macro it($s, function($n) $f):
				var change = macro it($s, buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro it($s, function() $f), macro it($s, $f):
				var change = macro it($s, buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro xit($s, function($n) $f):
				var change = macro xit($s, buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro xit($s, function() $f), macro xit($s, $f), macro @exclude it($s, $f):
				var change = macro xit($s, buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			/////

			case _: e.iter(injectAsync);
		}
	}

	macro public static function build() : Array<Field>
	{
		var exists = false;
		var cls = Context.getLocalClass();
		if (cls == null || cls.get().superClass == null) return null;

		var fields = Context.getBuildFields();
		for (f in fields)
		{
			if (f.name != "new") continue;
			switch(f.kind)
			{
				case FFun(f):
					switch(f.expr.expr)
					{
						case EBlock(exprs):
							for (e in exprs) switch e {
								case macro super():	
									exists = true;
									break;
								case _:
							}

							if(!exists) exprs.unshift(macro super());

						case _:
					}
					f.expr.iter(injectAsync);

				case _:
			}
		}

		return fields;
	}
}
#end
