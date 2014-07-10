package buddy.tools ;
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
	public static function run(onClass : ClassType, includePackages : Array<String>, includePaths : Array<String>, allowed : Array<ClassType> -> Array<ClassType>, metaName = "autoIncluded")
	{
		if (includePackages == null || includePackages.length == 0) includePackages = [""];
		if (includePaths == null || includePaths.length == 0)
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
			includePaths = Context.getClassPath().filter(function(p) {
				p = p.replace("\\", "/");
				return !excludePaths.exists(function(p2) return p.indexOf(p2) >= 0);
			});
		}

		Context.onGenerate(getClasses.bind(_, onClass, allowed, metaName));

		for (pack in includePackages)
			Compiler.include(pack, true, [], includePaths);
	}

	private static function getClasses(types : Array<Type>, onClass : ClassType, allowed : Array<ClassType> -> Array<ClassType>, metaName : String) : Void
	{
		var classTypes = new Array<ClassType>();
		for (t in types) switch t {
			case TInst(t, params): classTypes.push(t.get());
			case _:
		}

		var classes = allowed(classTypes);

		// Add :keep metadata to prevent dead code elimination
		for (c in classes)
			c.meta.add(":keep", [], c.pos);

		//classes.push(toTypeStringExpr(t.get()));
		onClass.meta.add(metaName, classes.map(function(c) return toTypeStringExpr(c)), onClass.pos);
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