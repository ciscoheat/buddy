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
						var change = macro $a.should();
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

			/////

			case macro @include describe($s, function() $f), macro @include describe($s, $f):
				var change = macro describeInclude($s, function() $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro describe($s, function() $f), macro describe($s, $f):
				var change = macro describe($s, function() $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro xdescribe($s, function() $f), macro xdescribe($s, $f), macro @exclude describe($s, function() $f), macro @exclude describe($s, $f):
				var change = macro xdescribe($s, function() $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			/////

			case macro before(function($n) $f):
				var change = macro before(function($n, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro before(function() $f), macro before($f):
				var change = macro syncBefore(function(__asyncDone, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			/////

			case macro after(function($n) $f):
				var change = macro after(function($n, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro after(function() $f), macro after($f):
				var change = macro syncAfter(function(__asyncDone, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			/////

			case macro @include it($s, function($n) $f):
				var change = macro itInclude($s, function($n, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro it($s, function($n) $f):
				var change = macro it($s, function($n, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			/////

			case macro @include it($s, function() $f), macro @include it($s, $f):
				var change = macro syncItInclude($s, function(__asyncDone, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro it($s, function() $f), macro it($s, $f):
				var change = macro syncIt($s, function(__asyncDone, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			/////

			case macro xit($s, function($n) $f):
				var change = macro xit($s, function($n, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro xit($s, function() $f), macro xit($s, $f), macro @exclude it($s, function() $f), macro @exclude it($s, $f):
				var change = macro syncXit($s, function(__asyncDone, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			/////

			case macro fail():
				var change = macro failSync(__status);
				e.expr = change.expr;

			case macro fail($s):
				var change = macro failSync(__status, $s);
				e.expr = change.expr;

			case macro fail:
				var change = macro function(d) { failSync(__status, d); };
				e.expr = change.expr;

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
							for (e in exprs)
							{
								switch(e)
								{
									// Replace before/after outside describe with corresponding init functions.

									case macro before(function($n) $f):
										var change = macro beforeDescribe(function($n, __status) $f);
										e.expr = change.expr;

									case macro before(function() $f), macro before($f):
										var change = macro syncBeforeDescribe(function(__asyncDone, __status) $f);
										e.expr = change.expr;

									case macro after(function($n) $f):
										var change = macro afterDescribe(function($n, __status) $f);
										e.expr = change.expr;

									case macro after(function() $f), macro after($f):
										var change = macro syncAfterDescribe(function(__asyncDone, __status) $f);
										e.expr = change.expr;

									// Test if a super call exists.

									case macro super():
										exists = true;

									case _:
								}
							}

							if(!exists)
								exprs.unshift(macro super());

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
