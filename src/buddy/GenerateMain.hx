package buddy ;

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
	macro public static function build( ?packages:Array<String> ) : Array<Field>
	{
		var cls = Context.getLocalClass().get();
		var fields = Context.getBuildFields();
		var found = false;

		AutoIncluder.run(cls, packages, typeIsSuite);

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

	private static function typeIsSuite(classes : Array<ClassType>) : Array<ClassType>
	{
		var output = new Array<ClassType>();
		var include = new Array<ClassType>();

		for (c in classes)
		{
			if (c.meta.has(BuddySuite.exclude)) continue;
			if (c.superClass != null && c.superClass.t.get().name == "BuddySuite")
			{
				if (c.meta.has(BuddySuite.include)) include.push(c);
				else output.push(c);
			}
		}

		return include.length > 0 ? include : output;
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

				// Windows bug doesn't flush stdout properly, need to wait: https://github.com/joyent/node/issues/3584
				runner.run().then(function(_) { untyped __js__("if(process.platform == 'win32') { process.once('exit', function() { process.exit(runner.statusCode()); }); } else { process.exit(runner.statusCode()); }"); } );
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
