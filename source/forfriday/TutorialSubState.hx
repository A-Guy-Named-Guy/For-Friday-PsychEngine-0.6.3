package forfriday;

import Map.IMap;
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

typedef TutorialFile =
{
	var tutorial_title:String;
	var tutorial_text:Array<TutorialTextData>;
	var images:Array<TutorialImageData>;
}

typedef TutorialTextData =
{
	var text:String;
	var size:Int;
	var position:Array<Float>;
	var screenCenterX:Bool;
	var screenCenterY:Bool;
}

typedef TutorialImageData =
{
	var image:String;
	var no_antialiasing:Bool;
	var position:Array<Float>;
	var flip_x:Bool;
	var scale:Float;
	var screenCenterX:Bool;
	var screenCenterY:Bool;
	var animation:TutorialAnimArray;
}

typedef TutorialAnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
}

typedef TutorialListData =
{
	var tutorial_list:Array<String>;
	var check_all_difficulties_for_tutorial:Array<String>;
	var all_difficulties_check_exceptions:Array<String>;
	var tutorial_song_pages:Array<SongPage>;
	var tutorial_clusters:Array<TutorialCluster>;

	var default_menu_music:String;
	var menu_music:Array<TutorialMusic>;
}

typedef SongPage =
{
	var song:String;
	var pages:Array<String>;
}

typedef TutorialCluster =
{
	var name:String;
	var pages:Array<String>;
}

typedef TutorialMusic =
{
	var song_name:String;
	var tutorial_song:Array<String>;
}

class TutorialSubState extends MusicBeatSubstate
{
	public var attackBind:String = ClientPrefs.keyBinds.get('attack')[0];
	public var specialBind:String = ClientPrefs.keyBinds.get('special')[0];

	public static var textMap:Map<String, String> = new Map();

	public var tutorialTitle:FlxText = null;
	public var mainText:FlxText = null;
	public var screenNum:FlxText = null;

	public var curScreenGroup = new FlxTypedGroup<FlxSprite>();
	public var constantGroup = new FlxTypedGroup<FlxText>();
	public var extraTextGroup = new FlxTypedGroup<FlxText>();
	public var curScreenNum:Int = 0;
	public var maxScreenNum:Int = 0;

	public var menuAccessedFrom:String = 'PauseSubState';
	public var tutorial:String = 'training';

	public var tutorialList:Array<String> = [];

	var menuSong:String = 'tutorialMenu';

	public var tutorialTitleGroup = new FlxTypedGroup<FlxText>();
	public var isTutorialList:Bool = true;
	public var curSelected:Int = 0;

	var tutorialMusic:FlxSound;

	var bfScreenX:Float = 0;
	var bfScreenY:Float = 0;

	public function new(x:Float, y:Float, tutorial:String, menuAccessedFrom:String)
	{
		super();

		this.menuAccessedFrom = menuAccessedFrom;
		this.tutorial = tutorial;

		bfScreenX = x;
		bfScreenY = y;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		tutorialTitle = new FlxText(0, 20, 0, 'Select A Tutorial', 24);
		tutorialTitle.scrollFactor.set();
		tutorialTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		tutorialTitle.updateHitbox();
		tutorialTitle.screenCenter(X);
		constantGroup.add(tutorialTitle);

		mainText = new FlxText(0, 0, 0, 'Nothing was put here!', 16);
		mainText.scrollFactor.set();
		mainText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		mainText.updateHitbox();
		constantGroup.add(mainText);
		mainText.visible = false;

		add(constantGroup);
		add(curScreenGroup);
		add(tutorialTitleGroup);

		// Certain variables for filling in control inputs ($attackBind, $gpAttackBind, etc.) cannot be done in variable initialization
		// So this function's purpose is to just move filling the text map outside intizialization so those can be included
		fillTextMap();

		changeScreen(0, tutorial);

		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.9}, 0.4, {ease: FlxEase.quartInOut});

		var json:TutorialListData = parseJson();

		menuSong = json.default_menu_music;
		for (song in json.menu_music)
		{
			if (song.tutorial_song.contains(Song.jsonName))
			{
				menuSong = song.song_name;
			}
		}

		if (menuSong != 'none' || menuSong != '')
		{
			tutorialMusic = new FlxSound().loadEmbedded(Paths.music(menuSong), true, true);
			tutorialMusic.play(false);
			tutorialMusic.volume = 0;

			FlxG.sound.list.add(tutorialMusic);
		}

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		// Can't use fadeIn since the destroy() override to get rid of the sound seems to cause a crash since it attempts to modify a volume that doesn't exist
		if (menuSong != 'none' || menuSong != '')
		{
			if (tutorialMusic.volume < 0.5)
				tutorialMusic.volume += 0.1 * elapsed;
		}

		super.update(elapsed);

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		var leftPcontroller:Bool = false;
		var rightPcontroller:Bool = false;
		var upPcontroller:Bool = false;
		var downPcontroller:Bool = false;

		if (maxScreenNum > 0 && !isTutorialList)
		{
			if (controls.UI_LEFT_P || leftPcontroller)
				changeScreen(-1, tutorial);
			else if (controls.UI_RIGHT_P || rightPcontroller)
				changeScreen(1, tutorial);
		}

		if (isTutorialList)
		{
			if (controls.UI_UP_P || upPcontroller)
				changeSelection(-1);
			else if (controls.UI_DOWN_P || downPcontroller)
				changeSelection(1);
		}

		if (controls.BACK)
		{
			// Since the tutorial list is most likely only accessed through the pause menu,
			// This just assumes we're going back to the song pause substate
			if (isTutorialList)
				FlxG.state.openSubState(new PauseSubState(bfScreenX, bfScreenY));
			else
			{
				switch (menuAccessedFrom)
				{
					case 'PauseSubState':
						FlxG.state.openSubState(new PauseSubState(bfScreenX, bfScreenY));
					default:
						close();
				}
			}
		}

		if (controls.ACCEPT)
		{
			if (isTutorialList)
				changeScreen(0, tutorialList[curSelected]);
			else
				switch (menuAccessedFrom)
				{
					case 'PauseSubState':
						changeScreen(0, 'tutorialList');
					default:
						close();
				}

			curSelected = 0;
		}
	}

	public function createScreenNumberText():Void
	{
		screenNum = new FlxText(0, FlxG.height, 0, '< ${curScreenNum + 1} / ${maxScreenNum + 1} >', 24);
		screenNum.scrollFactor.set();
		screenNum.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		screenNum.updateHitbox();

		screenNum.screenCenter(X);
		screenNum.y -= screenNum.height;
		screenNum.y -= 20;

		constantGroup.add(screenNum);
	}

	private function changeSelection(change)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = tutorialList.length - 1;
		if (curSelected >= tutorialList.length)
			curSelected = 0;

		for (item in tutorialTitleGroup.members)
			item.alpha = 0.6;

		tutorialTitleGroup.members[curSelected].alpha = 1;
	}

	private function changeScreen(change:Int, ?curTutorial:String):Void
	{
		curScreenNum += change;

		cleanGroup(curScreenGroup);

		var json:TutorialListData = parseJson();

		if (json.tutorial_list != null)
			tutorialList = json.tutorial_list;

		var tutorialScreensArray:Array<String> = [];
		if (Song.jsonFullName == Song.jsonName)
			tutorialScreensArray.push(curTutorial);

		var readyToBreak:Bool = false;
		if (curTutorial != 'tutorialList')
		{
			for (page in json.tutorial_song_pages)
			{
				if (json.check_all_difficulties_for_tutorial.contains(curTutorial)
					&& !json.all_difficulties_check_exceptions.contains(curTutorial)
					&& page.song == Song.jsonFullName)
				{
					if (page.song == curTutorial || curTutorial == 'Current Song Tutorial')
						readyToBreak = true;
				}
				else if (Song.jsonFullName == Song.jsonName && page.song == Song.jsonName)
				{
					if (page.song == curTutorial || curTutorial == 'Current Song Tutorial')
						readyToBreak = true;
				}

				if (readyToBreak)
				{
					tutorialScreensArray = [];
					for (i in 0...page.pages.length)
					{
						tutorialScreensArray.push(page.pages[i]);
					}
					break;
				}
			}

			if (curTutorial == 'Current Song Tutorial' && tutorialScreensArray.length == 0)
				tutorialTitle.text = 'No tutorial tied to this song!';

			if (json.tutorial_clusters != null && json.tutorial_clusters.length > 0 && tutorialScreensArray.length > 0)
			{
				for (page in json.tutorial_clusters)
				{
					if (tutorialScreensArray.contains(page.name))
					{
						for (i in 0...page.pages.length)
						{
							tutorialScreensArray.insert(tutorialScreensArray.indexOf(page.name), page.pages[i]);
						}
						tutorialScreensArray.remove(page.name);
					}
				}
			}
		}

		maxScreenNum = tutorialScreensArray.length - 1;

		if (curScreenNum < 0)
			curScreenNum = maxScreenNum;
		if (curScreenNum > maxScreenNum)
			curScreenNum = 0;

		createTutorialScreen(tutorialScreensArray[curScreenNum]);

		// Changing the text shifts the title offcenter, so this is needed to correct for that
		tutorialTitle.screenCenter(X);

		if (screenNum != null)
			screenNum.text = '< ${curScreenNum + 1} / ${maxScreenNum + 1} >';
		else
			createScreenNumberText();

		// Remember that a max screen of 1 means there's two screens
		if (maxScreenNum > 0)
			screenNum.visible = true;
		else
			screenNum.visible = false;

		curScreenGroup.forEach(function(spr:FlxSprite)
		{
			spr.alpha = 0;
			FlxTween.tween(spr, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut});
		});
		constantGroup.forEach(function(txt:FlxText)
		{
			txt.alpha = 0;
			FlxTween.tween(txt, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut});
		});

		tutorial = curTutorial;
	}

	public function createTutorialScreen(screenName:String):Void
	{
		cleanGroup(extraTextGroup);

		mainText.visible = true;
		mainText.size = 16;
		isTutorialList = false;
		tutorialTitleGroup.kill();

		tutorialTitle.text = screenName;
		mainText.text = textMap.get(screenName);
		mainText.x = 60;
		// Just a note: screenCenter needs to be updated after every text change
		// So redundant screenCenters later on are intentional and required
		mainText.screenCenter(Y);

		switch (screenName)
		{
			// From PsychEngine's character json-parsing code
			// Like there, just add a switch check if you want to hardcode a tutorial
			default:
				var json:TutorialFile = parseJson('tutorials/' + screenName + '.json');

				var jsonTextDataArray:Array<TutorialTextData> = json.tutorial_text;
				var jsonImageDataArray:Array<TutorialImageData> = json.images;

				if (json.tutorial_title != null)
					tutorialTitle.text = (json.tutorial_title);
				else
					tutorialTitle.text = screenName;

				if (jsonTextDataArray != null && jsonTextDataArray.length > 0)
				{
					var curTextID:Int = 0;
					for (text in jsonTextDataArray)
					{
						if (curTextID != 0)
						{
							var newText = new FlxText(0, 0, 0, 'Nothing was put here!', 16);
							newText.scrollFactor.set();
							newText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
							newText.size = text.size;
							newText.updateHitbox();

							assignText(newText, text);
						}
						else
							assignText(mainText, text);

						++curTextID;
					}
				}

				if (jsonImageDataArray != null && jsonImageDataArray.length > 0)
				{
					for (image in jsonImageDataArray)
					{
						var tutorialImage:FlxSprite = new FlxSprite(image.position[0], image.position[1]);

						if (image.animation != null)
						{
							var tutorialAnim:TutorialAnimArray = image.animation;

							var spriteType = "sparrow";
							#if MODS_ALLOWED
							var modTxtToFind:String = Paths.modsTxt(image.image);
							var txtToFind:String = Paths.getPath('images/' + image.image + '.txt', TEXT);

							if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
							#else
							if (Assets.exists(Paths.getPath('images/' + image.image + '.txt', TEXT)))
							#end
							{
								spriteType = "packer";
							}

							#if MODS_ALLOWED
							var modAnimToFind:String = Paths.modFolders('images/' + image.image + '/Animation.json');
							var animToFind:String = Paths.getPath('images/' + image.image + '/Animation.json', TEXT);

							if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
							#else
							if (Assets.exists(Paths.getPath('images/' + image.image + '/Animation.json', TEXT)))
							#end
							{
								spriteType = "texture";
							}

							switch (spriteType)
							{
								case "packer":
									tutorialImage.frames = Paths.getPackerAtlas(image.image);

								case "sparrow":
									tutorialImage.frames = Paths.getSparrowAtlas(image.image);

								case "texture":
									tutorialImage.frames = AtlasFrameMaker.construct(image.image);
							}

							var animAnim:String = '' + tutorialAnim.anim;
							var animName:String = '' + tutorialAnim.name;
							var animFps:Int = tutorialAnim.fps;
							var animLoop:Bool = !!tutorialAnim.loop; // Bruh
							var animIndices:Array<Int> = tutorialAnim.indices;
							if (animIndices != null && animIndices.length > 0)
							{
								tutorialImage.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
							}
							else
							{
								tutorialImage.animation.addByPrefix(animAnim, animName, animFps, animLoop);
							}

							tutorialImage.animation.play(animAnim);
						}
						else
							// Ah, yes
							// The image image image
							tutorialImage.loadGraphic(Paths.image(image.image));

						if (image.scale != 1)
						{
							tutorialImage.setGraphicSize(Std.int(tutorialImage.width * image.scale));
							tutorialImage.updateHitbox();
						}

						tutorialImage.flipX = !!image.flip_x;

						if (image.no_antialiasing)
						{
							tutorialImage.antialiasing = false;
						}

						if (image.screenCenterX)
						{
							tutorialImage.screenCenter(X);
							Math.round(tutorialImage.x);
						}
						if (image.screenCenterY)
						{
							tutorialImage.screenCenter(Y);
							Math.round(tutorialImage.y);
						}

						curScreenGroup.add(tutorialImage);
					}
				}

			case 'tutorialList':
				isTutorialList = true;
				mainText.visible = false;
				tutorialTitle.text = 'Select A Tutorial';
				updateTutorialSelectionList();
		}
	}

	function updateTutorialSelectionList():Void
	{
		cleanGroup(tutorialTitleGroup);

		tutorialTitleGroup.revive();

		for (i in 0...tutorialList.length)
		{
			var tutorialTitleText:FlxText = new FlxText(20, 60, 0, tutorialList[i], 24);
			tutorialTitleText.scrollFactor.set();
			tutorialTitleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			tutorialTitleText.y += ((tutorialTitleText.height + 15) * i);
			tutorialTitleText.updateHitbox();

			tutorialTitleGroup.add(tutorialTitleText);
		}

		for (item in tutorialTitleGroup.members)
		{
			item.alpha = 0;

			if (item != tutorialTitleGroup.members[curSelected])
				FlxTween.tween(item, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
			else
				FlxTween.tween(item, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut});
		}
	}

	function cleanGroup(group:FlxTypedGroup<Dynamic>):Void
	{
		if (group.members.length > 0)
		{
			var i:Int = group.members.length - 1;
			while (i >= 0)
			{
				var memb:Dynamic = group.members[i];
				if (memb != null)
				{
					memb.kill();
					group.remove(memb);
					memb.destroy();
				}
				--i;
			}
			group.clear();
		}
	}

	function assignText(textObject:FlxText, textData:TutorialTextData):Void
	{
		textObject.text = textData.text;
		textObject.text = textObject.text.replace("$attackBind", attackBind);
		textObject.text = textObject.text.replace("$specialBind", specialBind);

		if (textData.screenCenterX || textData.position == null)
		{
			textObject.screenCenter(X);
			textObject.x = Math.round(textObject.x);
		}
		else
			textObject.x = textData.position[0];

		if (textData.screenCenterY || textData.position == null)
		{
			textObject.screenCenter(Y);
			textObject.y = Math.round(textObject.y);
		}
		else
			textObject.y = textData.position[1];

		if (textData.position == null)
			textObject.x = 60;

		if (textObject != mainText)
			extraTextGroup.add(textObject);
	}

	/**
		I don't recall why I did this in a function rather than on initialization

		But I suppose it keeps the top from being too full? I'll keep it for now but know I don't have a better answer for why I did it this way.
	**/
	public function fillTextMap():Void
	{
		// Just leaving this one as an example of how to use this function
		textMap = [
			'Unblockable As Parry Telegraph' => 'LIMITS OF BLOCKING
					Blocking enemy attacks is more restrictive than hitting a normal note by design.
					Where a normal singing note allows for a late response, an attack concludes immediately once executed.

					Due to the lack of a late timing, blocking dense waves of attacks in faster songs manually can be infeasible.
					This case is where parry\'s all guard benefit helps greatly.

					UNBLOCKABLE AS PARRY TELEGRAPH
					Since unblockable notes must be parried, they can be used to telegraph a good place to parry in a song.

					While nothing prevents parrying normal attacks to stay safe,
					Some charts may use unblockable notes as a visual indicator of when a safe time to parry would be.
					',

		];
	}

	public static function songHasTutorial():Bool
	{
		var json:TutorialListData = parseJson();

		var foundSong:Bool = false;
		for (page in json.tutorial_song_pages)
		{
			if (json.check_all_difficulties_for_tutorial.contains(Song.jsonName)
				&& !json.all_difficulties_check_exceptions.contains(Song.jsonFullName)
				&& page.song == Song.jsonFullName)
			{
				foundSong = true;
			}
			else if (Song.jsonFullName == Song.jsonName && page.song == Song.jsonName)
			{
				foundSong = true;
			}

			if (foundSong)
			{
				break;
			}
		}

		return foundSong;
	}

	/**
	 * Returns a parsed json from the input path.
	 * 
	 * This function returns a Dynamic due to it being used to parse multiple different json typedefs.
	 * 
	 * Making separate functions to account for this issue somewhat defeats the purpose of this centralized function, so just be forewarned that parsing the wrong json won't be caught in the compiler here
	 *
	 * @param tutorialPath Defaults to tutorialList since it's currently what this function's called to parse mostly
	 */
	public static function parseJson(tutorialPath:String = 'tutorials/tutorialList.json'):Dynamic
	{
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(tutorialPath);
		if (!FileSystem.exists(path))
		{
			path = Paths.getPreloadPath(tutorialPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(tutorialPath);
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getPreloadPath('tutorials/Fundamentals.json'); // Crash prevention attempt
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end

		return cast Json.parse(rawJson);
	}

	override function destroy()
	{
		if (tutorialMusic != null)
			tutorialMusic.destroy();

		super.destroy();
	}
}
