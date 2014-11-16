package buddy.reporting;

import buddy.BuddySuite.Suite;
import buddy.reporting.ConsoleReporter;
import buddy.BuddySuite.TestStatus;

using Lambda;

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

/**
 * For usage together with travis-hx: https://github.com/waneck/travis-hx
 * @author deep <system.grand@gmail.com>
 */
class TravisHxReporter extends ConsoleReporter
{
	override public function done(suites:Iterable<Suite>)
	{
		var res = super.done(suites);

		function successSuite(s : Suite):Bool {
			for (sp in s.steps) switch sp {
				case TSpec(sp) if (sp.status == TestStatus.Failed): return false;
				case TSuite(s) if (!successSuite(s)): return false;
				case _:
			}
			return true;
		};

		var success = suites.foreach(successSuite);

		Sys.println('success: ${success}');

		return res;
	}
}