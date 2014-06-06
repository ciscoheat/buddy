package buddy.internal.lib;
#if js
import js.Browser;

class JsLib
{
	public static function print(s : String)
	{
		Browser.document.write(s);
	}

	public static function println(s : String)
	{
		Browser.document.writeln(s);
	}
}
#end