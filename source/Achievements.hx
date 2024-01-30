import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

class Achievements
{
	// Combat changes
	// New cheevos bb
	/*public static var achievementsStuff:Array<Dynamic> = [ //Name, Description, Achievement save tag, Hidden achievement
			["Freaky on a Friday Night",	"Play on a Friday... Night.",						'friday_night_play',	 true],
			["She Calls Me Daddy Too",		"Beat Week 1 on Hard with no Misses.",				'week1_nomiss',			false],
			["No More Tricks",				"Beat Week 2 on Hard with no Misses.",				'week2_nomiss',			false],
			["Call Me The Hitman",			"Beat Week 3 on Hard with no Misses.",				'week3_nomiss',			false],
			["Lady Killer",					"Beat Week 4 on Hard with no Misses.",				'week4_nomiss',			false],
			["Missless Christmas",			"Beat Week 5 on Hard with no Misses.",				'week5_nomiss',			false],
			["Highscore!!",					"Beat Week 6 on Hard with no Misses.",				'week6_nomiss',			false],
			["God Effing Damn It!",			"Beat Week 7 on Hard with no Misses.",				'week7_nomiss',			false],
			["What a Funkin' Disaster!",	"Complete a Song with a rating lower than 20%.",	'ur_bad',				false],
			["Perfectionist",				"Complete a Song with a rating of 100%.",			'ur_good',				false],
			["Roadkill Enthusiast",			"Watch the Henchmen die over 100 times.",			'roadkill_enthusiast',	false],
			["Oversinging Much...?",		"Hold down a note for 10 seconds.",					'oversinging',			false],
			["Hyperactive",					"Finish a Song without going Idle.",				'hype',					false],
			["Just the Two of Us",			"Finish a Song pressing only two keys.",			'two_keys',				false],
			["Toaster Gamer",				"Have you tried to run the game on a toaster?",		'toastie',				false],
			["Debugger",					"Beat the \"Test\" Stage from the Chart Editor.",	'debugger',				 true]
		]; */
	// My VSCode auto-condenses this into this format, so, sorry for not following above
	public static var achievementsStuff:Array<Dynamic> = [
		// Name, Description, Achievement save tag, Hidden achievement
		[
			"That Is How It's Done!",
			"Complete Dominion on Normal or higher",
			'dom_award',
			false
		],
		[
			"Light Spam",
			"Achieve a combat victory on Dominon-Reversal on Hard",
			'dom_rev_hard',
			false
		],
		[
			"Bash On Red",
			"Bash BF out of his final Kill Note\n(Sing victory required, only works on Dominion-Reversal)",
			'kill_note_bash',
			false
		],
		[
			"Recover Tech",
			"Use the recover special after being struck by a bash to clear the stun",
			'recover_tech',
			false
		],
		[
			"Oak Stance",
			"With combat enabled, complete Trial-Reverse without parrying",
			'trial_rev_no_parry',
			false
		],
		[
			"Three Left Guards",
			"Complete any combat song without manually blocking up or right (Switching under Sing Guard is safe!)",
			'who_needs_a_guard',
			false
		],
		[
			"Rappers Die Thrice",
			"When fighting BF, deal cumulative damage across a song that adds up to three times your opponent's health",
			'bf_pain',
			false
		],
		[
			"Rappers' Bones Ache",
			"Spend at least three-quarters of a song at or under half combat health",
			'bf_ache',
			false
		],
		[
			"Beating The Bush",
			"While fighting the Shrub, deal cumulative damage across a song that adds up to twice your opponent's health",
			'shrub_pain',
			false
		]
	];
	// End of changes
	public static var achievementsMap:Map<String, Bool> = new Map<String, Bool>();

	public static var henchmenDeath:Int = 0;

	public static function unlockAchievement(name:String):Void
	{
		FlxG.log.add('Completed achievement "' + name + '"');
		achievementsMap.set(name, true);
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	public static function isAchievementUnlocked(name:String)
	{
		if (achievementsMap.exists(name) && achievementsMap.get(name))
		{
			return true;
		}
		return false;
	}

	public static function getAchievementIndex(name:String)
	{
		for (i in 0...achievementsStuff.length)
		{
			if (achievementsStuff[i][2] == name)
			{
				return i;
			}
		}
		return -1;
	}

	public static function loadAchievements():Void
	{
		if (FlxG.save.data != null)
		{
			if (FlxG.save.data.achievementsMap != null)
			{
				achievementsMap = FlxG.save.data.achievementsMap;
			}
			if (henchmenDeath == 0 && FlxG.save.data.henchmenDeath != null)
			{
				henchmenDeath = FlxG.save.data.henchmenDeath;
			}
		}
	}
}

class AttachedAchievement extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var tag:String;

	public function new(x:Float = 0, y:Float = 0, name:String)
	{
		super(x, y);

		changeAchievement(name);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function changeAchievement(tag:String)
	{
		this.tag = tag;
		reloadAchievementImage();
	}

	public function reloadAchievementImage()
	{
		if (Achievements.isAchievementUnlocked(tag))
		{
			loadGraphic(Paths.image('achievements/' + tag));
		}
		else
		{
			loadGraphic(Paths.image('achievements/lockedachievement'));
		}
		scale.set(0.7, 0.7);
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
			setPosition(sprTracker.x - 130, sprTracker.y + 25);

		super.update(elapsed);
	}
}

class AchievementObject extends FlxSpriteGroup
{
	public var onFinish:Void->Void = null;

	var alphaTween:FlxTween;

	public function new(name:String, ?camera:FlxCamera = null)
	{
		super(x, y);
		ClientPrefs.saveSettings();

		var id:Int = Achievements.getAchievementIndex(name);
		var achievementBG:FlxSprite = new FlxSprite(60, 50).makeGraphic(420, 120, FlxColor.BLACK);
		achievementBG.scrollFactor.set();

		var achievementIcon:FlxSprite = new FlxSprite(achievementBG.x + 10, achievementBG.y + 10).loadGraphic(Paths.image('achievements/' + name));
		achievementIcon.scrollFactor.set();
		achievementIcon.setGraphicSize(Std.int(achievementIcon.width * (2 / 3)));
		achievementIcon.updateHitbox();
		achievementIcon.antialiasing = ClientPrefs.globalAntialiasing;

		var achievementName:FlxText = new FlxText(achievementIcon.x + achievementIcon.width + 20, achievementIcon.y + 16, 280,
			Achievements.achievementsStuff[id][0], 16);
		achievementName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(achievementName.x, achievementName.y + 32, 280, Achievements.achievementsStuff[id][1], 16);
		achievementText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementText.scrollFactor.set();

		add(achievementBG);
		add(achievementName);
		add(achievementText);
		add(achievementIcon);

		var cam:Array<FlxCamera> = FlxCamera.defaultCameras;
		if (camera != null)
		{
			cam = [camera];
		}
		alpha = 0;
		achievementBG.cameras = cam;
		achievementName.cameras = cam;
		achievementText.cameras = cam;
		achievementIcon.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {
			onComplete: function(twn:FlxTween)
			{
				alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
					startDelay: 2.5,
					onComplete: function(twn:FlxTween)
					{
						alphaTween = null;
						remove(this);
						if (onFinish != null)
							onFinish();
					}
				});
			}
		});
	}

	override function destroy()
	{
		if (alphaTween != null)
		{
			alphaTween.cancel();
		}
		super.destroy();
	}
}
