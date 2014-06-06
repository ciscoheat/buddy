package buddy.internal.js;
import js.Browser;

class Lib
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