package forfriday;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.Json;
import lime.net.curl.CURLCode;

using StringTools;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

typedef SelectFile =
{
	var characters:Array<CharacterSelectArray>;
	var useCharacterSelect:Bool;
}

typedef CharacterSelectArray =
{
	var name:String;
	var portrait_position:Array<Float>;
	var name_position:Array<Float>;
	var description:String;
}

class CharacterSelectState extends MusicBeatState
{
	var characterArray:Array<String> = [];
	var portraitPositionArray:Array<Array<Float>> = [];
	var namePositionArray:Array<Array<Float>> = [];
	var descriptionArray:Array<String> = [];

	public static var currentSelectedStoryCharacter:String = 'bf';
	public static var characterUnlocked:Array<Bool> = [true, true];

	var characterDescription:FlxText;
	var characterName:FlxSprite;
	var characterPortrait:FlxSprite;
	var curCharacter:Int = 0;
	var grpCharacterText:FlxTypedGroup<FlxSprite>;
	var grpLocks:FlxTypedGroup<FlxSprite>;

	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		grpCharacterText = new FlxTypedGroup<FlxSprite>();
		add(grpCharacterText);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		/*if (!characterUnlocked[i])
			{
				var lock:FlxSprite = new FlxSprite(characterName.width + 10 + characterName.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = true;
				grpLocks.add(lock);
		}*/

		characterDescription = new FlxText(-50, 50, 612, "Bottom Text", 16);

		var json:SelectFile = parseCharacterSelectJson();

		for (character in json.characters)
		{
			characterArray.push(character.name);
			portraitPositionArray.push(character.portrait_position);
			namePositionArray.push(character.name_position);
			descriptionArray.push(character.description);
		}

		characterDescription.text = descriptionArray[curCharacter];

		characterDescription.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		characterDescription.scrollFactor.set();
		characterDescription.x += (FlxG.width - characterDescription.fieldWidth);

		characterName = new FlxSprite(namePositionArray[curCharacter][0], namePositionArray[curCharacter][1],
			Paths.image('characterSelect/' + characterArray[curCharacter] + 'Name'));

		characterPortrait = new FlxSprite(portraitPositionArray[curCharacter][0], portraitPositionArray[curCharacter][1],
			Paths.image('characterSelect/' + characterArray[curCharacter]));

		add(characterDescription);
		add(characterName);
		add(characterPortrait);

		changeCharacter();

		// add(yellowBG);

		super.create();
	}

	override function update(elapsed:Float)
	{
		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpCharacterText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedCharacter)
			{
				var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

				if (gamepad != null)
				{
					if (gamepad.justPressed.DPAD_LEFT)
					{
						changeCharacter(-1);
					}
					if (gamepad.justPressed.DPAD_RIGHT)
					{
						changeCharacter(1);
					}
				}

				if (controls.UI_LEFT_P)
				{
					changeCharacter(-1);
				}

				if (controls.UI_RIGHT_P)
				{
					changeCharacter(1);
				}
			}

			if (controls.ACCEPT)
			{
				selectCharacter();
			}
		}

		if (controls.BACK && !movedBack && !selectedCharacter)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedCharacter:Bool = false;

	function selectCharacter()
	{
		if (characterUnlocked[curCharacter] && !selectedCharacter)
		{
			selectedCharacter = true;

			currentSelectedStoryCharacter = characterArray[curCharacter];

			FlxG.switchState(new StoryMenuState());
		}
	}

	function changeCharacter(change:Int = 0):Void
	{
		curCharacter += change;

		if (curCharacter >= characterArray.length)
			curCharacter = 0;
		if (curCharacter < 0)
			curCharacter = characterArray.length - 1;

		characterName.loadGraphic(Paths.image('characterSelect/' + characterArray[curCharacter] + 'Name'));
		characterPortrait.loadGraphic(Paths.image('characterSelect/' + characterArray[curCharacter]));
		characterDescription.text = descriptionArray[curCharacter];

		characterName.alpha = 0;
		characterPortrait.alpha = 0;
		characterDescription.alpha = 0;

		// characterDescription.x = 618;

		switch (change)
		{
			default:
				characterPortrait.x = portraitPositionArray[curCharacter][0] - 15;
				FlxTween.tween(characterPortrait, {x: characterPortrait.x + 15, alpha: 1}, 0.04);
			case -1:
				characterPortrait.x = portraitPositionArray[curCharacter][0] + 15;
				FlxTween.tween(characterPortrait, {x: characterPortrait.x - 15, alpha: 1}, 0.04);
		}

		characterName.y = namePositionArray[curCharacter][1] + 15;
		FlxTween.tween(characterName, {y: characterName.y - 15, alpha: 1}, 0.04);

		characterDescription.y = 35;
		FlxTween.tween(characterDescription, {y: characterDescription.y + 15, alpha: 1}, 0.04);

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	public static function shouldOpenCharacterSelect():Bool
	{
		var json:SelectFile = parseCharacterSelectJson();

		return json.useCharacterSelect;
	}

	public static function parseCharacterSelectJson():SelectFile
	{
		var arrayPath:String = 'characters/characterSelect/characterArray.json';

		#if MODS_ALLOWED
		var path:String = Paths.modFolders(arrayPath);
		if (!FileSystem.exists(path))
		{
			path = Paths.getPreloadPath(arrayPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(arrayPath);
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getPreloadPath('characters/characterSelect/characterArray.json');
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end

		return cast Json.parse(rawJson);
	}
}
