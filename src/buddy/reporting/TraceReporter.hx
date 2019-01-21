package buddy.reporting;

import haxe.CallStack.StackItem;
import promhx.Deferred;
import promhx.Promise;

import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.BuddySuite.SpecStatus;

using Lambda;
using StringTools;

@:enum abstract Color(Int) {
	var Default = 39;
	var Red = 31;
	var Yellow = 33;
	var Green = 32;
	var White = 37;

	@:to public function ansiCode() : String return String.fromCharCode(27) + '[${this}m';
}

class TraceReporter implements Reporter
{
	var colors : Bool;

	public function new(colors = false) {
		this.colors = colors;
	}

	public function start()	{
		return resolveImmediately(true);
	}

	public function progress(spec:Spec)	{
		// No progress is shown, it would generate too much noise.
		return resolveImmediately(spec);
	}

	public function done(suites : Iterable<Suite>, status : Bool) {
		#if (js && !nodejs && !travix)
		// Skip newline, already printed in console.log()
		#else
		println("");
		#end

		var total = 0;
		var failures = 0;
		var pending = 0;

		var countTests : Suite -> Void = null;
		var printTests : Suite -> Int -> { success : Bool, lines : Array<String> } = null;

		countTests = function(s : Suite) {
			if (s.error != null) failures++; // Count a crashed BuddySuite as a failure?

			for (sp in s.steps) switch sp {
				case TSpec(sp):
					total++;
					if (sp.status == Failed) failures++;
					else if (sp.status == Pending) pending++;
				case TSuite(s):
					countTests(s);
			}
		};

		suites.iter(countTests);

		printTests = function(s : Suite, indentLevel : Int) {
			var success = true;
			var lines = [];

			function print(str : String, color : Color = Default) {
				var start = strCol(color), end = strCol(Default);
				lines.push(start + str.lpad(" ", str.length + Std.int(Math.max(0, indentLevel * 2))) + end);
			}

			function printStack(indent : String, stack : Array<StackItem>) {
				if (stack == null || stack.length == 0) return;
				for (s in stack) switch s {
					case FilePos(_, file, line) if (line > 0 && file.indexOf("buddy/internal/") != 0 && file.indexOf("buddy.SuitesRunner") != 0):
						print(indent + '@ $file:$line', Yellow);
					case _:
				}
			}

			function printTraces(spec : Spec) {
				for (t in spec.traces) print("    " + t, Yellow);
			}

			if (s.description.length > 0) print(s.description);

			if (s.error != null) {
				// The whole suite crashed.
				print("ERROR: " + s.error, Red);
				printStack('  ', s.stack);
				return { success: false, lines: lines };
			}

			for (step in s.steps) switch step {
				case TSpec(sp):
					success = success && sp.status == Passed;

					if (sp.status == Failed) {
						print("  " + sp.description + " (FAILED)", Red);
						printTraces(sp);

						for(failure in sp.failures) {
							print("    " + failure.error, Yellow);
							printStack('      ', failure.stack);
						}
					}
					else {
						print("  " + sp.description + " (" + sp.status + ")", sp.status == Passed ? Green : Yellow);
						printTraces(sp);
					}

				case TSuite(s):
					var ret = printTests(s, indentLevel + 1);
					success = success && ret.success;
					lines = lines.concat(ret.lines);
			}

			return { 
				success: success, 
				lines: #if buddy_ignore_passing_specs !success ? lines : [] #else lines #end 
			};
		};

		suites.iter(function (s) {
			var ret = printTests(s, -1);
			ret.lines.iter(println);
		});

		var totalColor = if (failures > 0) Red else Green;
		var pendingColor = if (pending > 0) Yellow else totalColor;

		println(
			strCol(totalColor) + '$total specs, $failures failures, ' +
			strCol(pendingColor) + '$pending pending' +
			strCol(Default)
		);

		return resolveImmediately(suites);
	}

	private function print(s : String) {
		// Override when needed.
	}

	private function println(s : String) {
		// Override when needed.
		#if flash
		flash.Lib.trace(s);
		#elseif (js && !nodejs)
		js.Browser.document.writeln(s);
		#else
		trace(s);
		#end
	}

	private function strCol(color : Color) return this.colors ? color.ansiCode() : "";

	/**
	 * Convenience method.
	 */
	private function resolveImmediately<T>(o : T) : Promise<T> {
		var def = new Deferred<T>();
		var pr = def.promise();
		def.resolve(o);
		return pr;
	}
}
