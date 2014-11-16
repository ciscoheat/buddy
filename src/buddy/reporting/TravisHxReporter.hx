package buddy.reporting;

import buddy.BuddySuite.Suite;
import buddy.reporting.TraceReporter;

/**
 * For usage together with travis-hx: https://github.com/waneck/travis-hx
 * @author deep <system.grand@gmail.com>
 */
class TravisHxReporter extends TraceReporter
{
	override public function done(suites:Iterable<Suite>, status : Bool)
	{
		var res = super.done(suites, status);
		println('success: ${status}');
		return res;
	}
}