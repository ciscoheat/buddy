package buddy.internal.sys;

#if nodejs
class NodeJs
{
	public static function print(s : String)
	{
		#if !macro
		untyped __js__("process.stdout.write(s)");
		#end
	}

	public static function println(s : String)
	{
		#if !macro
		untyped __js__("console.log(s)");
		#end
	}
}
#end
