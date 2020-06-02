package buddy.internal.sys;

#if nodejs
class NodeJs
{
	public static function print(s : String)
	{
		#if !macro
		js.Node.process.stdout.write(s);
		#end
	}

	public static function println(s : String)
	{
		#if !macro
		js.Node.console.log(s);
		#end
	}
}
#end
