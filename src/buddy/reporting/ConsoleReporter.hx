package buddy.reporting ;

import buddy.BuddySuite;
import buddy.reporting.Reporter;
import haxe.CallStack;
import promhx.Deferred;
import promhx.Promise;
using Lambda;

#if nodejs
import buddy.internal.sys.NodeJs;
typedef Sys = NodeJs;
#elseif js
import buddy.internal.sys.Js;
typedef Sys = Js;
#elseif flash
import buddy.internal.sys.Flash;
typedef Sys = Flash;
#end

class ConsoleReporter implements Reporter
{
	#if php
	var cli : Bool;
	#end

	public function new() {}

	public function start()
	{
		#if php
		cli = (untyped __call__("php_sapi_name")) == 'cli';
		if(!cli) Sys.println("<pre>");
		#end

		return resolveImmediately(true);
	}

	public function progress(spec : Spec)
	{
		Sys.print(switch(spec.status) {
			case TestStatus.Failed: "X";
			case TestStatus.Passed: ".";
			case TestStatus.Pending: "P";
			case TestStatus.Unknown: "?";
		});

		return resolveImmediately(spec);
	}

	public function done(suites : Iterable<Suite>)
	{
		Sys.println("");

		var total = 0;
		var failures = 0;
		var pending = 0;
		for (s in suites)
		{
			for (sp in s.specs)
			{
				total++;
				if (sp.status == TestStatus.Failed) failures++;
				else if (sp.status == TestStatus.Pending) pending++;
			}
		}

		for (s in suites)
		{
			Sys.println(s.name);
			for (sp in s.specs)
			{
				if (sp.status == TestStatus.Failed)
				{
					Sys.println("  " + sp.description + " (FAILED: " + sp.error + ")");

					if (sp.stack == null || sp.stack.length == 0) continue;

					// Display the exception stack
					for (s in sp.stack) switch s {
						case FilePos(_, file, line) if (file.indexOf("buddy/internal/") != 0):
							Sys.println('    @ $file:$line');
						case _:
					}
				}
				else
					Sys.println("  " + sp.description + " (" + sp.status + ")");
			}
		}

		Sys.println('$total specs, $failures failures, $pending pending');

		#if php
		if(!cli) Sys.println("</pre>");
		#end

		return resolveImmediately(suites);
	}

	private function resolveImmediately<T>(o : T) : Promise<T>
	{
		var def = new Deferred<T>();
		var pr = def.promise();
		def.resolve(o);
		return pr;
	}
}

