package ;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.ExprTools;
using Lambda;
using StringTools;

class AutoIncluder
{
	#if macro
	public static function run(onClass : ClassType, allowed : ClassType -> Bool, metaName = "autoIncluded")
	{
		var haxePath = Sys.executablePath().replace("\\", "/");
		var paths = [for (p in Context.getClassPath()) if (p.replace("\\", "/").indexOf(haxePath) < 0) p];

		Context.onGenerate(function(types : Array<Type>) {
			getClasses(types, onClass, allowed, metaName);
		});

		Compiler.include("", true, [], paths);
	}

	private static function getClasses(types : Array<Type>, onClass : ClassType, allowed : ClassType -> Bool, metaName : String) : Void
	{
		var classes = new Array<Expr>();

		for (a in types)
		{
			switch(a)
			{
				case TInst(t, params) if(allowed(t.get())):
					classes.push(toTypeIdentifier(t.get()));

				case _:
			}
		}

		onClass.meta.add(metaName, classes, onClass.pos);
	}
	#end

	public static function toTypeString(type : ClassType) : String
	{
		if (type.pack.length > 0)
			return type.pack.join(".") + "." + type.name;

		return type.name;
	}

	public static function toTypeIdentifier(type : ClassType) : Expr
	{
		return macro $v{toTypeString(type)};
	}
}