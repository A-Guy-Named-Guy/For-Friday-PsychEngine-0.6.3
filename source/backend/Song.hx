package backend;

import forfriday.Chart.SwagChart;
import haxe.Json;
import lime.utils.Assets;
import objects.Note;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	// Combat changes
	var disableCombat:Bool;
	var endSongOnDefeat:Bool;
	var activeChart:String;
	var chartArray:Null<Array<SwagChart>>;

	var useIntroChart:Bool;
	var skipCountdown:Bool;
	var skipIntroOnRestart:Bool;
	// End of changes
	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var format:String = 'psych_v1';

	// Combat changes
	public var noteType:String = '';
	public var disableCombat:Bool = true;
	public var endSongOnDefeat:Bool = false;

	public var activeChart:String = 'Inst';

	public var useIntroChart:Bool = false;
	public var skipCountdown:Bool = false;
	public var skipIntroOnRestart:Bool = false;

	// SONG.song, which is used to save highscore information in vanilla code, saves to the name of the song itself rather than the name of the json.
	// This variable stores the name of the json so checks for setting save info to the right name can be done
	// Without this, stuff like training-reversed would only be saved to training, which would overwrite the actual training song's data
	public static var jsonName:String = '';
	// jsonName has the -easy and -hard pruned out, so this variable is intended for reading the full name of the json
	public static var jsonFullName:String = '';

	// End of changes

	public static function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
	{
		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			if (Reflect.hasField(songJson, 'player3'))
				Reflect.deleteField(songJson, 'player3');
		}

		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else
						i++;
				}
			}
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if (sectionsData == null)
			return;

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if (Reflect.hasField(section, 'lengthInSteps'))
					Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

				if (!Std.isOfType(note[3], String))
					note[3] = Note.defaultNoteTypes[note[3]]; // compatibility with Week 7 and 0.1-0.3 psych charts
			}
		}
	}

	public static var chartPath:String;
	public static var loadedSongName:String;

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if (folder == null)
			folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath.replace('/', '\\');
		StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;

	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if (folder == null)
			folder = jsonInput;
		var rawData:String = null;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = Paths.json('$formattedFolder/$formattedSong');

		#if MODS_ALLOWED
		if (FileSystem.exists(_lastPath))
			rawData = File.getContent(_lastPath);
		else
		#end
		rawData = Assets.getText(_lastPath);

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		var songJson:SwagSong = cast Json.parse(rawData);
		if (Reflect.hasField(songJson, 'song'))
		{
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if (subSong != null && Type.typeof(subSong) == TObject)
				songJson = subSong;
		}

		if (convertTo != null && convertTo.length > 0)
		{
			var fmt:String = songJson.format;
			if (fmt == null)
				fmt = songJson.format = 'unknown';

			switch (convertTo)
			{
				case 'psych_v1':
					if (!fmt.startsWith('psych_v1')) // Convert to Psych 1.0 format
					{
						trace('converting chart $nameForError with format $fmt to psych_v1 format...');
						songJson.format = 'psych_v1_convert';
						convert(songJson);
					}
			}
		}
		return songJson;
	}

	// Combat change
	// Having these functions in the Song class seems to make the most sense
	public static function retrieveNotesFromChartArray(curChartName:String, song:SwagSong):Array<SwagSection>
	{
		var sectionCount:Int = 0;

		var returnNotes:Array<SwagSection> = [];

		for (i in 0...song.chartArray.length)
		{
			if (song.chartArray[i].chartName != curChartName)
				continue;

			// Combat change note
			// There's not a perfect spot to explain this so I'll put this here
			//
			// Trying to store the song.chartArray in any capacity
			// (Like trying to write it to a variable)
			// Destroys the sectionNotes information
			// Thus the i in ... method is used instead of section in x
			for (ii in 0...song.chartArray[i].chartNotes.length)
			{
				var sec:SwagSection = newSection(song.chartArray[i].chartNotes[ii], song);

				if (returnNotes[sectionCount] == null)
					returnNotes.insert(sectionCount, sec);

				returnNotes[sectionCount] = sec;

				++sectionCount;
			}

			break;
		}

		return returnNotes;
	}

	static function newSection(section:SwagSection = null, song:SwagSong):SwagSection
	{
		var sec:SwagSection = null;

		if (section != null)
			sec = {
				sectionBeats: section.sectionBeats,
				bpm: section.bpm,
				changeBPM: section.changeBPM,
				mustHitSection: section.mustHitSection,
				gfSection: section.gfSection,
				sectionNotes: section.sectionNotes,
				altAnim: section.altAnim
			};
		else
			sec = {
				sectionBeats: 4,
				bpm: song.bpm,
				changeBPM: false,
				mustHitSection: true,
				gfSection: false,
				sectionNotes: [],
				altAnim: false
			};

		return sec;
	}

	public static function getChartByName(name:String, song:SwagSong):SwagChart
	{
		if (song.chartArray == null)
			return null;

		for (chart in song.chartArray)
		{
			if (chart.chartName == name)
				return chart;
		}

		return null;
	}

	public static function retrieveNameInChartList(name:String, song:SwagSong):String
	{
		if (song.chartArray == null)
			return null;

		for (chart in song.chartArray)
		{
			if (chart.chartName == name)
				return chart.chartName;
		}

		return null;
	}

	public static function appendUpcomingChart(upcomingChart:SwagChart, currentChart:SwagChart, currentNotes:Array<SwagSection>):Void
	{
		var noteTimeModifier:Float = 0;
		var sectionCount:Int = 0;

		for (section in currentChart.chartNotes)
		{
			if (section != null)
			{
				++sectionCount;

				if (sectionCount > {currentChart.lengthOfChartInSections == 0 ? currentChart.chartNotes.length : currentChart.lengthOfChartInSections;})
					break;

				noteTimeModifier += ((section.bpm / 60) * 1000 * section.sectionBeats);
			}
		}

		var sectionsToAdd:Array<SwagSection> = [];

		for (i in 0...1)
		{
			sectionsToAdd.push(upcomingChart.chartNotes[i]);
		}

		for (section in sectionsToAdd)
		{
			if (section != null)
			{
				for (i in 0...section.sectionNotes.length)
					section.sectionNotes[i][0] += noteTimeModifier;

				currentNotes.push(section);
			}
		}
	}

	// End of changes
}
