package buddy.reporting;

import sys.io.File;
import haxe.CallStack.StackItem;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.reporting.Reporter;
import promhx.Deferred;
import promhx.Promise;

using StringTools;

class XUnit2Reporter implements Reporter {
    var reportName : String;

    var total : Int;

    var passing : Int;

    var failures : Int;

    var pending : Int;

    var unknowns : Int;

    var xml : Xml;

    var totalTime : Float;

    public function new() {
        reportName = if (isDefined('report-name')) getDefine('report-name') else 'report';
        total      = 0;
        passing    = 0;
        failures   = 0;
        pending    = 0;
        unknowns   = 0;
        totalTime  = 0;

        xml = Xml.createElement('assemblies');
        xml.set('timestamp', '${getDate()} ${getTime()}');
    }

    static macro function isDefined(key : String) : haxe.macro.Expr {
        return macro $v{haxe.macro.Context.defined(key)};
    }

    static macro function getDefine(key : String) : haxe.macro.Expr {
        return macro $v{haxe.macro.Context.definedValue(key)};
    }

    public function start() : Promise<Bool> {
        return resolve(true);
    }

    public function progress(_spec : Spec) : Promise<Spec> {
        return resolve(_spec);
    }

    public function done(_suites : Iterable<Suite>, _status : Bool) : Promise<Iterable<Suite>> {
        for (suite in _suites) {
            countSuite(suite);
        }

        createReport(_suites);

        return resolve(_suites);
    }

    function resolve<T>(_o : T) : Promise<T> {
        var def = new Deferred<T>();
        var prm = def.promise();

        def.resolve(_o);
        return prm;
    }

    function createReport(_suites : Iterable<Suite>) {
        var assembly = Xml.createElement('assembly');
        assembly.set('name'          , 'Main.hx');
        assembly.set('config-file'   , 'build-cpp.hxml');
        assembly.set('test-framework', 'Buddy');
        assembly.set('environment', '');
        assembly.set('run-date', getDate());
        assembly.set('run-time', getTime());
        assembly.set('total'   , Std.string(total));
        assembly.set('passed'  , Std.string(passing));
        assembly.set('failed'  , Std.string(failures));
        assembly.set('skipped' , Std.string(pending));
        assembly.set('errors'  , Std.string(0));

        var errors = Xml.createElement('errors');

        var collection = Xml.createElement('collection');
        collection.set('name'    , reportName);
        collection.set('total'   , Std.string(total));
        collection.set('passed'  , Std.string(passing));
        collection.set('failed'  , Std.string(failures));
        collection.set('skipped' , Std.string(pending));

        for (suite in _suites) {
            totalTime += suite.time;

            reportSuite(suite, collection, suite.description);
        }

        // Set the time after reporting tests
        collection.set('time', Std.string(totalTime));
        assembly.set('time', Std.string(totalTime));

        assembly.addChild(errors);
        assembly.addChild(collection);
        xml.addChild(assembly);

        var outxml = '<?xml version="1.0" encoding="utf-8"?>\r\n' + xml.toString();

        File.saveContent('$reportName.xml', outxml);
    }

    function reportSuite(_suite : Suite, _collection : Xml, _description : String) {
        for (spec in _suite.specs) {
            if (spec.status == Unknown) {
                continue;
            }

            var test = Xml.createElement('test');
            test.set('type'  , spec.fileName);
            test.set('method', spec.description);
            test.set('name'  , _description + '/' + spec.description);
            test.set('time'  , Std.string(spec.time));

            switch (spec.status) {
                case Passed:
                    test.set('result', 'Pass');
                case Pending:
                    test.set('result', 'Skip');

                    var reason = Xml.createElement('reason');
                    reason.addChild(Xml.createCData('Pending Test'));

                    test.addChild(reason);
                case Failed:
                    test.set('result', 'Fail');
                    for (failure in spec.failures) {
                        var failureElem = Xml.createElement('failure');
                        failureElem.set('exception-type', '');

                        var message = Xml.createElement('message');
                        message.addChild(Xml.createCData(failure.error));

                        var stacktrace = Xml.createElement('stack-track');
                        stacktrace.addChild(Xml.createCData(formatStackTrace(failure.stack)));

                        failureElem.addChild(message);
                        failureElem.addChild(stacktrace);

                        test.addChild(failureElem);
                    }
                case Unknown:
                    test.set('result', 'Skip');
            }

            _collection.addChild(test);
        }

        for (suite in _suite.suites) {
            reportSuite(suite, _collection, _description + '/' + suite.description);
        }
    }

    function formatStackTrace(_stack : Array<StackItem>) : String {
        var buffer = new StringBuf();

        for (item in _stack) {
            switch (item) {
                case FilePos(s, file, line, column):
                    if (line > 0 && file.indexOf('buddy/internal/') != 0 && file.indexOf('buddy.SuitesRunner') != 0) {
                        buffer.add('@ $file:$line\n');
                    }
                default:
                    //
            }
        }

        return buffer.toString();
    }

    function countSuite(_suite : Suite) {
        if (_suite.error != null) {
            failures++;
        }

        for (step in _suite.steps) {
            switch (step) {
                case TSpec(step):
                    total++;

                    switch (step.status) {
                        case Unknown: unknowns++;
                        case Passed : passing++;
                        case Pending: pending++;
                        case Failed : failures++;
                    }

                case TSuite(step):
                    countSuite(step);
            }
        }
    }

    function getDate() : String {
        return '${Std.string(Date.now().getFullYear()).lpad('0', 2)}/${Std.string(Date.now().getMonth() + 1).lpad('0', 2)}/${Std.string(Date.now().getDate()).lpad('0', 2)}';
    }

    function getTime() : String {
        return '${Std.string(Date.now().getHours()).lpad('0', 2)}:${Std.string(Date.now().getMinutes()).lpad('0', 2)}:${Std.string(Date.now().getSeconds()).lpad('0', 2)}';
    }
}