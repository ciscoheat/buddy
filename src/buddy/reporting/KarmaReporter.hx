package buddy.reporting;

import buddy.reporting.TraceReporter;
import buddy.BuddySuite;
import promhx.Promise;

typedef Karma = {
	result: {
		id: String,
		description: String,
		// the suite to which this test belongs. potentially nested.
		suite: Array<String>,
		// an array of string error messages that might explain a failure.
		// this is required if success is false.
		?log: Array<String>,
		success: Bool,
		skipped: Bool,
		time: Float,
	} -> Void,
	complete: {order: Dynamic, coverage: Dynamic} -> Void,
	error: {} -> Void,
	info: {
		total: Int,
		specs: Dynamic
	} -> Void,
};

class KarmaReporter extends TraceReporter {
	var karmaIsReady: Promise<Karma>;
	var logs = [];
	var specResults = [];
	var lastStartTime: Float;

	public function new() {
		super(true);
		var deferred = new promhx.Deferred();
		karmaIsReady = new Promise(deferred);
		js.Lib.global.__karma__.start = function (config) {
			deferred.resolve(js.Lib.global.__karma__);
		};
	}

	/**
	 * Called just before tests are run. If promise is resolved with "false",
	 * testing will immediately exit with status 1.
	 */
	override public function start() : Promise<Bool> {
		return karmaIsReady.then(function (karma) {
			lastStartTime = Date.now().getTime();
			return true;
		});
	}

	/**
	 * Called for every Spec. Can be used to display realtime notifications.
	 * Resolve with the same spec as the parameter.
	 */
	override public function progress(spec : Spec) : Promise<Spec> {
		var skipped, success;
		switch spec.status {
			case Unknown:
				skipped = true;
				success = null;
			case Pending:
				skipped = true;
				success = null;
			case Passed:
				skipped = false;
				success = true;
			case Failed:
				skipped = false;
				success = false;
		}
		return karmaIsReady.then(function (karma) {
			var logs = [];
			if (spec.failures != null) {
				for (failure in spec.failures) {
					logs.push('' + failure.error);
					logs.push(haxe.CallStack.toString(failure.stack));
				}
			}
			if (spec.traces != null) {
				for (t in spec.traces) {
					logs.push(t);
				}
			}
			var now = Date.now().getTime();
			specResults.push({
				suite: [spec.fileName + ':'],
				id: spec.fileName,
				description: spec.description,
				skipped: skipped,
				success: success,
				log: logs,
				time: now - lastStartTime
			});
			lastStartTime = now;
			return spec;
		});
	}

	/**
	 * Called after the last spec is run. Useful for displaying a test summary.
	 * Resolve with the same iterable as the parameter.
	 * Status is true if all tests passed, otherwise false.
	 */
	override public function done(suites : Iterable<Suite>, status : Bool) : Promise<Iterable<Suite>> {
		super.done(suites, status);
		js.Browser.console.log('\n' + logs.join('\n'));
		return karmaIsReady.then(function (karma) {
			karma.info({
				specs: null,
				total: specResults.length
			});
			for (result in specResults) {
				karma.result(result);
			}
			karma.complete({
				order: null,
				coverage: null
			});
			return suites;
		});
	}

	override function println(s: String) {
		logs.push(s);
	}
}
