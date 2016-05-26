package buddy.internal.sys;

#if js
import js.Browser;
using StringTools;

class Js
{
	static var completed = ~/^\d+ specs, (\d+) failures, (\d+) pending$/;
	
	public static function print(s : String) {
	}

	public static function println(s : String) {
		var log = Browser.window.console;
		if (completed.match(s)) {
			switch Std.parseInt(completed.matched(1)) {
				case 0: 
					switch Std.parseInt(completed.matched(2)) {
						case 0: log.info('%c$s', 'color: green');
						case _: log.warn('%c$s', 'color: green');
					}
					
				case _: log.error(s);
			}
		} else 
			log.log(s);
	}
}
#end