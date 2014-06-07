package buddy.internal.lib;
#if php
import php.Lib;

class PhpLib
{
	static var header = false;

	private static function init()
	{
		header = true;
		Lib.println("<pre>");
	}

	public static function print(s : String)
	{
		if (!header) init();
		Lib.print(s);
	}

	public static function println(s : String)
	{
		if (!header) init();
		Lib.println(s);
	}
}
#end
