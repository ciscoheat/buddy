package buddy.internal;

#if macro
import buddy.reporting.ConsoleReporter;
import buddy.SuitesRunner;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.rtti.Meta;
using haxe.macro.ExprTools;
import buddy.tools.AutoIncluder;
using Lambda;

class GenerateMain
{
	macro public static function build() : Array<Field>
	{
		var cls = Context.getLocalClass().get();
		var fields = Context.getBuildFields();
		var found = false;

		AutoIncluder.run(cls, typeIsSuite);

		for (f in fields)
		{
			if (f.name == "main" && f.access.exists(function(a) { return a == Access.AStatic; } ))
			{
				switch(f.kind)
				{
					case FFun(f2):
						switch(f2.expr.expr)
						{
							case EBlock(exprs):
								found = true;
								buildMain(exprs, cls);
							case _:
						}
					case _:
				}
			}
		}

		if (!found)
		{
			var body = macro {};
			switch(body.expr)
			{
				case EBlock(exprs):
					buildMain(exprs, cls);
				case _:
			}

			var func = {
				ret: null,
				params: [],
				expr: body,
				args: []
			};

			var main = {
				pos: Context.currentPos(),
				name: "main",
				meta: [],
				kind: FFun(func),
				doc: null,
				access: [Access.AStatic, Access.APublic]
			};

			fields.push(main);
		}

		return fields;
	}

	private static function typeIsSuite(type : ClassType) : Bool
	{
		var superClass = type.superClass;
		return superClass != null && superClass.t.get().name == "BuddySuite";
	}

	private static function buildMain(exprs : Array<Expr>, cls : ClassType)
	{
		var e = AutoIncluder.toTypeStringExpr(cls);
		var body : Expr;

		if (Context.defined("neko") || Context.defined("cpp"))
		{
			body = macro {
				var reporter = new buddy.reporting.ConsoleReporter();
				var suites = [];
				for (a in haxe.rtti.Meta.getType(Type.resolveClass($e)).autoIncluded) {
					suites.push(Type.createInstance(Type.resolveClass(a), []));
				}

				var testsRunning = true;
				var runner = new buddy.SuitesRunner(suites, reporter);

				runner.run().then(function(_) { testsRunning = false; } );
				while (testsRunning) Sys.sleep(0.1);
				Sys.exit(runner.statusCode());
			};
		}
		else if(Context.defined("cs"))
		{
			body = macro {
				var reporter = new buddy.reporting.ConsoleReporter();
				var suites = [];
				for (a in haxe.rtti.Meta.getType(Type.resolveClass($e)).autoIncluded) {
					suites.push(Type.createInstance(Type.resolveClass(a), []));
				}

				var testsRunning = true;
				var runner = new buddy.SuitesRunner(suites, reporter);

				runner.run().then(function(_) { testsRunning = false; } );
				while (testsRunning) cs.system.threading.Thread.Sleep(10);
				cs.system.Environment.Exit(runner.statusCode());
			};
		}
		else if(Context.defined("nodejs"))
		{
			body = macro {
				var reporter = new buddy.reporting.ConsoleReporter();
				var suites = [];
				for (a in haxe.rtti.Meta.getType(Type.resolveClass($e)).autoIncluded) {
					suites.push(Type.createInstance(Type.resolveClass(a), []));
				}

				var runner = new buddy.SuitesRunner(suites, reporter);
				runner.run().then(function(_) { untyped __js__("process.exit(runner.statusCode())"); } );
			};
		}
		else if(Context.defined("php") || Context.defined("java"))
		{
			body = macro {
				var reporter = new buddy.reporting.ConsoleReporter();
				var suites = [];
				for (a in haxe.rtti.Meta.getType(Type.resolveClass($e)).autoIncluded) {
					suites.push(Type.createInstance(Type.resolveClass(a), []));
				}

				var runner = new buddy.SuitesRunner(suites, reporter);
				runner.run().then(function(_) { Sys.exit(runner.statusCode()); });
			};
		}
		else
		{
			body = macro {
				var reporter = new buddy.reporting.ConsoleReporter();
				var suites = [];
				for (a in haxe.rtti.Meta.getType(Type.resolveClass($e)).autoIncluded) {
					suites.push(Type.createInstance(Type.resolveClass(a), []));
				}

				new buddy.SuitesRunner(suites, reporter).run();
			};
		}

		exprs.push(body);
	}
}
#end
