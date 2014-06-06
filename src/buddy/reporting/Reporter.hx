package buddy.reporting ;
import buddy.BuddySuite;

interface Reporter
{
	public function start() : Void;
	public function progress(spec : Spec) : Void;
	public function done(suites : Iterable<Suite>) : Void;
}
