package ;
import BDDSuite;
import neko.Lib;

interface BDDReporter
{
	public function start() : Void;
	public function progress(spec : Spec) : Void;
	public function done(suites : Iterable<Suite>) : Void;
}
