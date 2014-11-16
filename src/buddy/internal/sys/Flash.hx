package buddy.internal.sys;
#if flash
#if console_log
class Flash
{
	public static function print(s : String)
	{
		trace(s);
	}

	public static function println(s : String)
	{
		trace(s);
	}
}
#else
import flash.events.Event;
import flash.text.TextField;
import flash.Lib;

class Flash
{
	private static var tf : TextField;

	private static function init()
	{
		tf = new TextField();
		var stage = Lib.current.stage;

		stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		stage.addEventListener(Event.RESIZE, function(_) {
			tf.width = stage.stageWidth;
			tf.height = stage.stageHeight;
		});

		Lib.current.addChild(tf);
		stage.dispatchEvent(new Event(Event.RESIZE));
	}

	public static function print(s : String)
	{
		#if !fdb_ci
		if (tf == null) init();
		tf.text += s;
		#end
	}

	public static function println(s : String)
	{
		#if fdb_ci
		trace(s);
		#else
		if (tf == null) init();
		tf.text += s + "\n";
		#end
	}
}
#end
#end