package buddy.reporting ;

import buddy.BuddySuite;
import buddy.reporting.Reporter;
import haxe.CallStack;
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

class ConsoleReporter extends TraceReporter
{
	#if php
	var cli : Bool;
	#end

	public function new() {
		super();
	}

	override public function start()
	{
		// A small convenience for PHP, to avoid creating a new reporter.
		#if php
		cli = (untyped __call__("php_sapi_name")) == 'cli';
		if(!cli) println("<pre>");
		#end

		return resolveImmediately(true);
	}

	override public function progress(spec : Spec)
	{
		print(switch(spec.status) {
			case TestStatus.Failed: "X";
			case TestStatus.Passed: ".";
			case TestStatus.Pending: "P";
			case TestStatus.Unknown: "?";
		});

		return resolveImmediately(spec);
	}

	override public function done(suites : Iterable<Suite>, status : Bool)
	{
		var output = super.done(suites, status);

		#if php
		if(!cli) println("</pre>");
		#end

		return output;
	}

	override private function print(s : String)
	{
		Sys.print(s);
	}

	override private function println(s : String)
	{
		Sys.println(s);
	}
}
