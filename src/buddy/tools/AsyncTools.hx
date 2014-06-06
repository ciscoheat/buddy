package buddy.tools ;
import promhx.Promise;
import promhx.Deferred;

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
