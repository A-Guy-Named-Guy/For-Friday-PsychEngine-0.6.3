package;

import flixel.FlxG;
import flixel.FlxSprite;

/**
 * Used for FreeplayState.
 * Also sources functions for storing data of achieved victories
 */
class VictoryControl extends FlxSprite
{
	#if (haxe >= "4.0.0")
	public static var singVictoryMap:Map<String, Int> = new Map();
	public static var combatVictoryMap:Map<String, Int> = new Map();
	#else
	public static var singVictoryMap:Map<String, Int> = new Map<String, Int>();
	public static var combatVictoryMap:Map<String, Int> = new Map<String, Int>();
	#end

	public var sprTracker:FlxSprite;

	public function new(song:String = 'training', isCombatVictory:Bool = false)
	{
		super();

		loadGraphic(Paths.image('victoryToken'), true, 150, 150);

		antialiasing = true;

		if (isCombatVictory)
		{
			// The order here allows for victories to occur despite being displayed as "impossible",
			// The idea being this allows the case where a seemingly impossible combat is triumphed over
			if (combatVictoryMap.exists(song))
			{
				switch (combatVictoryMap.get(song))
				{
					case 0:
						animation.add('token', [7], 0, false);
					case 1:
						animation.add('token', [8], 0, false);
					case 2:
						animation.add('token', [9], 0, false);
					case 3:
						animation.add('token', [5], 0, false);
				}
			}
			else if (Combat.combatVictoryDisabled.contains(song))
			{
				animation.add('token', [5], 0, false);
			}
			else
				animation.add('token', [6], 0, false);
		}
		else
		{
			// Disabled sing victory takes requirement precedence since it should be enforced in the cases it shows up in
			// Basically the character probably gets killed or the song doesn't end until the opponent's defeated
			if (Combat.singVictoryDisabled.contains(song))
			{
				animation.add('token', [0], 0, false);
			}
			else if (singVictoryMap.exists(song))
			{
				switch (singVictoryMap.get(song))
				{
					case 0:
						animation.add('token', [2], 0, false);
					case 1:
						animation.add('token', [3], 0, false);
					case 2:
						animation.add('token', [4], 0, false);
					case 3:
						animation.add('token', [0], 0, false);
				}
			}
			else
				animation.add('token', [1], 0, false);
		}

		animation.play('token');

		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition((sprTracker.x + sprTracker.width) - 10, sprTracker.y);
	}

	static function setVictory(song:String, victory:Int, victoryMap:Map<String, Int>):Void
	{
		if (victoryMap == singVictoryMap)
		{
			singVictoryMap.set(song, victory);
			FlxG.save.data.singVictoryMap = singVictoryMap;
			FlxG.save.flush();
		}
		else if (victoryMap == combatVictoryMap)
		{
			combatVictoryMap.set(song, victory);
			FlxG.save.data.combatVictoryMap = combatVictoryMap;
			FlxG.save.flush();
		}
	}

	public static function saveVictory(song:String, ?diff:Int = 0):Void
	{
		if (singVictoryMap.exists(song))
		{
			if (singVictoryMap.get(song) < diff)
				setVictory(song, diff, singVictoryMap);
		}
		else
			setVictory(song, diff, singVictoryMap);

		if (Combat.combatVictory)
		{
			if (combatVictoryMap.exists(song))
			{
				if (combatVictoryMap.get(song) < diff)
					setVictory(song, diff, combatVictoryMap);
			}
			else
				setVictory(song, diff, combatVictoryMap);
		}
	}

	public static function loadVictories():Void
	{
		trace(singVictoryMap);
		trace(FlxG.save.data.singVictoryMap);
		if (FlxG.save.data.singVictoryMap != null)
		{
			singVictoryMap = FlxG.save.data.singVictoryMap;
		}
		if (FlxG.save.data.combatVictoryMap != null)
		{
			combatVictoryMap = FlxG.save.data.combatVictoryMap;
		}
	}
}
