package buddy.internal.sys;
#if js
#if console_log
class Js
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
import js.html.DivElement;
import js.html.Text;
import js.html.SpanElement;
import js.Browser;
using StringTools;

class Js
{
	private static function replaceSpace(s : String)
	{
		if (Browser.navigator.userAgent.indexOf("PhantomJS") >= 0) return s;
		return s.replace(" ", "&nbsp;");
	}

	public static function print(s : String)
	{
		var sp = Browser.document.createSpanElement();
		sp.innerHTML = replaceSpace(s);
		Browser.document.body.appendChild(sp);
	}

	public static function println(s : String)
	{
		var div = Browser.document.createDivElement();
		div.innerHTML = replaceSpace(s);
		Browser.document.body.appendChild(div);
	}
}
#end
#end