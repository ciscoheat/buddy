package buddy.tests;

import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.BuddySuite.TestStatus;

/**
 * Used for Buddy to test itself
 */
class SelfTest {
	public static var lastSpec : Spec;
	public static var lastSuite : Suite;
	
	public static function passLastSpecIf(expr : Bool, failReason : String) {
		if (expr) {
			setLastSpec(Passed);
			failReason = null;
		}
		else {
			setLastSpec(Failed);
		}
		
		Reflect.setProperty(lastSpec, "error", failReason);
	}
	
	public static function setLastSpec(status : TestStatus) {
		Reflect.setProperty(lastSpec, "status", status);
	}
}