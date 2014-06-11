package buddy.reporting ;
import buddy.BuddySuite;
import promhx.Promise;

interface Reporter
{
	/**
	 * Called just before tests are run. If promise is resolved with "false", testing is immediately aborted.
	 */
	public function start() : Promise<Bool>;

	/**
	 * Called for every Spec. Can be used to display realtime notifications. Resolve with the same spec as the parameter.
	 */
	public function progress(spec : Spec) : Promise<Spec>;

	/**
	 * Called after the last spec is run. Useful for displaying a test summary. Resolve with the same iterable as the parameter.
	 */
	public function done(suites : Iterable<Suite>) : Promise<Iterable<Suite>>;
}
