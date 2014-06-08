package buddy.tools ;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;
import sys.io.Process;

using haxe.macro.ExprTools;
using Lambda;
using StringTools;

class AutoIncluder
{
	#if macro
	public static function run(onClass : ClassType, allowed : ClassType -> Bool, metaName = "autoIncluded")
	{
		var excludePaths = [];

		for (p in Context.getClassPath())
		{
			p = p.replace("\\", "/");

			var i = p.indexOf("/promhx/");
			if (i > 0) excludePaths.push(p.substr(0, i));

			i = p.indexOf("/extraLibs");
			if (i > 0) excludePaths.push(p.substr(0, p.length - "/extraLibs".length));
		}

		//var haxePath = new Process("haxelib", ["config"]).stdout.readAll().toString().replace("\\", "/");
		var paths = Context.getClassPath().filter(function(p) {
			p = p.replace("\\", "/");
			return !excludePaths.exists(function(p2) {
				return p.indexOf(p2) >= 0;
			});
		});

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
					classes.push(toTypeStringExpr(t.get()));

				case _:
			}
		}

		onClass.meta.add(metaName, classes, onClass.pos);
	}

	public static function toTypeString(type : ClassType) : String
	{
		return type.pack.concat([type.name]).join(".");
	}

	public static function toTypeStringExpr(type : ClassType) : Expr
	{
		return {expr: EConst(CString(toTypeString(type))), pos: Context.currentPos()};
	}
	#end
}