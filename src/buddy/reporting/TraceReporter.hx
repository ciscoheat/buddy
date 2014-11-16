package buddy.reporting;

import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.reporting.ConsoleReporter;
import buddy.BuddySuite.TestStatus;

class TraceReporter extends ConsoleReporter
{
	override public function progress(spec:Spec)
	{
		// No progress is shown, it would generate too much noise.
		return resolveImmediately(spec);
	}

	override function println(s:String)
	{
		trace(s);
	}
}