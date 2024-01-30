package;

import flash.text.TextFormat;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

/**
 * A very basic way of using dialogue.
 * Intended pretty much just for the tutorial, as this lacks nuance for multiple characters and such.
 *
 * This copies a lot of the vanilla game methods of handling the dialogue.
 * Pretty much this is all just to try and simplify reimplementing the tutorial dialogue in other engines and projects
 *
 * Also helps that starting from scratch and leaving default dialogue code alone makes things a lot easier
 */
class CombatDialogue extends FlxSpriteGroup
{
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	var box:FlxSprite;
	var boxWidth:Int = 1000;
	var boxHeight:Int = 160;
	var dropBox:FlxSprite;

	public var displayGroup = new FlxTypedGroup<FlxSprite>();

	var curCharacter:String = '';
	var tutorialScreen:String = '';
	var isEnding:Bool = false;

	var dialogueCounter:Int = 0;
	var dialogueList:Array<String> = [];

	public static var songDialogueExclusions:Array<String> = ['trial-hard', 'dominion-hard', 'dominion-reversal-hard'];
	public static var songDialogueMap:Map<String, Array<String>> = [
		'training' => [
			'Hello! This is A Guy Named Guy, presenting the For Friday combat system!',
			'Each song will start with a screen describing what mechanics, concepts, characters, etc. will be introduced. 
			You can always check the song-specific info along with all other tutorial screens in the "Help" option of the pause menu.',
			'The full fundamentals will be presented, but know that defeating the opponent is optional for this song. Feel free to experiment and figure out how things work!'
		],
		'trial' => [
			'You survived! Well done!',
			'Now that you (hopefully) understand how blocking and attacking works, we\'re upping the ante with a wider offense to defend against.',
			'Simply put: Press down defend against blue down attacks, and attack before blocking orange attacks to parry. The tutorial screen following this will give some details, of course, but that\'s the gist.',
			'This time, you must defeat me to progress to the next song, so buck up and get ready!'
		],
		'dominion' => [
			'You have learned well. It is time to apply that knowledge to a final test.',
			'The scrolling arrows are a courtesy I will extend no longer. For this is no longer a battle of words and prose.',
			'Now, we fight for honor.'
		],
		'training-easy' => [
			'Hello! It seems you have chosen the easy difficulty.',
			'Songs that involve enough singing to justify it are encouraged to reserve the "easy" difficulty as the mode to pick for playing with combat mechanics disabled.',
			'Therefore, if your only interest is vanilla gameplay, you\'re in the right place! Otherwise, the core content is Normal difficulty and higher.',
			'I\'ll let you go here. Good luck!'
		],
		'trial-easy' => [
			'Hey there, one more heads up before we start!',
			'Due to combat mechanics being disabled, the final song is inaccessible since a combat victory is not possible.',
			'The song Dominion has long absences of singing, so lacking combat would make the song pretty boring.',
			'Do know that you still have the option to try Dominion on easy in Freeplay! There\'s a gameplay difference that makes the song quite a bit easier',
			'That\'ll be all for now. Good luck!'
		],
		'training-hard' => [
			'Hello, and welcome to hell!',
			'Hard mode is no ordinary difficulty adjustment! For this tutorial your chart is largely the same between Normal and Hard, but rest assured, things will be much more painful indeed.',
			'If you haven\'t yet completed Normal mode and gotten to grips with the mechanics, I strongly advise that you DO NOT continue. Tutorials for fundamentals, basic controls and the like will be skipped.',
			'This is all I will tell you from here. You\'re on your own now.'
		],
		'training-reverse' => [
			'Hello! This A Guy Named Guy, presenting an alternate character!',
			'I\'ll be serving as a placeholder-character for how an alternative play-style would look like. I strongly encourage that you complete Boyfriend\'s week first if you haven\'t already, as the fundamentals will be skipped for brevity.',
			'Furthermore, my offense approach is much less direct. You\'ll need to attack and defend regularly to force an opening. Once that yellow bar\'s full, attacks will break through guards, and a bash-to-attack followup will deal a critical blow!',
			'Like Boyfriend\'s week, use this as a chance to get to grips with things. Good luck!'
		],
		'trial-reverse' => [
			'And thus you\'ve triumphed! Fantastic work!',
			'Now be careful, for Boyfriend\'s down-special attack will work quite differently: Instead of bashing, he will heal health and posture. Only a bash will interrupt this move.',
			'Keep in mind your defensive moves as well! Not only can bashes make a great utility for stopping an attack flurry thanks to its stun, but parrying too gives you a window to auto-block incoming attacks.',
			'Perilous combat awaits thee, and only victory will grant passage to the final battle. To arms!'
		],
		'dominion-reversal' => [
			'You\'ve made it this far. The final trial awaits.',
			'Do not be fooled by the smug demeanor of the one before you. He will show no mercy.',
			'His aggression will be his downfall. Stand fast against the flurry of blows and punish him rightly on his falter.',
			'Let\'s do this.'
		],
		'training-reverse-easy' => [
			'Hello there! Welcome to easy mode, Shrub edition!',
			'I\'m just here to let you know that yours truly has no functional differences with combat disabled. Pretty much just the same thing as BF.',
			'That\'s pretty much all I\'ve got. I wish you luck!'
		],
		'trial-reverse-easy' => [
			'Hey hey hey, it\'s me again! One thing left to clear up',
			'The final song is not accessible without combat enabled. It\'s a bit of an underwhelming song without it. But hey, you can check it out in Freeplay on easy if you wish!',
			'And hey, while you\'re here, I\'ll throw you a bit of trivia: The third song, "Dominion", was ORIGINALLY going to inspired by the song from the For Honor OST "Hymn of The Walled City".',
			'A musically-inclined friend of mine had to help me out with figuring out that the drum beat of the Hymn was actually triplets, or three beats per measure instead of four.',
			'It makes for quite a unique beat! But, unfortunately FnF\'s native charting doesn\'t support different time signatures very well, so I figured charting on 4/4 time with essentially a 3/4 beat wouldn\'t quite mesh.',
			'Trust me, charting a 3/4 song is a headache. So, instead I based it off of "Adversarii Ad Portas" instead, which turned Dominion into a much more somber and dire sort of song.',
			'Dominion\'s much slower pace also inspired the faster-paced remix of Dominion-Reversal, which I quite like over the original. Makes for an interesting singing-chart on bf\'s side too.',
			'Do check out Dominion-Reversal-Reversed\'s easy chart in Freeplay for a nice little vanilla time. Good luck on this song in the meantime!'
		],
		'training-reverse-hard' => [
			'Hello there! Seems you picked Hard mode! Unquestionably one of the choices of all time.',
			'Greater challenge awaits thee, no doubt, but this time around there\'s a bit of extra mechanical demand.',
			'It\'ll become more relevant in Trial next stage, but what I\'ll say is this: If notes are getting too dense to block, parry or bash! Stops offense right in its tracks!',
			'Go ahead and experiment with that for now. You\'ll need to make thorough use of it later. Good luck.'
		],
		'trial-reverse-hard' => [
			'One down, two to go.',
			'Like in Normal, combat victory is required as usual for the third song. And for surviving this one? Remember: Parry, and bash.',
			'You\'ve likely grown accustomed to blocking\'s idiosyncracies compared to hitting normal singing notes. Short note there is that blocking lacks any leeway once the note has ocurred.',
			'This means that dense packs of notes in faster songs are going to be incredibly difficult, if not impossible to block individually.',
			'Thus, this is why parrying is a fantastic tool, as it lets you block a section automatically. Bashing serves a similar function as well',
			'Enough beating around the bush, here goes nothing. To arms!'
		]
	];

	var spriteMap:Map<String, Array<String>> = [
		'training' => ['hi', 'here', 'hi'],
		'trial' => ['hi', 'here', 'hi', 'triumph'],
		'dominion' => ['serious', 'serious', 'getReady'],
		'training-easy' => ['hi', 'here', 'hi'],
		'trial-easy' => ['hi', 'here', 'hi', 'triumph', 'hi'],
		'training-hard' => ['hi', 'here', 'hi', 'triumph'],
		'training-reverse' => ['hi', 'hi', 'here', 'hi'],
		'trial-reverse' => ['triumph', 'hi', 'here', 'triumph'],
		'dominion-reversal' => ['serious', 'serious', 'getReady'],
		'training-reverse-easy' => ['hi', 'here', 'hi'],
		'trial-reverse-easy' => ['hi', 'here', 'hi'],
		'training-reverse-hard' => ['hi', 'hi', 'here', 'hi'],
		'trial-reverse-hard' => ['triumph', 'hi', 'here', 'hi', 'here', 'triumph']
	];
	var bg:FlxSprite;
	var portrait:FlxSprite;

	var curSong:String;
	var swagDialogue:FlxTypeText;
	var dialogueFormat:TextFormat;
	var textSkipText:FlxText;
	var attackBind:String = ClientPrefs.keyBinds.get('attack')[0];

	static var dialogueSong:String = 'training';

	public var finishThing:Void->Void;
	public var pauseThing:Void->Void;
	public var unpauseThing:Void->Void;
	public var enableCombat:Void->Void;

	var constructorX:Float = 0;
	var constructorY:Float = 0;

	public function new(x:Float, y:Float, curSong:String, storyDifficulty:Int)
	{
		super();

		// Deprecated by dialogueSong after optimizing the dynamics of songs with different suffixes
		// Leaving it here in case the song itself needs to be referenced for something later down the line
		this.curSong = curSong;

		// boyfriend is private now,
		// And although I don't think the PauseSubState needs this info in anyway,
		// It asks for it, and for the sake of consistency this information is transferred down the line in case its ever necessary
		constructorX = x;
		constructorY = y;

		switch (Song.jsonName)
		{
			case 'dominion':
				FlxG.sound.playMusic(Paths.inst('dominion'), 0);
			case 'dominion-reversal':
				FlxG.sound.playMusic(Paths.inst('dominion'), 0);
			default:
				FlxG.sound.playMusic(Paths.music('tutorialMenu'), 0);
		}
		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeIn(1, 0, 0.8);

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();

		dialogueList = songDialogueMap.get(Song.jsonFullName);

		portrait = new FlxSprite(0, 0);
		portrait.frames = Paths.getSparrowAtlas('characters/shrubDialogue');
		portrait.antialiasing = true;
		portrait.animation.addByPrefix('hi', 'shrubDialogue hi', 0);
		portrait.animation.addByPrefix('here', 'shrubDialogue here', 0);
		portrait.animation.addByPrefix('triumph', 'shrubDialogue triumph', 0);
		portrait.animation.addByPrefix('serious', 'shrubDialogue serious', 0);
		portrait.animation.addByPrefix('getReady', 'shrubDialogue getReady', 0);

		portrait.animation.play('hi');

		animateDialogueSprite();

		// No particular reason for stuff being divisible by 8,
		// just figured I ought to go all the way when 24 font + 8 leading looked pretty good
		boxWidth = 1024;
		// The 4 represents the line number,
		// the text size (24) plus 8 leading (line spacing) equals total height of each line,
		// and the 16 adds 8 pixels leeway top and bottom.
		boxHeight = (32 * 4 + 16);
		box = new FlxSprite(125, 475).makeGraphic(boxWidth, boxHeight, FlxColor.WHITE);
		dropBox = new FlxSprite(box.x - 10, box.y - 5).makeGraphic(boxWidth + 10, boxHeight + 10, FlxColor.BLACK);
		textSkipText = new FlxText(145, box.y + box.height + 8, 960, '(Press ATTACK ($attackBind) to skip to start of song.)', 16);
		textSkipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		displayGroup.add(bg);
		displayGroup.add(portrait);
		displayGroup.add(textSkipText);
		displayGroup.add(dropBox);
		displayGroup.add(box);
		displayGroup.forEach(function(spr:FlxSprite)
		{
			// For some reason adding displayGroup wasn't working so add(spr) is a compromise
			add(spr);
			spr.updateHitbox();
			spr.screenCenter(X);
			if (spr == bg)
				FlxTween.tween(bg, {alpha: 0.6}, 1, {ease: FlxEase.quartInOut});
			else
				FlxTween.tween(spr, {alpha: 1}, 2, {ease: FlxEase.quartInOut});
		});
		// This increases the line spacing of the text
		// Trust me, this wasn't a simple value to figure out how to change
		dialogueFormat = new TextFormat();
		dialogueFormat.leading = 8;
		swagDialogue = new FlxTypeText(box.x + 20, box.y + 10, boxWidth - 20, "", 24);
		swagDialogue.textField.defaultTextFormat = dialogueFormat;
		swagDialogue.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		swagDialogue.finishSounds = true;
		add(swagDialogue);
		displayGroup.add(swagDialogue);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;
	var dialogueFinished:Bool = false;

	override function update(elapsed:Float)
	{
		if (box.alpha == 1)
			dialogueOpened = true;
		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}
		if (controls.ACCEPT && dialogueStarted)
		{
			if (dialogueFinished)
			{
				dialogueFinished = false;
				FlxG.sound.play(Paths.sound('clickText'), 0.8);
				if (dialogueList[dialogueCounter + 1] == null)
					endDialogue();
				else
				{
					dialogueCounter += 1;
					startDialogue();
				}

				animateDialogueSprite();
			}
			else
				swagDialogue.skip();
		}
		if (controls.ATTACK_P)
			endDialogue();
		super.update(elapsed);
	}

	function startDialogue():Void
	{
		swagDialogue.resetText(dialogueList[dialogueCounter]);
		swagDialogue.start(0.02, true, false, [], function()
		{
			dialogueFinished = true;
		});
	}

	public function endDialogue():Void
	{
		isEnding = true;
		displayGroup.forEach(function(spr:FlxSprite)
		{
			FlxTween.tween(spr, {alpha: 0}, 0.5, {
				ease: FlxEase.quartInOut,
				onComplete: function(twn:FlxTween)
				{
					if (isEnding)
					{
						// The extra finishThing() else check is needed since the positioning of pauseThing() and finishThing() are very particular to make this work
						//
						// openSubState after pauseThing crashes since PlayState openSubState() override calls for startTimer, which is not set until finishThing() calls startCountdown()
						// pauseThing() and finishThing() after openSubState() doesn't crash but the start countdown begins early during the tutorial screen
						//
						// Finally, the purpose of that else finishThing() at all is for the sake of pauseThing not being called when there's no tutorial
						// If pauseThing is performed, the game unpauses, but something breaks and the wrong song gets played. The charting also seems to break on top of that.
						//
						// Point is: Order matters. If you really want to fix that redundant finishThing then start with making a != null check on startTimer in startCountdown()
						if (TutorialSubState.songHasTutorial())
						{
							pauseThing();
							finishThing();
							FlxG.state.openSubState(new TutorialSubState(constructorX, constructorY, Song.jsonName, 'CombatDialogue'));
						}
						else
						{
							finishThing();
							FlxG.sound.music.fadeOut(0.5, 0);
						}

						enableCombat();
						kill();

						isEnding = false;
					}
				}
			});
		});
	}

	function animateDialogueSprite():Void
	{
		var animationArray:Array<String> = spriteMap.get(dialogueSong);

		if (animationArray != null)
			portrait.animation.play(animationArray[dialogueCounter]);
	}

	/**
		Returns true if the full json name exists in the dialogue map, or if the non-difficulty altered json name exists.

		If the song is present in the exclusion array, this will return false. Useful for disabling on hard or easy versions.
	**/
	public static function evaluateDialogueExists():Bool
	{
		var returnBool:Bool = false;

		if (songDialogueMap.exists(Song.jsonFullName))
		{
			dialogueSong = Song.jsonFullName;
			returnBool = true;
		}
		else if (songDialogueMap.exists(Song.jsonName))
		{
			dialogueSong = Song.jsonName;
			returnBool = true;
		}

		if (songDialogueExclusions.contains(Song.jsonFullName))
			returnBool = false;

		return returnBool;
	}
}
