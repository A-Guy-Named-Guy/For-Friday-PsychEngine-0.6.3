package;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.Lib;
#if windows
import llua.Lua;
#end

class VictoryResultSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<FlxText>;

	var song:String = null;
	var menuItems:Array<String> = ['Continue', 'Restart Song'];
	var curSelected:Int = 0;
	var endSong:Void->Void;

	var continueToMainMenu:Bool = false;

	var pauseMusic:FlxSound;

	public function new(x:Float, y:Float, song:String, difficulty:Int = 0, endSong:Void->Void)
	{
		super();

		this.song = song;
		this.endSong = endSong;

		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		var victoryTypeText:FlxText = new FlxText(0, 20, 0, "", 32);
		if (Combat.combatVictory)
			victoryTypeText.text += "Combat";
		else
			victoryTypeText.text += "Singing";
		victoryTypeText.text += " Victory Achieved";
		victoryTypeText.scrollFactor.set();
		victoryTypeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		victoryTypeText.updateHitbox();
		add(victoryTypeText);
		victoryTypeText.screenCenter(X);

		victoryTypeText.alpha = 0;

		grpMenuShit = new FlxTypedGroup<FlxText>();
		add(grpMenuShit);

		var victoryMedal:FlxSprite = new FlxSprite(0, (victoryTypeText.y + victoryTypeText.height + 10));
		victoryMedal.loadGraphic(Paths.image('victoryMedal'), true, 170, 180);
		victoryMedal.antialiasing = true;

		/*
			if (Combat.combatVictory)
			{
				switch (difficulty)
				{
					case 0:
						victoryMedal.animation.add('token', [6], 0, false);
					case 1:
						victoryMedal.animation.add('token', [7], 0, false);
					case 2:
						victoryMedal.animation.add('token', [8], 0, false);
				}
			}
			else
			{
				switch (difficulty)
				{
					case 0:
						victoryMedal.animation.add('token', [1], 0, false);
					case 1:
						victoryMedal.animation.add('token', [2], 0, false);
					case 2:
						victoryMedal.animation.add('token', [3], 0, false);
				}
		}*/

		// For reasons I cannot fathom the above plays the completely wrong frames in a pattern that I cannot figure out what the hell it's doing
		// This following fix is dumb and brings in an uneeded XML but fuck it, I've been stumped on a cleaner approach for like an hour, I'm moving on
		victoryMedal.frames = Paths.getSparrowAtlas('victoryMedal');
		victoryMedal.animation.addByPrefix('medal', 'victoryMedal idle', 0);
		victoryMedal.animation.play('medal', false, false, difficulty += Combat.combatVictory ? 7 : 2);

		victoryMedal.scrollFactor.set();
		add(victoryMedal);
		victoryMedal.screenCenter(X);

		var infoText:FlxText = new FlxText(0, (victoryMedal.y + victoryMedal.height + 10), (FlxG.width - 20), "", 32);

		if (Combat.needCombatVictory.contains(song))
		{
			infoText.text += "A combat victory is required to advance.";
			if (!Combat.combatVictory)
				this.continueToMainMenu = true;
		}

		infoText.text += "\nContinue with this victory?";
		infoText.scrollFactor.set();
		infoText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		infoText.updateHitbox();
		add(infoText);

		infoText.alpha = 0;
		infoText.screenCenter(X);

		for (i in 0...menuItems.length)
		{
			// var menuText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			var menuText:FlxText = new FlxText(0, 0, 0, menuItems[i], 32);
			menuText.scrollFactor.set();
			menuText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			menuText.updateHitbox();
			menuText.screenCenter();
			menuText.y += ((menuText.height + 10) * i);

			menuText.alpha = 0;

			// Since this tweening effect occurs far after the changeSelection() function,
			// This check is to ensure the alpha values indicating which is selected is correct
			// Using the tween function as usual causes all options to be set to alpha 1
			if (i == 0)
				FlxTween.tween(menuText, {alpha: 1, y: menuText.y + 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			else
				FlxTween.tween(menuText, {alpha: 0.6, y: menuText.y + 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});

			grpMenuShit.add(menuText);
		}

		FlxTween.tween(victoryTypeText, {alpha: 1, y: victoryTypeText.y + 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(victoryMedal, {alpha: 1, y: victoryMedal.y + 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(infoText, {alpha: 1, y: infoText.y + 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		var upPcontroller:Bool = false;
		var downPcontroller:Bool = false;

		if (controls.UI_UP_P || upPcontroller)
		{
			changeSelection(-1);
		}
		else if (controls.UI_DOWN_P || downPcontroller)
		{
			changeSelection(1);
		}

		if (controls.ACCEPT)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Continue":
					// The storyPlaylist purge is for the sake of mimicking this behavior in PlayState, as this was how song changes were handled in the original song-end function
					if (continueToMainMenu)
						while (PlayState.storyPlaylist.length > 1)
							PlayState.storyPlaylist.remove(PlayState.storyPlaylist[0]);

					endSong();
				/*trace(daSelected);
					if (continueToMainMenu)
					{
						if (PlayState.instance.useVideo)
						{
							GlobalVideo.get().stop();
							PlayState.instance.remove(PlayState.instance.videoSprite);
							PlayState.instance.removedVideo = true;
						}
						#if windows
						if (PlayState.luaModchart != null)
						{
							PlayState.luaModchart.die();
							PlayState.luaModchart = null;
						}
						#end

						if (FlxG.save.data.scoreScreen)
						{
							FlxG.state.closeSubState();
							FlxG.state.openSubState(new ResultsScreen());
						}
						else
							FlxG.switchState(new MainMenuState());
					}
					else
						LoadingState.loadAndSwitchState(new PlayState()); */

				case "Restart Song":
					FlxG.resetState();
			}
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		for (item in grpMenuShit.members)
			item.alpha = 0.6;

		grpMenuShit.members[curSelected].alpha = 1;
	}
}
