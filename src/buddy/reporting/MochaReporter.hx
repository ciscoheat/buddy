package buddy.reporting;

import haxe.Timer;
import promhx.Deferred;
import promhx.Promise;

import buddy.reporting.Reporter;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.BuddySuite.TestStatus;

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


/** A mocha-like reporter (with timings) */
class MochaReporter implements Reporter
{
#if php
	var cli : Bool;
#end

  var startTime:Float;
  var overallProgress:StringBuf;
  
  public var timings:Map<Spec, Float>;
  
	public function new() {}

	public function start()
	{
		// A small convenience for PHP, to avoid creating a new reporter.
  #if php
		cli = (untyped __call__("php_sapi_name")) == 'cli';
		if(!cli) println("<pre>");
  #end

    startTime = Timer.stamp();
    timings = new Map();
    overallProgress = new StringBuf();
    
		return resolveImmediately(true);
	}

	public function progress(spec:Spec)
	{
    var elapsed = Timer.stamp() - startTime;
    elapsed = Std.int(elapsed * 1000) / 1000;
    timings[spec] = elapsed;
    startTime = Timer.stamp();
    
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
  #if js
    println(overallProgress.toString());
  #end
  
    println("");

		var total = 0;
		var failures = 0;
		var successes = 0;
		var pending = 0;
		var unknnowns = 0;

		var countTests : Suite -> Void = null;
		var printTests : Suite -> Int -> Void = null;

		countTests = function(s : Suite) {
			for (sp in s.steps) switch sp {
				case TSpec(sp):
					total++;
					if (sp.status == TestStatus.Failed) failures++;
					if (sp.status == TestStatus.Passed) successes++;
					else if (sp.status == TestStatus.Pending) pending++;
				case TSuite(s):
					countTests(s);
			}
		};

		suites.iter(countTests);

		printTests = function(s : Suite, indentLevel : Int)
		{
			var print = function(str : String) println(str.lpad(" ", str.length + (indentLevel + 1) * 2));

      var statusToStr = function(status : TestStatus) {
        return switch (status) {
          case TestStatus.Failed:  "[FAIL]";
          case TestStatus.Passed:  "[ OK ]";
          case TestStatus.Pending: "[PEND]";
          case TestStatus.Unknown: "[ ?? ]";
        }
      }
      
      println("");
			print(s.name);
      
			for (step in s.steps) switch step
			{
				case TSpec(sp):
					if (sp.status == TestStatus.Failed)
					{
						print("  " + statusToStr(sp.status) + " " + sp.description + " (ERROR: " + sp.error + ")" + "  (" + timings[sp] + "s)");
            
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
						print("  " + statusToStr(sp.status) + " " + sp.description + "  (" + timings[sp] + "s)");

						printTraces(sp);
					}
				case TSuite(s):
					printTests(s, indentLevel+2);
			}
		};

		suites.iter(printTests.bind(_, 0));

    println("");
		println('$total specs, $successes passed, $failures failed, $pending pending');

    var totalTime = .0;
    for (t in timings) totalTime += t;
    println("total time: " + totalTime);
		println("");
    
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
	#if js
    overallProgress.add(s);
  #else
    Sys.print(s);
  #end
	}

	private function println(s : String)
	{
  #if js
		trace(s);
  #else
    Sys.println(s);
  #end
	}

	private function resolveImmediately<T>(o : T) : Promise<T>
	{
		var def = new Deferred<T>();
		var pr = def.promise();
		def.resolve(o);
		return pr;
	}
}