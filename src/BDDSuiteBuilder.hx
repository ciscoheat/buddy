package ;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;
using Lambda;
using haxe.macro.ExprTools;

//@:autoBuild(BDDSuiteBuilder.build()) interface BDDSuite { }

class BDDSuiteBuilder
{
	private static function injectAsync(e : Expr)
	{
		switch(e)
		{
			case macro describe($s, function() $f):
				f.iter(injectAsync);

			case macro describe($s, $f):
				var change = macro describe($s, function() $f);
				e.expr = change.expr;
				f.iter(injectAsync);

			/////

			case macro before(function() $f):
				var change = macro syncBefore(function(__asyncDone) $f);
				e.expr = change.expr;

			case macro before($f):
				var change = macro syncBefore(function(__asyncDone) $f);
				e.expr = change.expr;

			/////

			case macro after(function() $f):
				var change = macro syncAfter(function(__asyncDone) $f);
				e.expr = change.expr;

			case macro after($f):
				var change = macro syncAfter(function(__asyncDone) $f);
				e.expr = change.expr;

			/////

			case macro it($s, function() $f):
				var change = macro syncIt($s, function(__asyncDone) $f);
				e.expr = change.expr;

			case macro it($s, $f):
				var change = macro syncIt($s, function(__asyncDone) $f);
				e.expr = change.expr;

			/////

			case macro xit($s, function() $f):
				var change = macro syncXit($s, function(__asyncDone) $f);
				e.expr = change.expr;

			case macro xit($s, $f):
				var change = macro syncXit($s, function(__asyncDone) $f);
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