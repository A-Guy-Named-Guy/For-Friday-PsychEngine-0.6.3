package forfriday;

import Section.SwagSection;

typedef SwagChart =
{
	var chartName:String;
	var chartNotes:Array<SwagSection>;
	var songFileName:String;
	var lengthOfChartInSections:Int;
}

class Chart
{
	public var chartName:String = 'Inst';
	public var songFileName:String = 'Inst';
	public var chartNotes:Array<SwagSection>;
	public var lengthOfChartInSections:Int;

	public function new() {}
}
