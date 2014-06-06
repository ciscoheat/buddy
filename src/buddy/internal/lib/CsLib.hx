package buddy.internal.lib;
#if cs
import cs.io.NativeOutput;
import cs.Lib;
import cs.system.Console;

class CsLib
{
	public static function print(s : String)
	{
		Console.Write(s);
	}

	public static function println(s : String)
	{
		Console.WriteLine(s);
	}
}
#end
