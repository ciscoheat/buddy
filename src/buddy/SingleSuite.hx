package buddy;

@:autoBuild(buddy.internal.GenerateMain.withSuites())
class SingleSuite extends BuddySuite
{
	public function new() super();
}