package buddy.tests;

import buddy.BuddySuite.Failure;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.BuddySuite.SpecStatus;

/**
 * Used for Buddy to test itself
 */
class SelfTest {
	public static var lastSpec : Spec = new Spec("No spec", "No filename");
	public static var lastSuite : Suite = new Suite("No suite");
	
	public static function passLastSpecIf(expr : Bool, failReason : String) {
		if (expr) {
			setLastSpec(Passed);
		}
		else {
			setLastSpec(Failed);
			lastSpec.failures.push(new Failure(failReason, []));
		}
	}
	
	public static function setLastSpec(status : SpecStatus) {
		Reflect.setProperty(lastSpec, "status", status);
	}
}