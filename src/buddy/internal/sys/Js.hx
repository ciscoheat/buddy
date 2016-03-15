package buddy.internal.sys;
#if js
import js.html.Element;
import js.html.DivElement;
import js.html.Text;
import js.html.SpanElement;
import js.Browser;
using StringTools;

class Js
{
	// Set in ConsoleReporter
	public static var outputElement : Element;
	
	public static function print(s : String) {
		outputElement.innerHTML += s;
	}

	public static function println(s : String) {
		outputElement.innerHTML += s + "\n";
	}
}
#end