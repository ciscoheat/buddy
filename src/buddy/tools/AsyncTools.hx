package buddy.tools ;
import promhx.Promise;
import promhx.Deferred;

#if neko
import neko.vm.Thread;
#elseif cs
import cs.system.timers.ElapsedEventHandler;
import cs.system.timers.ElapsedEventArgs;
import cs.system.timers.Timer;
#elseif java
import java.util.concurrent.FutureTask;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
#elseif cpp
import cpp.vm.Thread;
#else
import haxe.Timer;
#end

class AsyncTools
{
	public static function iterateAsyncBool<T>(it : Iterable<T>, action : T -> Promise<T>) : Promise<Bool>
	{
		return iterateAsync(it, action, true);
	}

	public static function iterateAsync<T, T2>(it : Iterable<T>, action : T -> Promise<T>, resolveWith : T2) : Promise<T2>
	{
		var finished = new Deferred<T2>();
		var pr = finished.promise();
		next(it.iterator(), action, finished, resolveWith);
		return pr;
	}

	public static function wait(ms : Int) : Promise<Bool>
	{
		var def = new Deferred<Bool>();
		var pr = def.promise();
		var done = function() { if (!pr.isFulfilled()) def.resolve(true); };

		#if neko
		Thread.create(function() {
			Sys.sleep(ms / 1000);
			done();
		});
		#elseif (js || flash)
		Timer.delay(function() { done(); }, ms);
		#elseif cs
		var t = new Timer(ms);
		t.add_Elapsed(new ElapsedEventHandler(function(sender : Dynamic, e : ElapsedEventArgs) {
			t.Stop(); t = null;
			done();
		}));
		t.Start();
		#elseif java
		var executor = Executors.newFixedThreadPool(1);
		var call = new AsyncCallable(function() {
			executor.shutdown(); executor = null;
			done();
		}, ms);
		executor.execute(new FutureTask(call));
		#elseif cpp
		Thread.create(function() {
			Sys.sleep(ms / 1000);
			done();
		});
		#else
		Sys.sleep(ms / 1000);
		done();
		#end

		return pr;
	}

	private static function next<T, T2>(it : Iterator<T>, action : T -> Promise<T>, def : Deferred<T2>, resolveWith : T2)
	{
		/*
		trace("Next");
		trace(Type.getClassName(Type.getClass(resolveWith)));
		trace(resolveWith);
		trace("==============");
		*/

		if (!it.hasNext())
		{
			//trace("Iterator empty");
			def.resolve(resolveWith);
		}
		else
		{
			var n = it.next();
			//trace("Iterating " + Type.getClassName(Type.getClass(n)));
			action(n).then(function(_) { next(it, action, def, resolveWith); } );
		}
	}
}

#if java
private class AsyncCallable implements Callable<String>
{
	private var done : Void -> Void;
	private var waitMs : Int;

	public function new(done : Void -> Void, waitMs : Int)
	{
		this.done = done;
		this.waitMs = waitMs;
	}

	public function call() : String
	{
		Sys.sleep(waitMs / 1000);
		done();
		return "";
	}
}
#end