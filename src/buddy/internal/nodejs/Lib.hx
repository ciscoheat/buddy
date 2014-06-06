package buddy.internal.nodejs;

/**
 * ...
 * @author ciscoheat
 */
class Lib
{
	public static function print(s : String)
	{
		untyped __js__("process.stdout.write(s)");
	}

	public static function println(s : String)
	{
		untyped __js__("console.log(s)");
	}
}