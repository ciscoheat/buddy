package buddy.internal ;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;
using haxe.macro.ExprTools;

class SuiteBuilder
{
	private static function injectAsync(e : Expr)
	{
		switch(e.expr)
		{
			// Fix autocomplete for should without parenthesis
			case EDisplay(e2, isCall):
				switch(e2.expr)
				{
					case EField(e3, f3) if(f3 == "should"):
						e2.expr = ECall({ expr: e2.expr, pos: e2.pos }, []);
					case _:
				}
			case _:
		}

		switch(e)
		{
			case macro $a.should().$b, macro $a.should.$b:
				var change = macro $a.should(__status).$b;
				e.expr = change.expr;

			/////

			case macro describe($s, function() $f), macro describe($s, $f):
				var change = macro describe($s, function() $f);
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

			case macro it($s, function($n) $f):
				var change = macro it($s, function($n, __status) $f);
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

			case macro xit($s, function() $f), macro xit($s, $f):
				var change = macro syncXit($s, function(__asyncDone, __status) $f);
				e.expr = change.expr;
				f.iter(injectAsync);

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
					f.expr.iter(injectAsync);
					switch(f.expr.expr)
					{
						case EBlock(exprs):
							for (e in exprs)
							{
								switch(e)
								{
									case macro super():
										exists = true;
										break;
									case _:
								}
							}

							if(!exists)
								exprs.unshift(macro super());

						case _:
					}

				case _:
			}
		}

		return fields;
	}
}