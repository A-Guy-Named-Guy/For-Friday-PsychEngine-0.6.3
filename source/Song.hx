package;

import Section.SwagSection;
import forfriday.Chart.SwagChart;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;

	// Combat change
	var disableCombat:Bool;
	var endSongOnDefeat:Bool;

	// var loopBeatStart:Float;
	var activeChart:String;
	var chartArray:Array<SwagChart>;

	var useIntroChart:Bool;
	var skipCountdown:Bool;
	var skipIntroOnRestart:Bool;
	// End
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
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	// Combat changes
	public var noteType:String = '';
	public var disableCombat:Bool = true;
	public var endSongOnDefeat:Bool = false;

	public var activeChart:String = 'Inst';
	public var chartArray:Array<SwagChart>;

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

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		// Combat change
		// SwagSong notes code
		//
		// Records events
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
	}

	public function new(song, notes, bpm)
	{
		// Combat change
		// SwagSong notes code
		//
		// Not sure if notes from Song is ever used?
		// Maybe it does, but changing inline of notes variable didn't change the things that were hoped for
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;

		// Combat change
		// Note that the case of the songs entered into respective week jsons matter!
		// The first song played in PlayState seems to default to lower case, but afterwards these json names seem to inherit the case entered in the weeks json
		//
		// For total safety, don't capitalize any of the songs in the respective week json, as this caused a problem with loading dialogues due to case-sensitivity
		if (jsonInput.endsWith('-easy'))
			jsonName = StringTools.replace(jsonInput, "-easy", "");
		else if (jsonInput.endsWith('-hard'))
			jsonName = StringTools.replace(jsonInput, "-hard", "");
		else
			jsonName = jsonInput;

		jsonFullName = jsonInput;
		// End of changes
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);

		if (FileSystem.exists(moddyFile))
		{
			rawJson = File.getContent(moddyFile).trim();
		}
		#end
		if (rawJson == null)
		{
			#if sys
			rawJson = File.getContent(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#else
			rawJson = Assets.getText(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#end
		}
		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}
		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);
		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		var songJson:Dynamic = parseJSONshit(rawJson);
		if (jsonInput != 'events')
			StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
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
		var sec = null;

		if (section != null)
			sec = {
				sectionBeats: section.sectionBeats,
				bpm: section.bpm,
				changeBPM: section.changeBPM,
				mustHitSection: section.mustHitSection,
				gfSection: section.gfSection,
				sectionNotes: section.sectionNotes,
				typeOfSection: section.typeOfSection,
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
				typeOfSection: 0,
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
