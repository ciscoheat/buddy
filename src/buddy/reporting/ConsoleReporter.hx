package buddy.reporting ;

import buddy.BuddySuite;
import buddy.reporting.Reporter;
import haxe.CallStack;
import promhx.Deferred;
import promhx.Promise;
using Lambda;
using StringTools;

#if nodejs
import buddy.internal.sys.NodeJs;
private typedef Sys = NodeJs;
#elseif js
import buddy.internal.sys.Js;
private typedef Sys = Js;
#elseif flash
import buddy.internal.sys.Flash;
private typedef Sys = Flash;
#end

class ConsoleReporter implements Reporter
{
	#if php
	var cli : Bool;
	#end

	public function new() {}

	public function start()
	{
		// A small convenience for PHP, to avoid creating a new reporter.
		#if php
		cli = (untyped __call__("php_sapi_name")) == 'cli';
		if(!cli) println("<pre>");
		#end

		return resolveImmediately(true);
	}

	public function progress(spec : Spec)
	{
		print(switch(spec.status) {
			case TestStatus.Failed: "X";
			case TestStatus.Passed: ".";
			case TestStatus.Pending: "P";
			case TestStatus.Unknown: "?";
		});

		return resolveImmediately(spec);
	}

	public function done(suites : Iterable<Suite>, status : Bool)
	{
		println("");

		var total = 0;
		var failures = 0;
		var pending = 0;

		var countTests : Suite -> Void = null;
		var printTests : Suite -> Int -> Void = null;

		countTests = function(s : Suite) {
			for (sp in s.steps) switch sp {
				case TSpec(sp):
					total++;
					if (sp.status == TestStatus.Failed) failures++;
					else if (sp.status == TestStatus.Pending) pending++;
				case TSuite(s):
					countTests(s);
			}
		};

		suites.iter(countTests);

		printTests = function(s : Suite, indentLevel : Int)
		{
			var print = function(str : String) println(str.lpad(" ", str.length + indentLevel * 2));

			print(s.name);
			for (step in s.steps) switch step
			{
				case TSpec(sp):
					if (sp.status == TestStatus.Failed)
					{
						print("  " + sp.description + " (FAILED: " + sp.error + ")");

						printTraces(sp);

						if (sp.stack == null || sp.stack.length == 0) continue;

						// Display the exception stack
						for (s in sp.stack) switch s {
							case FilePos(_, file, line) if (file.indexOf("buddy/internal/") != 0):
								print('    @ $file:$line');
							case _:
						}
					}
					else
					{
						print("  " + sp.description + " (" + sp.status + ")");
						printTraces(sp);
					}
				case TSuite(s):
					printTests(s, indentLevel+1);
			}
		};

		suites.iter(printTests.bind(_, 0));

		println('$total specs, $failures failures, $pending pending');

		#if php
		if(!cli) println("</pre>");
		#end

		return resolveImmediately(suites);
	}

	function printTraces(spec : Spec)
	{
		for (t in spec.traces)
			println("    " + t);
	}

	private function print(s : String)
	{
		Sys.print(s);
	}

	private function println(s : String)
	{
		Sys.println(s);
	}

	private function resolveImmediately<T>(o : T) : Promise<T>
	{
		var def = new Deferred<T>();
		var pr = def.promise();
		def.resolve(o);
		return pr;
	}
}
