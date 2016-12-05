package buddy.reporting;

import buddy.BuddySuite.Spec;

class ConsoleFileReporter extends ConsoleReporter
{
	var lastFileName : String = null;
	
	public function new(colors = false) {
		super(colors);
	}

	override public function progress(spec : Spec)
	{
		if(lastFileName != spec.fileName) {
			if(lastFileName != null) {
				progressString += "\n";
				println("");
			}

			progressString += spec.fileName + ": ";
			print(spec.fileName + ": ");

			lastFileName = spec.fileName;
		}

		var status = switch(spec.status) {
			case Failed: strCol(Red) + "X";
			case Passed: strCol(Green) + ".";
			case Pending: strCol(Yellow) + "P";
			case Unknown: strCol(Yellow) + "?";
		}
		
		progressString += status;
		print(status + strCol(Default));

		return resolveImmediately(spec);
	}
}
