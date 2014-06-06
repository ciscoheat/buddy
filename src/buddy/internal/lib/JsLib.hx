package buddy.internal.lib;
#if js
import js.html.DivElement;
import js.html.Text;
import js.html.SpanElement;
import js.Browser;

class JsLib
{
	public static function print(s : String)
	{
		var sp = Browser.document.createSpanElement();
		sp.innerText = s;
		Browser.document.body.appendChild(sp);
	}

	public static function println(s : String)
	{
		var div = Browser.document.createDivElement();
		div.innerText = s;
		Browser.document.body.appendChild(div);
	}
}
#end