package options;

#if desktop
import Discord.DiscordClient;
#end
import Controls;
import flash.text.TextField;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;

using StringTools;

class ControlsSubState extends MusicBeatSubstate
{
	private static var curSelected:Int = 1;
	private static var curAlt:Bool = false;

	private static var defaultKey:String = 'Reset to Default Keys';

	private var bindLength:Int = 0;

	var optionShit:Array<Dynamic> = [
		['NOTES'], ['Left', 'note_left'], ['Down', 'note_down'], ['Up', 'note_up'], ['Right', 'note_right'], [''], ['GUARD KEYS'],
		['Press / to match "NOTES"'], ['Left', 'guard_left'], ['Dodge', 'guard_down'], ['Up', 'guard_up'], ['Right', 'guard_right'], [''], ['ATTACKS'],
		['Attack', 'attack'], ['Special', 'special'], [''], ['UI'], ['Left', 'ui_left'], ['Down', 'ui_down'], ['Up', 'ui_up'], ['Right', 'ui_right'], [''],
		['Reset', 'reset'], ['Accept', 'accept'], ['Back', 'back'], ['Pause', 'pause'], [''], ['VOLUME'], ['Mute', 'volume_mute'], ['Up', 'volume_up'],
		['Down', 'volume_down'], [''], ['DEBUG'], ['Key 1', 'debug_1'], ['Key 2', 'debug_2']];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var grpInputs:Array<AttachedText> = [];
	private var grpInputsAlt:Array<AttachedText> = [];
	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		optionShit.push(['']);
		optionShit.push([defaultKey]);

		for (i in 0...optionShit.length)
		{
			var isCentered:Bool = false;
			var isDefaultKey:Bool = (optionShit[i][0] == defaultKey);
			if (unselectableCheck(i, true))
			{
				isCentered = true;
			}

			var optionText:Alphabet = new Alphabet(200, 300, optionShit[i][0], (!isCentered || isDefaultKey));
			optionText.isMenuItem = true;
			if (isCentered)
			{
				optionText.screenCenter(X);
				optionText.y -= 55;
				optionText.startPosition.y -= 55;
			}
			optionText.changeX = false;
			optionText.distancePerItem.y = 60;
			optionText.targetY = i - curSelected;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if (!isCentered)
			{
				addBindTexts(optionText, i);
				bindLength++;
				if (curSelected < 0)
					curSelected = i;
			}
		}
		changeSelection();
	}

	var leaving:Bool = false;
	var bindingTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (!rebindingKey)
		{
			if (controls.UI_UP_P)
			{
				changeSelection(-1);
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(1);
			}
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
			{
				changeAlt();
			}

			if (controls.BACK)
			{
				ClientPrefs.reloadControls();
				close();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if (controls.ACCEPT && nextAccept <= 0)
			{
				if (optionShit[curSelected][0] == defaultKey)
				{
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
					reloadKeys();
					changeSelection();
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				else if (!unselectableCheck(curSelected))
				{
					bindingTime = 0;
					rebindingKey = true;
					if (curAlt)
					{
						grpInputsAlt[getInputTextNum()].alpha = 0;
					}
					else
					{
						grpInputs[getInputTextNum()].alpha = 0;
					}
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			}

			// Combat change
			// A quality-of-life feature to force-bind guard keys to notes
			// One could question why guard keys have their own inputs in the first place,
			// And honestly, they're not entirely necessary, but I figure having the option is nice for some kind of challenge run or something
			if (FlxG.keys.justPressed.SLASH)
			{
				ClientPrefs.keyBinds.set('guard_left', ClientPrefs.keyBinds.get('note_left'));
				ClientPrefs.keyBinds.set('guard_down', ClientPrefs.keyBinds.get('note_down'));
				ClientPrefs.keyBinds.set('guard_up', ClientPrefs.keyBinds.get('note_up'));
				ClientPrefs.keyBinds.set('guard_right', ClientPrefs.keyBinds.get('note_right'));

				reloadKeys();
				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
		}
		else
		{
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1)
			{
				// Combat change
				// Replace the keysArray:Array with... well, this
				//
				// Okay
				// Buckle the fuck up,
				// And let me explain
				//
				// There is a very, VERY good reason this horseshit was written, and I'm gonna explain to you e x a c t l y why
				//
				// This whole sequence has to do with that feature up above: When you press SLASH, it copies the note keys to the guard keys
				// Easiest dub of the century, right?
				// You stupid bastard
				// What were you thinking?
				// No
				//
				// Jokes aside, this pretty basic feature caused a mind-bogglingly confusing bug that took like three days to investigate (and spoiler: I don't have a clear answer)
				// After copying the inputs over, erroneously, causes any change to one of the two keybinds to force-match the other
				// This would persist until either keys were reset to defaults or the game was restarted. State changes don't work.
				// Here's where it gets weird
				//
				// You see that ClientPrefs.keyBinds.set() function down there?
				// Yeah that does effectively nothing.
				// Somehow, it's at the keysArray = keyPressed line that any key rebinds happen, somehow occuring several lines before an actual set to the keybinds map
				// You can delete that set and keybinds function perfectly normally.
				//
				// Viewing the callstack reveals nothing about any other functions being run that set the map in any way. Somehow, assignments only occur on this keysArray
				// So why all this extra dumb code?
				//
				// Basically, I can only attribute this to some spaghetti in the backend of how maps work, which can't be viewed to check what's going on (to my knowledge)
				// My reasoning behind this is that keysArray is like, establishing itself as the value of the input, rather than temporarily storing the data.
				// And retrieving the data for, say, 'note_left' to copy to 'guard_left' somehow makes its Array<FlxKey> the same.
				//
				// This all fixes that by turning keysArray into something isolated from that strange referencing mixup,
				// as it gets the data needed through some steps obfuscating the real origin of the data.
				//
				// All that make sense?
				// Of course it doesn't.
				// Just trust me on this. If you add the SLASH copy feature, test to make sure changing inputs afterwards doesn't have strange behavior.
				// I'd frankly be relieved if some kind of library setup ends up never having this problem in the first place.
				//
				// var keysArray:Array<FlxKey> = ClientPrefs.keyBinds.get(optionShit[curSelected][1]);
				var copyBugBypassArray:Array<FlxKey> = ClientPrefs.keyBinds.get(optionShit[curSelected][1]);
				var defaultDummyKey:FlxKey = copyBugBypassArray[curAlt ? 0 : 1];
				var keysArray:Array<FlxKey> = [
					(curAlt ? defaultDummyKey : copyBugBypassArray[0]),
					(curAlt ? copyBugBypassArray[1] : defaultDummyKey)
				];
				// End of changes
				keysArray[curAlt ? 1 : 0] = keyPressed;

				var opposite:Int = (curAlt ? 0 : 1);
				if (keysArray[opposite] == keysArray[1 - opposite])
				{
					keysArray[opposite] = NONE;
				}
				ClientPrefs.keyBinds.set(optionShit[curSelected][1], keysArray);

				reloadKeys();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				rebindingKey = false;
			}

			bindingTime += elapsed;
			if (bindingTime > 5)
			{
				if (curAlt)
				{
					grpInputsAlt[curSelected].alpha = 1;
				}
				else
				{
					grpInputs[curSelected].alpha = 1;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
				rebindingKey = false;
				bindingTime = 0;
			}
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}

		super.update(elapsed);
	}

	function getInputTextNum()
	{
		var num:Int = 0;
		for (i in 0...curSelected)
		{
			if (optionShit[i].length > 1)
			{
				num++;
			}
		}
		return num;
	}

	function changeSelection(change:Int = 0)
	{
		do
		{
			curSelected += change;
			if (curSelected < 0)
				curSelected = optionShit.length - 1;
			if (curSelected >= optionShit.length)
				curSelected = 0;
		}
		while (unselectableCheck(curSelected));

		var bullShit:Int = 0;

		for (i in 0...grpInputs.length)
		{
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length)
		{
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
					if (curAlt)
					{
						for (i in 0...grpInputsAlt.length)
						{
							if (grpInputsAlt[i].sprTracker == item)
							{
								grpInputsAlt[i].alpha = 1;
								break;
							}
						}
					}
					else
					{
						for (i in 0...grpInputs.length)
						{
							if (grpInputs[i].sprTracker == item)
							{
								grpInputs[i].alpha = 1;
								break;
							}
						}
					}
				}
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeAlt()
	{
		curAlt = !curAlt;
		for (i in 0...grpInputs.length)
		{
			if (grpInputs[i].sprTracker == grpOptions.members[curSelected])
			{
				grpInputs[i].alpha = 0.6;
				if (!curAlt)
				{
					grpInputs[i].alpha = 1;
				}
				break;
			}
		}
		for (i in 0...grpInputsAlt.length)
		{
			if (grpInputsAlt[i].sprTracker == grpOptions.members[curSelected])
			{
				grpInputsAlt[i].alpha = 0.6;
				if (curAlt)
				{
					grpInputsAlt[i].alpha = 1;
				}
				break;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	private function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool
	{
		if (optionShit[num][0] == defaultKey)
		{
			return checkDefaultKey;
		}
		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey;
	}

	private function addBindTexts(optionText:Alphabet, num:Int)
	{
		var keys:Array<Dynamic> = ClientPrefs.keyBinds.get(optionShit[num][1]);
		var text1 = new AttachedText(InputFormatter.getKeyName(keys[0]), 400, -55);
		text1.setPosition(optionText.x + 400, optionText.y - 55);
		text1.sprTracker = optionText;
		grpInputs.push(text1);
		add(text1);

		var text2 = new AttachedText(InputFormatter.getKeyName(keys[1]), 650, -55);
		text2.setPosition(optionText.x + 650, optionText.y - 55);
		text2.sprTracker = optionText;
		grpInputsAlt.push(text2);
		add(text2);
	}

	function reloadKeys()
	{
		while (grpInputs.length > 0)
		{
			var item:AttachedText = grpInputs[0];
			item.kill();
			grpInputs.remove(item);
			item.destroy();
		}
		while (grpInputsAlt.length > 0)
		{
			var item:AttachedText = grpInputsAlt[0];
			item.kill();
			grpInputsAlt.remove(item);
			item.destroy();
		}

		trace('Reloaded keys: ' + ClientPrefs.keyBinds);

		for (i in 0...grpOptions.length)
		{
			if (!unselectableCheck(i, true))
			{
				addBindTexts(grpOptions.members[i], i);
			}
		}

		var bullShit:Int = 0;
		for (i in 0...grpInputs.length)
		{
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length)
		{
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
					if (curAlt)
					{
						for (i in 0...grpInputsAlt.length)
						{
							if (grpInputsAlt[i].sprTracker == item)
							{
								grpInputsAlt[i].alpha = 1;
							}
						}
					}
					else
					{
						for (i in 0...grpInputs.length)
						{
							if (grpInputs[i].sprTracker == item)
							{
								grpInputs[i].alpha = 1;
							}
						}
					}
				}
			}
		}
	}
}
