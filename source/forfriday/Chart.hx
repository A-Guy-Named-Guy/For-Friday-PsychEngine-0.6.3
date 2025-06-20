package forfriday;

import backend.Song.SwagSection;

typedef SwagChart =
{
	var chartName:Null<String>;
	var shouldLoop:Null<Bool>;

	var songFileName:Null<String>;
	var voiceFileName:Null<String>;
	var sourceFileName:Null<String>;
	var chartNotes:Null<Array<SwagSection>>;
	var chartEvents:Null<Array<Dynamic>>;

	var chartBpm:Null<Float>;
	var chartNeedsVoices:Null<Bool>;
	var chartSpeed:Null<Float>;
	var chartOffset:Null<Float>;
}

class Chart
{
	public var chartName:Null<String> = 'Inst';

	public var songFileName:Null<String> = 'Inst';
	public var voiceFileName:Null<String> = 'Voices';
	public var sourceFileName:Null<String> = '';
	public var chartNotes:Null<Array<SwagSection>>;
	public var chartEvents:Null<Array<Dynamic>>;

	public var chartBpm:Null<Float>;
	public var chartNeedsVoices:Null<Bool>;
	public var chartSpeed:Null<Float>;
	public var chartOffset:Null<Float>;

	public function new()
	{
	}
}
