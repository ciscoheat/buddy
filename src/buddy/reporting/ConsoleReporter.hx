package buddy.reporting;

import buddy.BuddySuite;
import buddy.reporting.Reporter;
import haxe.CallStack;
import buddy.reporting.TraceReporter.Color;
using Lambda;
using StringTools;

#if nodejs
import buddy.internal.sys.NodeJs;
private typedef Sys = NodeJs;
#elseif js
import js.html.PreElement;
import js.Browser;
import buddy.internal.sys.Js;
private typedef Sys = Js;
#elseif flash
import buddy.internal.sys.Flash;
private typedef Sys = Flash;
#end

class ConsoleReporter extends TraceReporter
{
	public function new(colors = false) {
		super(colors);
	}

	override public function start()
	{
		// A small convenience for PHP, to avoid creating a new reporter.
		#if php
		if (untyped __call__("php_sapi_name") != "cli") println("<pre>");
		#elseif (js && !nodejs)
		Js.outputElement = Browser.document.createPreElement();
		Browser.document.body.appendChild(Js.outputElement);
		#end

		return resolveImmediately(true);
	}

	override public function progress(spec : Spec)
	{
		print((switch(spec.status) {
			case Failed: strCol(Red) + "X";
			case Passed: strCol(Green) + ".";
			case Pending: strCol(Yellow) + "P";
			case Unknown: strCol(Yellow) + "?";
		}) + strCol(Default));

		return resolveImmediately(spec);
	}

	override public function done(suites : Iterable<Suite>, status : Bool)
	{
		var output = super.done(suites, status);

		#if php
		if(untyped __call__("php_sapi_name") != "cli") println("</pre>");
		#end	
		
		return output;
	}

	override private function print(s : String)
	{
		Sys.print(s);
		#if php
		untyped __call__("flush");
		#end
	}

	override private function println(s : String)
	{
		Sys.println(s);
		#if php
		untyped __call__("flush");
		#end
	}
}
