package buddy.internal ;

#if macro
import buddy.reporting.ConsoleReporter;
import buddy.SuitesRunner;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.rtti.Meta;
import Type in HaxeType;

using haxe.macro.ExprTools;
using Lambda;
#end

class GenerateMain
{
	// Will be set in SuitesRunner
	public static var testsRunning : Bool;

	#if macro
	macro public static function withSuites(?buddySuites : Expr) : Array<Field>
	{
		var cls = Context.getLocalClass().get();
		var fields = Context.getBuildFields();
		
		function error() Context.error("Buddy must use an array of type paths as parameter.", cls.pos);		
		
		if (buddySuites == null || buddySuites.expr.equals(EConst(CIdent("null")))) {
			var buddyInterface = cls.interfaces.find(function(f) return f.t.get().name == 'Buddy');
			if (buddyInterface == null) {
				if (cls.superClass.t != null && cls.superClass.t.get().name == "SingleSuite")
					buddySuites = macro [$p{cls.pack.concat([cls.name])}];
				else
					error();
			} else {
				switch buddyInterface.params[0] {
					case TInst(t, _): switch t.get().kind {
						case KExpr(e): buddySuites = e;
						case _: error();
					}
					case _: error();
				}
			}
		}
			
		var addedSuites = [];

		function addSuite(type) switch type {
			case TInst(t, params):
				var type = t.get();
				if (type.meta.has('exclude')) return;
				
				addedSuites.push({expr: ENew({
					name: type.name,
					pack: type.pack,
					params: []
				}, []), pos: cls.pos});
			case _: error();
		};
		
		switch buddySuites.expr {
			case EArrayDecl(values): for (c in values) switch c.expr {
				case EField(e, field):
					addSuite(Context.getType(e.toString() + '.' + field));
				case EConst(c): switch c {
					case CString(s), CIdent(s):
						addSuite(Context.getType(s));
					case _: error();
				}
				case ENew(t, params):
					addedSuites.push(c);
				case _: error();
			}
			case _: error();
		}

		buildMain(currentMain(fields), cls, reporter(), { expr: EArrayDecl(addedSuites), pos: cls.pos });

		return fields;
	}

	private static function currentMain(fields : Array<Field>) : Array<Expr>
	{
		for (f in fields)
		{
			if (f.name == "main" && f.access.exists(function(a) { return a == Access.AStatic; } ))
			{
				switch(f.kind)
				{
					case FFun(f2):
						switch(f2.expr.expr)
						{
							case EBlock(exprs): return exprs;
							case _:
						}
					case _:
				}
			}
		}

		var exprs = new Array<Expr>();

		var func = {
			ret: null,
			params: [],
			expr: {pos: Context.currentPos(), expr: EBlock(exprs)},
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
		return exprs;
	}

	private static function reporter() : String
	{
		var cls = Context.getLocalClass().get();
		
		var colors = ["buddy-colors", "buddy_colors"].exists(Context.defined) || 
			["buddy-colors", "buddy_colors", "colors", "color", "colorize"].exists(cls.meta.has);

		if (["buddy-no-colors", "buddy_no_colors"].exists(Context.defined))
			colors = false;

		// Set default reporter
		var reporter = if (flashCI()) {
			"buddy.reporting.TraceReporter";
		} else {
			colors ? "buddy.reporting.ConsoleColorReporter" : "buddy.reporting.ConsoleReporter";
		}

		if (Context.defined("reporter"))
		{
			reporter = Context.definedValue("reporter");
		}
		else if (cls.meta.has("reporter"))
		{
			reporter = cls.meta.get().find(function(m) return m.name == "reporter").params[0].getValue();
		}

		return reporter;
	}

	private static function typeIsSuite(classes : Array<ClassType>) : Array<ClassType>
	{
		var output = new Array<ClassType>();
		var include = new Array<ClassType>();

		for (c in classes) {
			if (c.meta.has("exclude")) continue;
			if (c.superClass != null && c.superClass.t.get().name == "BuddySuite")
			{
				if (c.meta.has("include")) include.push(c);
				else output.push(c);
			}
		}

		return include.length > 0 ? include : output;
	}
	
	private static function flashCI() 
		return Context.defined("fdb-ci") || Context.defined("exit-flash") || Context.defined("flash-exit");

	private static function buildMain(exprs : Array<Expr>, cls : ClassType, reporter : String, ?allSuites : ExprOf<Array<BuddySuite>>) {
		if (allSuites == null) Context.error("No BuddySuites found.", cls.pos);
		
		function toTypeStringExpr(type : ClassType) : Expr {
			return {expr: EConst(CString(type.pack.concat([type.name]).join("."))), pos: Context.currentPos()};
		}
		
		var e = toTypeStringExpr(cls);
		var body : Expr;

		var pack = reporter.split(".");
		var type = pack.pop();

		var rep = {
			sub: null,
			params: null,
			pack: pack,
			name: type
		}
		
		var header = macro {
			var testsDone : Bool = false; // For platforms without event loop
			var runner : buddy.SuitesRunner = null;
			var oldTrace = haxe.Log.trace;
			
			function outputError() {
				haxe.Log.trace = oldTrace; // Restore original trace
				trace(runner.unrecoverableError);

				var stack = runner.unrecoverableErrorStack;
				if (stack == null || stack.length == 0) return;
				
				for (s in stack) switch s {
					case FilePos(_, file, line) if(line > 0): trace(file+":"+line);
					case _:
				}
			}
			
			function startRun(done : Void -> Void) : Void {				
				runner = new buddy.SuitesRunner($allSuites, new $rep());
				runner.run().then(function(_) {
					if (runner.unrecoverableError != null) outputError();
					done();
				});
			}				
		};

		// Targets that requires a waiting loop
		if (Context.defined("neko") || Context.defined("cpp") || Context.defined("python"))
		{
			body = macro {
				startRun(function() testsDone = true);
				while (!testsDone) Sys.sleep(0.1);
				Sys.exit(runner.statusCode());
			};
		}
		else if(Context.defined("cs"))
		{
			body = macro {
				startRun(function() testsDone = true);
				while (!testsDone) cs.system.threading.Thread.Sleep(10);
				cs.system.Environment.Exit(runner.statusCode());
			};
		}
		else if(Context.defined("nodejs"))
		{
			body = macro {
				untyped __js__("process.on('uncaughtException', function(err) {");
				runner.haveUnrecoverableError(untyped err);
				untyped __js__("})");
				startRun(function() untyped __js__("process.exit(runner.statusCode())"));
			};
		}
		else if(Context.defined("sys"))
		{
			body = macro {
				startRun(function() Sys.exit(runner.statusCode()));
			};
		}
		else if (flashCI())
		{
			body = macro {
				startRun(function() flash.system.System.exit(runner.statusCode()));
			}
		}
		else if(Context.defined('js') && Context.defined('travix') && !Context.defined('nodejs'))
		{
			body = macro {
				startRun(function() {
					var callPhantom = untyped js.Browser.window.callPhantom;
					callPhantom({
						cmd: 'travix:exit',
						exitCode: runner.statusCode()
					});
				});
			}
		}
		else
		{
			body = macro {
				startRun(function() {});
			};
		}

		// Merge the blocks
		for(block in [header, body]) switch block.expr {
			case EBlock(exprs2):
				for (e in exprs2) exprs.push(e);
			case _:
				throw "header or body isn't a block expression.";
		}
	}
	#end
}
