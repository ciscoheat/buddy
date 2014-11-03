package buddy.internal;
import buddy.BuddySuite.Suite;
import buddy.BuddySuite.Spec;
import buddy.reporting.Reporter;
import promhx.Deferred;
import promhx.Promise;

class TestReporter implements Reporter
{
	public function new()
	{}

	public function start():Promise<Bool>
	{
		trace("TestReporter starting");

		var def = new Deferred<Bool>();
		var pr = def.promise();

		def.resolve(false);
		return pr;
	}

	public function progress(spec:Spec):Promise<Spec>
	{
		return new Deferred<Spec>().promise();
	}

	public function done(suites:Iterable<Suite>):Promise<Iterable<Suite>>
	{
		return new Deferred<Iterable<Suite>>().promise();
	}
}