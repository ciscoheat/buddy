package buddy.internal.sys;
#if js
import js.html.DivElement;
import js.html.Text;
import js.html.SpanElement;
import js.Browser;
using StringTools;

class Js
{
	public static function print(s : String)
	{
		var sp = Browser.document.createSpanElement();
		sp.innerHTML = s.replace(" ", "&nbsp");
		Browser.document.body.appendChild(sp);
	}

	public static function println(s : String)
	{
		var div = Browser.document.createDivElement();
		div.innerHTML = s.replace(" ", "&nbsp;");
		Browser.document.body.appendChild(div);
	}
}
#end