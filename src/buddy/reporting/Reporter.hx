package buddy.reporting ;
import buddy.BuddySuite;
import neko.Lib;

interface Reporter
{
	public function start() : Void;
	public function progress(spec : Spec) : Void;
	public function done(suites : Iterable<Suite>) : Void;
}
