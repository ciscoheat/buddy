package buddy.internal.sys;

#if nodejs
class NodeJs
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
#end
