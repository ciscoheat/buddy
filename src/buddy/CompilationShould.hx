package buddy;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;

class CompilationShould
{
	// Thanks to back2dos: https://github.com/back2dos/travix/issues/19#issuecomment-222100034
	macro public static function failFor(e : Expr) {
		var exception : String;
		var status = try {
			Context.typeof(e);
			false;
		} catch (ex : Dynamic) {
			exception = Std.string(ex);
			true;
		}
		
		return if(!status) {
			var message = 'Expected expression "${e.toString()}" to fail compilation.';
			var pos = toPosInfos(e.pos);
		
			macro { buddy.SuitesRunner.currentTest($v{status}, $v{message}, buddy.SuitesRunner.posInfosToStack($v{pos})); ""; };
		} else {
			macro ($v{exception} : String);
		}
	}
	
	#if macro
	// Thanks to nadako: https://gist.github.com/nadako/6411325#file-testutils-hx-L33
    static function toPosInfos(p:haxe.macro.Expr.Position):haxe.PosInfos {
        var pi = haxe.macro.Context.getPosInfos(p);
        var line = sys.io.File.getContent(pi.file).substr(0, pi.min).split("\n").length;
        return {
            lineNumber: line,
            fileName: pi.file,
            className: haxe.macro.Context.getLocalClass().get().name,
            methodName: haxe.macro.Context.getLocalMethod()
        };
    }
	#end	
}