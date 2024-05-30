package forfriday;

import Character;
import Song.SwagSong;
import flash.geom.Rectangle;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxImageFrame;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import lime.math.Rectangle;
import openfl.geom.Point;

using StringTools;

// I tested switching the extension to just an FlxBasic to make sure there's not a ton of unneeded memory usage. Memory usage seems unchanged
//
// Essentially, the main purpose of extending PlayState in this case is to allow access to private PlayState variables without having to turn them public
// Variables like generatedMusic and healthBarBG probably should be public anyway but it's less engine stuff to have to monkey with
class Combat extends PlayState
{
	var updateTrace:Bool = true;
	var debugAttackTrigger:Bool = false;

	public static var debugGodMode:Bool = false;

	public var combatUI = new FlxTypedGroup<FlxSprite>();
	public var timerArrowGroup = new FlxTypedGroup<TimeIndicator>();
	public var timerIndicator:FlxTypedGroup<FlxSprite> = null;
	public var postureBar:FlxBar;

	public var combatPlayerHealthBar:FlxBar;
	public var combatEnemyHealthBar:FlxBar;

	public var combatMechanics:Bool = true;
	public var characterDeathByStamina:Bool = true;
	public var hasHitNote:Bool = false;
	public var hasParried:Bool = false;
	public var isDodge:Bool = false;

	public static var disableControls:Bool = false;
	public static var enableTimingIndicator:Bool = false;
	public static var combatVictory:Bool = false;
	public static var needCombatVictory:Array<String> = ['trial'];
	public static var singVictoryDisabled:Array<String> = ['dominion', 'dominion-reversal'];
	public static var combatVictoryDisabled:Array<String> = [''];
	public static var combatNoteTypes:Array<String> = ['attack', 'wind', 'shortwind'];
	public static var characterFlipSide:Bool = false;

	var timerReady:Bool = false;
	var timerX:Float = 0;
	var timerY:Float = 0;
	var timerArrowScrollScale:Int = 2;

	var stepTime:Float = 0;

	var playerGuard:FlxTypedGroup<FlxSprite> = null;
	var enemyGuard:FlxTypedGroup<FlxSprite> = null;

	var cpuGuard:FlxTypedGroup<FlxSprite> = null;
	var playerGuardActive:Bool = false;
	var singGuard:Bool = false;
	var attackRecovery:Bool = false;
	var inChain:Bool = false;
	var enemyWasBashed:Bool = false;
	var hasSustainAttacked:Bool = false;
	var combatNoteData:Int = 0;
	var enemyPassiveGuard:Bool = true;
	var enemyGuardDown:Bool = false;
	var bufferNoteAttack:Bool = false;
	var attackDelay:Bool = false;
	var hasStartedAttack:Bool = false;
	var enemyAttackIndicated:Bool = false;
	var instantSingAttack:Bool = false;

	var characterOutOfStamina:Bool = false;
	var enemyPostureMechanic:Bool = false;
	var postureHealthCoefficient:Float = 1;
	var posturePause:Bool = false;

	var playerPreviousGuardPosition:Int = 0;
	var playerAttackPosition:Int = 0;
	var downAttackPositionShift:Bool = false;

	var guardArrow:FlxSprite;
	var attackTypeIndicator:FlxSprite = new FlxSprite(100, 450);

	var combatPlayerHealthBarBG:FlxSprite;
	var combatEnemyHealthBarBG:FlxSprite;

	var hitOverlay:FlxSprite;

	public var reflexGuardTimer:FlxTimer = new FlxTimer();
	public var singGuardTimer:FlxTimer = new FlxTimer();

	var attackRecoveryTimer:FlxTimer = new FlxTimer();
	var enemyPassiveGuardTimer:FlxTimer = new FlxTimer();
	var hasHitNoteTimer:FlxTimer = new FlxTimer();
	var playerWasBashedTimer:FlxTimer = new FlxTimer();
	var enemyWasBashedTimer:FlxTimer = new FlxTimer();
	var attackDelayTimer:FlxTimer = new FlxTimer();
	var isDodgeTimer:FlxTimer = new FlxTimer();
	var posturePauseTimer:FlxTimer = new FlxTimer();
	var chainTimer:FlxTimer = new FlxTimer();
	var instantSingAttackTimer:FlxTimer = new FlxTimer();

	public var stepTimerCrochet:Float = (Conductor.stepCrochet / 1000); // steps in milliseconds compatible with FlxTimer

	// Variable initalization doesn't allow using stepTimerCrochet directly, so just doing the math again
	var bashDuration:Float = (Conductor.stepCrochet / 1000) * 6;

	public var achievementPerformedAParry:Bool = false;
	public var achievementBlockedNonLeftAttack:Bool = false;
	public var achievementCumulativeDamage:Float = 0;
	public var achievementHealthStepCount:Int = 0;

	var manuallySwitchedGuard:Bool = false;

	// This is the core file for handling combat
	// Regarding the entirety of this mod: The setup for this code aims to condense as much of it into it own files as possible
	// Basically the goal is to make as few edits to the engine's code outside of drag-and-dropping the files for this mod
	// Unfortunately it's not possible to prune out every engine-edit, but steps were taken at every chance to reduce this
	// Any change made will have a "Combat change" comment next to it

	public function new()
	{
		super();

		// Combat change
		// Null static values default to false (since static values can't be null)
		// so for combat to be enabled by default the combat mechanic value of a song is the reverse of combatMechanics actually being true or not
		if (PlayState.SONG.disableCombat)
			combatMechanics = false;

		combatVictory = false;

		if (PlayState.instance.flipBoyfriendAndDad)
		{
			characterFlipSide = true;
		}
		else
			characterFlipSide = false;

		if (combatMechanics)
		{
			// Thanks to the fact that I keep butting into making a variable equal to an object just references the original object,
			// I can at least use this for some good
			// PlayState.instance.boyfriend used to be here like 150 times before
			boyfriend = PlayState.instance.boyfriend;
			dad = PlayState.instance.dad;

			trace('start combat new');
			trace(stepTimerCrochet);
			FlxG.watch.addQuick("hasHitNote", hasHitNote);
			FlxG.watch.addQuick("hasParried", hasParried);
			FlxG.watch.addQuick("bufferNoteAttack", bufferNoteAttack);

			playerGuard = new FlxTypedGroup<FlxSprite>();
			enemyGuard = new FlxTypedGroup<FlxSprite>();

			trace('start SONG.player1');
			// Character-specific effects
			switch (PlayState.SONG.player1)
			{
				case 'bf':
				case 'shrub':
					characterDeathByStamina = false;
					setupEnemyPostureMechanic();
				case "shrubSerious":
					characterDeathByStamina = false;
					setupEnemyPostureMechanic();
			}

			// Stamina uses vanilla health as resource
			// So if the character doesn't die the vanilla way, makes sense to just fill the resource off the bat
			if (characterDeathByStamina == false)
				PlayState.instance.health = PlayState.instance.healthBar.max;

			if (!boyfriend.hasReflexGuard)
				playerGuardActive = true;

			generateHealthBar('player');
			generateHealthBar('enemy');

			hitOverlay = new FlxSprite(0, 0);
			hitOverlay.updateHitbox();
			hitOverlay.scrollFactor.set();
			hitOverlay.antialiasing = true;
			hitOverlay.frames = Paths.getSparrowAtlas('effects/hitFlash');
			hitOverlay.animation.addByPrefix('flash', "hitFlash", 12, false);
			hitOverlay.alpha = 0;
			hitOverlay.scrollFactor.set(0, 0);

			combatUI.add(hitOverlay);

			trace('start guard generate');
			generateGuardArrows(0);
			generateGuardArrows(1);

			if (enableTimingIndicator)
				setupTimingIndicator();

			trace('finished create()');
		}
	}

	override function update(elapsed:Float)
	{
		if (combatMechanics)
		{
			/*
				OLD KADE ENGINE THING!
				Return to this when getting around to repositioning time bar

				// Song length bar overlaps with the combat health bars
				// Fits *just* barely in between those and the strumlines
				// Most definitely a KadeEngine specific thing, expect a conflict here in other engines
				//
				// Also: This is in update() since putting this in new doesn't apply the change
				if (PlayState.songPosBar != null && PlayState.songPosBG != null)
				{
					// I'd move the song name too
					// But the variable is declared within a function
					// For the sake of avoiding more off-combat-mod file notes I'm leaving it as-is
					if (PlayState.songPosBar.y == combatPlayerHealthBar.y)
						PlayState.songPosBar.y += 21;
					if (PlayState.songPosBG.y == combatPlayerHealthBarBG.y)
						PlayState.songPosBG.y += 21;
			}*/

			if (updateTrace)
				trace('start update()');

			if (PlayState.instance.generatedMusic)
			{
				// if (PlayState.SONG.notes[PlayState.instance.curSection].sectionNotes == [])
				// {

				// determineEnemyChain();
				// if (dad.currentAction == 'neutral' && !dad.currentAttack.step_based_timing)
				//	performEnemyChartlessAttack();

				// }
				// else
				evaluateCombatNotes();
				// All behavior for the enemy's notes are chunked into evaluateCombatNotes()
			}

			if (updateTrace)
				trace('pre controls');

			if (!disableControls && !boyfriend.isBashed && !hasStartedAttack)
			{
				if (controls.ATTACK_P && !bufferNoteAttack && !attackDelay)
				{
					// attackDelay is here to make a small delay before an attack is thrown if it's not unblockable
					// Unblockables account for buffering the attack in time to let a guard switch happen
					// This is here to provide a buffer before the attack is thrown to give some time to actually press the guard button before the attack is thrown
					attackDelay = true;
					if (instantSingAttack)
						performAttack();
					else
					{
						if (attackDelayTimer.active)
							attackDelayTimer.reset();
						else
							attackDelayTimer.start(0.05, function(tmr:FlxTimer)
							{
								performAttack();
							});
					}

					if (timerReady)
					{
						timerArrowGroup.forEach(function(arrow:TimeIndicator)
						{
							if (arrow.timeExisted >= (Conductor.crochet * 2.75) && arrow.timeExisted <= (Conductor.crochet * 3.25))
							{
								arrow.kill();
								timerArrowGroup.remove(arrow, true);
								arrow.destroy();

								timerIndicator.forEach(function(spr:FlxSprite)
								{
									spr.animation.play('hit');
								});
							}
						});
					}
				}

				if (controls.DDOWN_P)
				{
					hasStartedAttack = false;

					if (isDodgeTimer.active)
						isDodgeTimer.reset();
					else
						isDodge = true;
					isDodgeTimer.start(stepTimerCrochet * 4, function(tmr:FlxTimer)
					{
						isDodge = false;
					});

					initiateChain();

					boyfriend.playAnim('combatReadyDOWN', true);
				}

				if (controls.SPECIAL_P)
				{
					evaluateAttack('specialKey');
				}

				if (controls.GLEFT_P || controls.GUP_P || controls.GRIGHT_P)
				{
					cancelStates();
					playerPreviousGuardPosition = boyfriend.guardPosition;

					if (controls.GLEFT_P)
						boyfriend.guardPosition = 0;
					if (controls.GUP_P)
						boyfriend.guardPosition = 2;
					if (controls.GRIGHT_P)
						boyfriend.guardPosition = 3;

					if (boyfriend.hasReflexGuard)
					{
						switch (boyfriend.guardPosition)
						{
							case 0:
								boyfriend.playAnim('combatReadyLEFT', true);
							case 1:
							// Nope
							case 2:
								boyfriend.playAnim('combatReadyUP', true);
							case 3:
								boyfriend.playAnim('combatReadyRIGHT', true);
						}
					}
					else
					{
						if (controls.GLEFT_P)
						{
							switch (playerPreviousGuardPosition)
							{
								case 2:
									boyfriend.playAnim('combatSwapUpLEFT', true);
								case 3:
									boyfriend.playAnim('combatSwapRightLEFT', true);
							}
						}
						if (controls.GUP_P)
						{
							switch (playerPreviousGuardPosition)
							{
								case 0:
									boyfriend.playAnim('combatSwapLeftUP', true);
								case 3:
									boyfriend.playAnim('combatSwapRightUP', true);
							}
						}
						if (controls.GRIGHT_P)
						{
							switch (playerPreviousGuardPosition)
							{
								case 0:
									boyfriend.playAnim('combatSwapLeftRIGHT', true);
								case 2:
									boyfriend.playAnim('combatSwapUpRIGHT', true);
							}
						}
					}

					if (!singGuard)
						updateGuardUI(playerGuard, 'normal');

					playerGuardActive = true;

					if (boyfriend.hasReflexGuard)
					{
						reflexGuardTimer.start(1, function(tmr:FlxTimer)
						{
							playerGuardActive = false;
						});
					}

					// Not sure if the note hit function occurs before or after this guard switch,
					// So to be generous with the only-left-guard achievement guard switches under singGuard are not counted
					// This way either note goes first and this doesn't apply, or notes go after and flip this to false
					if (!singGuard)
						manuallySwitchedGuard = true;
				}
			}
			else if (boyfriend.isBashed && boyfriend.special == 'recover')
			{
				if (controls.SPECIAL_P)
					evaluateAttack('specialKey');
			}
			if (updateTrace)
				trace('pre timer');
			// Just a note:
			// This all only controls the little timer indicator's animations
			// Do NOT base any actual input timings on this!
			// The timers for determining if an action is on time needs to be independent, both in case the timer's disabled and because it's more foolproof
			if (timerReady)
			{
				timerArrowGroup.forEach(function(arrow:TimeIndicator)
				{
					if (arrow.alpha < 1)
						arrow.alpha += ((FlxG.elapsed * 10) / 12);

					if (arrow.side == 'left')
						arrow.x += ((FlxG.elapsed * 1000) / 12);
					else
						arrow.x -= ((FlxG.elapsed * 1000) / 12);

					arrow.timeExisted += (FlxG.elapsed * 1000);

					// if (arrow.beatCount >= 3)
					if (arrow.timeExisted >= (Conductor.crochet * 3))
					{
						arrow.alpha -= (FlxG.elapsed * 10);
						if (arrow.alpha <= 0)
						{
							arrow.kill();
							timerArrowGroup.remove(arrow, true);
							arrow.destroy();
						}
					}
				});
			}

			stepTime += (FlxG.elapsed * 1000);

			if (boyfriend.hasReflexGuard && !playerGuardActive && !singGuard)
				updateGuardUI(playerGuard, 'inactive');

			if (updateTrace)
				trace('pre misc');

			if (combatEnemyHealthBar.percent >= 75)
				postureHealthCoefficient = 1;
			else if (combatEnemyHealthBar.percent >= 50 && combatEnemyHealthBar.percent < 75)
				postureHealthCoefficient = 0.66;
			else if (combatEnemyHealthBar.percent >= 0 && combatEnemyHealthBar.percent < 50)
				postureHealthCoefficient = 0.33;

			if (!posturePause)
				dad.posture -= (elapsed * 8 * dad.postureRecoveryCoefficient * postureHealthCoefficient);

			if (!characterDeathByStamina)
			{
				if (PlayState.instance.health <= 0 && !characterOutOfStamina)
				{
					// characterOutOfStamina = true;

					PlayState.instance.health = 0;
				}

				PlayState.instance.health += (elapsed / 10);
			}

			if (postureBar != null)
			{
				if (dad.posture <= 0)
					dad.posture = 0;
				if (dad.posture >= dad.postureMax)
					dad.posture = dad.postureMax;
			}

			if (!enemyPostureMechanic)
				dad.posture = 0;

			if (boyfriend.combatHealth >= combatPlayerHealthBar.max)
				boyfriend.combatHealth = combatPlayerHealthBar.max;

			if (boyfriend.combatHealth < 0)
				boyfriend.combatHealth = 0;

			if (dad.combatHealth >= combatEnemyHealthBar.max)
				dad.combatHealth = combatEnemyHealthBar.max;

			if (dad.combatHealth <= 0)
			{
				combatVictory = true;
				dad.combatHealth = 0;
			}
			else
				combatVictory = false;

			if (combatPlayerHealthBar.percent < 40)
				PlayState.instance.iconP1.animation.curAnim.curFrame = 1;
			else
				PlayState.instance.iconP1.animation.curAnim.curFrame = 0;

			if (combatEnemyHealthBar.percent <= 0)
				PlayState.instance.iconP2.animation.curAnim.curFrame = 1;
			else
				PlayState.instance.iconP2.animation.curAnim.curFrame = 0;

			if (updateTrace)
			{
				trace('end update()');
				updateTrace = false;
			}
		}

		if (hitOverlay != null && hitOverlay.animation != null)
		{
			if (hitOverlay.animation.finished)
				hitOverlay.alpha = 0;
			if (hitOverlay.alpha > 0)
				hitOverlay.alpha -= elapsed;
		}
	}

	public static function flipCharacterSide():Void
	{
		PlayState.instance.playerStrums.forEach(function(spr:FlxSprite)
		{
			if (spr.x >= FlxG.width / 2)
				spr.x -= (FlxG.width / 2);
		});
		PlayState.instance.opponentStrums.forEach(function(spr:FlxSprite)
		{
			if (spr.x <= FlxG.width / 2)
				spr.x += (FlxG.width / 2);
		});
	}

	public function generateGuardArrows(player:Int):Void
	{
		// var guardWidgetWidth:Float = 0;
		var leftGuardX:Float = 0;
		var upGuardY:Float = 0;
		for (i in 0...3)
		{
			var guardArrow:FlxSprite = new FlxSprite(50, 450);
			if (ClientPrefs.downScroll)
				guardArrow.y = 50;

			var curGuard:String = 'left';
			var guardPosition:Int = i;
			switch (i)
			{
				case 0:
					guardArrow.x += 5;
					guardArrow.y += 76;
				case 1:
					curGuard = 'up';
					guardArrow.x += 30;
					guardArrow.y += 18;
					guardPosition += 1;
				case 2:
					curGuard = 'right';
					guardArrow.x += 76;
					guardArrow.y += 76;
					guardPosition += 1;
			}

			guardArrow.frames = Paths.getSparrowAtlas('guards/fnfStyle/' + curGuard);
			guardArrow.antialiasing = true;
			guardArrow.setGraphicSize(Std.int(guardArrow.width * 0.7));
			guardArrow.updateHitbox();
			guardArrow.scrollFactor.set();

			guardArrow.x += ((FlxG.width - 195 - 50) * player);

			guardArrow.animation.addByPrefix('active', 'active', 12, false);
			guardArrow.animation.addByPrefix('reflex', 'reflex', 12, false);
			guardArrow.animation.addByPrefix('singGuard', 'singGuard', 12, false);
			guardArrow.animation.addByPrefix('attack', 'attack', 12, false);
			guardArrow.animation.addByPrefix('passive', 'passive');
			guardArrow.animation.addByPrefix('inactive', 'inactive');

			guardArrow.y -= 10;
			guardArrow.alpha = 0;
			FlxTween.tween(guardArrow, {y: guardArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * 1)});

			if (characterFlipSide)
			{
				switch (player)
				{
					case 0:
						playerGuard.add(guardArrow);
					case 1:
						enemyGuard.add(guardArrow);
				}
			}
			else
			{
				switch (player)
				{
					case 0:
						enemyGuard.add(guardArrow);
					case 1:
						playerGuard.add(guardArrow);
				}
			}

			guardArrow.animation.play('passive');

			combatUI.add(guardArrow);

			switch (i)
			{
				case 0:
					leftGuardX = guardArrow.x;
				case 1:
					upGuardY = guardArrow.y;
			}
		}

		updateGuardUI(enemyGuard, 'neutral');
		updateGuardUI(playerGuard, 'neutral');

		if ((characterFlipSide && player == 1) || (!characterFlipSide && player == 0))
		{
			attackTypeIndicator.frames = Paths.getSparrowAtlas('notes/indicator');
			attackTypeIndicator.animation.addByPrefix('specialIndicator', 'indicator bash', false);
			attackTypeIndicator.animation.addByPrefix('unblockableIndicator', 'indicator unblockable', false);
			attackTypeIndicator.antialiasing = true;
			attackTypeIndicator.setGraphicSize(Std.int(attackTypeIndicator.width * 0.6));
			attackTypeIndicator.updateHitbox();
			attackTypeIndicator.scrollFactor.set();

			attackTypeIndicator.x = leftGuardX - 5;
			attackTypeIndicator.y = upGuardY + 2;
			attackTypeIndicator.animation.play('specialIndicator');
			attackTypeIndicator.visible = false;
			combatUI.add(attackTypeIndicator);
		}
	}

	public function generateHealthBar(player:String):Void
	{
		switch (player)
		{
			case 'player':
				combatPlayerHealthBarBG = new FlxSprite(FlxG.width * 0.5, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));
				combatPlayerHealthBarBG.y = 10;
				combatPlayerHealthBarBG.scale.set(0.5, 1);
				combatPlayerHealthBarBG.scrollFactor.set();

				if (characterFlipSide)
					combatPlayerHealthBarBG.x = 0;
				else
					combatPlayerHealthBarBG.x = FlxG.width / 2;

				combatPlayerHealthBarBG.x += 23;

				combatPlayerHealthBar = new FlxBar(combatPlayerHealthBarBG.x + 152, combatPlayerHealthBarBG.y + 4, RIGHT_TO_LEFT,
					Std.int(combatPlayerHealthBarBG.width / 2 - 4), Std.int(combatPlayerHealthBarBG.height - 8), boyfriend, 'combatHealth', 0,
					boyfriend.combatHealth);
				combatPlayerHealthBar.scrollFactor.set();
				combatPlayerHealthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);

				combatUI.add(combatPlayerHealthBarBG);
				combatUI.add(combatPlayerHealthBar);

				PlayState.instance.iconP1.y = PlayState.instance.strumLine.y + 15;
				// Removing the curly brackets results in the expression refusing to move to a new line
				// Looks a lot more confusing if the brackets are left out
				if (characterFlipSide)
				{
					PlayState.instance.iconP1.x = (FlxG.width / 2 - PlayState.instance.iconP1.width / 2);
				}
				else
				{
					PlayState.instance.iconP1.x = FlxG.width / 2;
				}
				if (ClientPrefs.downScroll)
					PlayState.instance.iconP1.y += 20;
				PlayState.instance.iconP1.x -= 35;
				PlayState.instance.iconP1.y += 10;

			case 'enemy':
				combatEnemyHealthBarBG = new FlxSprite(FlxG.width * 0.5, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));
				combatEnemyHealthBarBG.y = 10;
				combatEnemyHealthBarBG.scale.set(0.5, 1);
				combatEnemyHealthBarBG.scrollFactor.set();

				if (characterFlipSide)
					combatEnemyHealthBarBG.x = FlxG.width / 2;
				else
					combatEnemyHealthBarBG.x = 0;

				combatEnemyHealthBarBG.x += 23;

				combatEnemyHealthBar = new FlxBar(combatEnemyHealthBarBG.x + 152, combatEnemyHealthBarBG.y + 4, RIGHT_TO_LEFT,
					Std.int(combatEnemyHealthBarBG.width / 2 - 4), Std.int(combatEnemyHealthBarBG.height - 8), dad, 'combatHealth', 0, dad.combatHealth);
				combatEnemyHealthBar.scrollFactor.set();
				combatEnemyHealthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);

				combatUI.add(combatEnemyHealthBarBG);
				combatUI.add(combatEnemyHealthBar);

				PlayState.instance.iconP2.y = PlayState.instance.strumLine.y - 15;
				// Removing the curly brackets results in the expression refusing to move to a new line
				// Looks a lot more confusing if the brackets are left out, not sure why it's doing that otherwise
				if (characterFlipSide)
				{
					PlayState.instance.iconP2.x = FlxG.width / 2;
				}
				else
				{
					PlayState.instance.iconP2.x = (FlxG.width / 2 - PlayState.instance.iconP2.width / 2);
				}
				PlayState.instance.iconP2.x -= 35;
				PlayState.instance.iconP2.y += 10;
		}
	}

	function evaluateCombatNotes():Void
	{
		var attackNoteToIndicate:Note = getSoonestNote('indicateNote');

		if (!enemyAttackIndicated)
		{
			if (attackNoteToIndicate != null)
			{
				combatNoteData = attackNoteToIndicate.noteData;

				if (combatNoteData != 1)
					dad.guardPosition = combatNoteData;

				if (attackNoteToIndicate.isSpecialNote || attackNoteToIndicate.isUnblockable)
				{
					if (!dad.isBashed)
					{
						attackTypeIndicator.visible = true;
						if (attackNoteToIndicate.isSpecialNote)
							attackTypeIndicator.animation.play('specialIndicator');
						else if (attackNoteToIndicate.isUnblockable)
							attackTypeIndicator.animation.play('unblockableIndicator');
					}
				}
				else
					attackTypeIndicator.visible = false;

				updateGuardUI(enemyGuard, 'attack');

				enemyAttackIndicated = true;
			}
			else
				attackTypeIndicator.visible = false;
		}

		if (attackNoteToIndicate == null && enemyAttackIndicated)
		{
			attackTypeIndicator.visible = false;
			updateGuardUI(enemyGuard, 'neutral');
			enemyAttackIndicated = false;
		}

		PlayState.instance.notes.forEachAlive(function(daNote:Note)
		{
			if (!daNote.mustPress)
			{
				// This startup animation I decided to use purely because I put a startup in the spritesheet
				// Set specifically to shrub so it doesn't cause issues elsewhere,
				// Very fiddly to get to look smooth, the attackStartup variable works of off the safezone for hitting notes
				// And is NOT a good way of doing this!
				if (daNote.attackStartup && dad.animation.curAnim.name.startsWith('combatWind') && PlayState.SONG.player2 == 'shrub')
				{
					switch (combatNoteData)
					{
						case 0:
							dad.playAnim('combatStartupLEFT', true);
						case 1:
						case 2:
							dad.playAnim('combatStartupUP', true);
						case 3:
							dad.playAnim('combatStartupRIGHT', true);
					}
				}

				if (daNote.wasGoodHit)
				{
					enemyPassiveGuard = false;
					if (enemyPassiveGuardTimer.active)
						enemyPassiveGuardTimer.reset();
					else
						enemyPassiveGuardTimer.start(stepTimerCrochet * 4, function(tmr:FlxTimer)
						{
							enemyPassiveGuard = true;
						});

					switch (daNote.noteType)
					{
						case "attack":
							var ignoreIsBashed:Bool = false;
							var forceUnblockable:Bool = false;
							var deathNoteAttack:Bool = false;
							var attackName:String = 'enemy_sing_attack';
							var attackData:AttackData = null;

							// Death note bypasses bashing to prevent cheese bash tactics
							// ...but I thought it was funny so it's being implemented for shrub as a secret ending
							// If you feel this is a viable counter to have overall, feel free to remove the deathNote check
							if (daNote.isDeathNote)
							{
								deathNoteAttack = true;

								if (boyfriend.curCharacter != 'shrubSerious')
									ignoreIsBashed = true;
							}

							if (daNote.isUnblockable)
								forceUnblockable = true;

							if (daNote.noteData == 1)
								attackName == 'enemy_sing_special';

							for (i in 0...dad.attackArray.length)
							{
								if (dad.attackArray[i].name != attackName)
									continue;

								attackData = dad.attackArray[i];
								break;
							}

							if (!daNote.isSustainNote && attackData != null)
								evaluateEnemyAttack(attackData, ignoreIsBashed, daNote.noteData, forceUnblockable, deathNoteAttack);

							enemyGuardDown = false;

						case "wind":
							if (!dad.isBashed)
							{
								if (daNote.noteData != 1)
									dad.guardPosition = daNote.noteData;

								dad.playAnim(appendDirection('combatWind', daNote.noteData, true) + (daNote.isUnblockable ? 'unblockable' : ''), true);

								enemyGuardDown = true;
							}
						case "shortwind":
							if (daNote.noteData != 1)
								dad.guardPosition = daNote.noteData;

							if (dad.animation.getByName(appendDirection('combatWindshort', daNote.noteData, true)
								+ (daNote.isUnblockable ? 'unblockable' : '')) == null)
								dad.playAnim(appendDirection('combatWind', daNote.noteData, true) + (daNote.isUnblockable ? 'unblockable' : ''), true);
							else
								dad.playAnim(appendDirection('combatWindshort', daNote.noteData, true) + (daNote.isUnblockable ? 'unblockable' : ''), true);

							enemyGuardDown = true;
						case "normal":
							switch (daNote.noteData)
							{
								case 0:
									dad.guardPosition = 0;
								case 1:
								case 2:
									dad.guardPosition = 2;
								case 3:
									dad.guardPosition = 3;
							}
							enemyGuardDown = false;
							updateGuardUI(enemyGuard, 'normal');
					}
				}
			}
		});
	}

	function performAttack():Void
	{
		var executeAttack:Bool = true;
		attackDelay = false;
		attackDelayTimer.cancel();

		var soonestNote:Note = getSoonestNote('bufferCheck', true);

		if (soonestNote != null && !hasHitNote)
		{
			if (soonestNote.noteType == 'attack')
				bufferNoteAttack = false;
			else
			{
				bufferNoteAttack = true;
			}

			FlxG.watch.addQuick("bufferNoteAttack", bufferNoteAttack);

			return;
		}

		if (!dad.isBashed)
		{
			if (dad.currentAction == 'startup')
			{
				if (dad.actionTimer.time <= 1)
				{
					hasParried = true;
					FlxG.watch.addQuick("hasParried", hasParried);

					executeAttack = false;
				}
			}
			else if (dad.currentAction == 'stepStartup')
			{
				var timeCounter:Float = 0;
				var parryWindow:Int = 0;
				while (timeCounter < 1)
				{
					timeCounter += stepTimerCrochet;
					++parryWindow;
				}

				if (dad.actionStepTimer <= parryWindow)
				{
					hasParried = true;
					FlxG.watch.addQuick("hasParried", hasParried);

					executeAttack = false;
				}
			}
			else
			{
				var noteToParry:Note = getSoonestNote('isCombatNote');

				if (noteToParry != null && noteToParry.noteData == boyfriend.guardPosition)
				{
					hasParried = true;
					FlxG.watch.addQuick("hasParried", hasParried);

					executeAttack = false;
				}
			}
		}

		if (executeAttack || hasHitNote)
		{
			if (characterDeathByStamina && !debugGodMode)
			{
				if (PlayState.instance.health > (boyfriend.staminaCost * 3) && PlayState.instance.health <= (boyfriend.staminaCost * 4))
					FlxG.sound.play('shared:assets/shared/sounds/oos.wav', 0.4);
				else if (PlayState.instance.health > (boyfriend.staminaCost * 2)
					&& PlayState.instance.health <= (boyfriend.staminaCost * 3))
					FlxG.sound.play('shared:assets/shared/sounds/oos.wav', 0.7);
				else if (PlayState.instance.health <= (boyfriend.staminaCost * 2))
					FlxG.sound.play('shared:assets/shared/sounds/oos.wav', 1);
			}

			evaluateAttack();
		}
	}

	function evaluateAttack(specialInitiation:String = 'none'):Void
	{
		attackDelayTimer.cancel();
		attackDelay = false;

		var isSpecialAttackNote:Bool = false;
		var localStaminaModifier:Float = 1;

		bufferNoteAttack = false;

		FlxG.watch.addQuick("bufferNoteAttack", bufferNoteAttack);

		if (specialInitiation == 'attackNote')
			isSpecialAttackNote = true;

		if (isSpecialAttackNote)
			localStaminaModifier = 0;

		switch (boyfriend.special)
		{
			case 'bash':
				if ((inChain || isSpecialAttackNote || specialInitiation == 'specialKey') && !dad.isBashed)
				{
					if (PlayState.instance.health >= boyfriend.staminaCost * 3 * localStaminaModifier)
						specialBash(localStaminaModifier);
					else
						boyfriend.playSoundEffect('oos');
				}
				else if (PlayState.instance.health >= boyfriend.staminaCost * localStaminaModifier || characterDeathByStamina)
				{
					playerAttack(localStaminaModifier);
				}
				else
					boyfriend.playSoundEffect('oos');
			case 'recover':
				if (!isSpecialAttackNote && specialInitiation == 'specialKey')
				{
					boyfriend.playAnim('combatAttackSPECIAL');
					if (boyfriend.combatHealth > boyfriend.combatHealthMax / 2 && !boyfriend.isBashed)
					{
						boyfriend.combatHealth -= boyfriend.combatHealthMax / 2;
						PlayState.instance.health += 0.6;
						boyfriend.playSoundEffect('heal');
					}
					else if (boyfriend.isBashed)
					{
						boyfriend.isBashed = false;
						playerWasBashedTimer.cancel();
						PlayState.instance.health += 0.3;
						boyfriend.playSoundEffect('heal');

						#if ACHIEVEMENTS_ALLOWED
						var achieve:String = PlayState.instance.checkForAchievement(['recover_tech']);
						if (achieve != null)
						{
							PlayState.instance.startAchievement(achieve);
							Achievements.unlockAchievement(achieve);
						}
						#end
					}

					cancelStates();
				}
				else
					playerAttack(localStaminaModifier);
			default:
				playerAttack();
		}
	}

	function specialBash(?localStaminaModifier:Float = 1):Void
	{
		boyfriend.playAnim('combatAttackSPECIAL', true);
		dad.playAnim('combatHit', true);

		boyfriend.playSoundEffect('bash');
		updateGuardUI(enemyGuard, 'inactive');

		damagePosture(1.5);
		PlayState.instance.health -= boyfriend.staminaCost * 3 * localStaminaModifier;

		dad.isBashed = true;

		if (enemyWasBashedTimer.active)
			enemyWasBashedTimer.reset();
		else
			enemyWasBashedTimer.start(bashDuration, function(tmr:FlxTimer)
			{
				dad.isBashed = false;
			});

		cancelStates();
	}

	function playerAttack(?localStaminaModifier:Float = 1):Void
	{
		if (attackDelay)
		{
			attackDelayTimer.cancel();
			attackDelay = false;
		}

		if (!hasHitNote && (attackRecovery || hasParried))
			return;

		// Sustain notes trigger hasSustainAttacked to remove unblockable effects if more than one attack is thrown
		if (hasSustainAttacked)
		{
			hasHitNote = false;
			hasHitNoteTimer.cancel();
		}

		// attackRecovery creates a delay after throwing an attack so you can't spam attacks abnormally quickly
		// Intentionally bypassed by unblockable shenanigans, you want note unblockables to be as fast as the charting allows
		if (!attackRecovery && !hasHitNote)
		{
			PlayState.instance.health -= (boyfriend.staminaCost * 1.5 * localStaminaModifier);

			hasParried = false;
			FlxG.watch.addQuick("hasParried", hasParried);

			attackRecovery = true;
			if (attackRecoveryTimer.active)
				attackRecoveryTimer.reset();
			else
				attackRecoveryTimer.start(stepTimerCrochet / 2, function(tmr:FlxTimer)
				{
					attackRecovery = false;
				});

			cancelSingGuard();

			if (boyfriend.hasReflexGuard)
			{
				reflexGuardTimer.cancel();
				playerGuardActive = false;
			}
		}
		else if (hasHitNote)
		{
			PlayState.instance.health -= boyfriend.staminaCost * localStaminaModifier;

			// Intentionally set with or without sustain note, just needed for the logic to work
			hasSustainAttacked = true;
		}

		if (!downAttackPositionShift)
			playerAttackPosition = boyfriend.guardPosition;

		downAttackPositionShiftFunction();

		moveCharacterToFront();

		boyfriend.playAnim(appendDirection('combatAttack', playerAttackPosition) + (hasHitNote
			&& boyfriend.hasUnblockableNoteAttacks ? 'unblockable' : ''),
			true);

		if (!boyfriend.hasUnblockableNoteAttacks)
			hasHitNote = false;

		if (enemyPostureMechanic)
		{
			// Greatly increase posture damage while enemy is singing as an alternative strategy to damage
			if (boyfriend.guardPosition == dad.guardPosition && enemyPassiveGuard)
				damagePosture(3);
			else
				damagePosture();
		}

		if ((boyfriend.guardPosition == dad.guardPosition || enemyPassiveGuard) && !hasHitNote && !enemyGuardDown && !dad.isBashed)
		{
			switch (playerAttackPosition)
			{
				case 0:
					dad.playAnim('combatBlockLEFT', true);
				case 2:
					dad.playAnim('combatBlockUP', true);
				case 3:
					dad.playAnim('combatBlockRIGHT', true);
			}

			if (dad.guardPosition == playerAttackPosition)
			{
				var newPosition:Int = FlxG.random.int(0, 2);
				if (newPosition > 0)
					++newPosition;

				// Re-randomizing once to decrease chance that guard sticks to one side
				if (newPosition == playerAttackPosition)
				{
					newPosition = FlxG.random.int(0, 2);
					if (newPosition > 0)
						++newPosition;
				}

				dad.guardPosition = newPosition;
			}
			else
				dad.guardPosition = playerAttackPosition;

			dad.playSoundEffect('block');
		}
		else
			playerAttackLand();

		updateGuardUI(enemyGuard, 'normal');

		cancelStates();
	}

	function evaluateEnemyAttack(attackData:AttackData, ignoreIsBashed:Bool = false, ?attackDirectionInt:Int, forceUnblockable:Bool = false,
			deathNoteAttack:Bool = false):Void
	{
		if (dad.isBashed && !ignoreIsBashed)
			return;

		enemyAttackIndicated = false;
		moveCharacterToFront('dad');

		if (attackDirectionInt != null)
		{
			if (attackDirectionInt != 1 && attackDirectionInt > -1 && attackDirectionInt < 4)
				dad.guardPosition = attackDirectionInt;
		}
		else
		{
			switch (attackData.direction)
			{
				case 'LEFT':
					attackDirectionInt = 0;
				case 'SPECIAL':
					attackDirectionInt = 1;
				case 'UP':
					attackDirectionInt = 2;
				case 'RIGHT':
					attackDirectionInt = 3;
				default:
					attackDirectionInt = dad.guardPosition;
			}
		}

		dad.playAnim(appendDirection(attackData.attack_animation_name, attackDirectionInt, true) + (forceUnblockable ? 'unblockable' : ''), true);

		// The intention is to force-kill if this note passes without the opponent defeated
		// This is intended as a cinematic-end to a song if the opponent wasn't defeated
		//
		// -999 health to try and circumvent heals accidentally causing survival
		//
		// This should trigger the process for dying directly, but that's not wrapped in a function,
		// Editing minimal non-combat file bits, y'know
		// The cleanest approach to this would be placing death's effects in a function and calling it here instead of the health nuke
		//
		// Philosophy's changed since then so I'll probably make this change eventually
		if (deathNoteAttack && !combatVictory)
			boyfriend.combatHealth = -999;

		dad.combatHealth += attackData.health_recover;

		if (enemyPostureMechanic)
			dad.posture -= attackData.posture_recover;

		if (attackData.not_an_attack)
		{
			dad.playSoundEffect(attackData.soundOnHit);
		}
		else if (attackData.is_bash)
		{
			if (isDodge || singGuard)
			{
				// The weapon the enemy is using likely has a greater influence on the kind of sound,
				// Compared to the player character's dodging method
				// Thus the sound is checking dad instead of boyfriend
				dad.playSoundEffect(attackData.soundOnMiss);

				if (!boyfriend.animation.curAnim.name.startsWith('sing'))
					boyfriend.playAnim('combatDodge', true);
			}
			else
			{
				PlayState.instance.health -= 0.5;
				dad.playSoundEffect(attackData.soundOnHit);
				boyfriend.playAnim('combatHit', true);

				cameraBounce(1);

				boyfriend.isBashed = true;
				if (playerWasBashedTimer.active)
					playerWasBashedTimer.reset();
				else
					playerWasBashedTimer.start(bashDuration, function(tmr:FlxTimer)
					{
						boyfriend.isBashed = false;
						if (!boyfriend.hasReflexGuard)
							playerGuardActive = true;
					});

				playerGuardActive = false;
			}
		}
		else if ((attackData.is_unblockable || forceUnblockable) && !hasParried && !singGuard)
		{
			enemyAttackLand(attackData);
		}
		else if ((dad.guardPosition != boyfriend.guardPosition) && !singGuard || !playerGuardActive && !singGuard)
		{
			enemyAttackLand(attackData);
		}
		else if (hasParried && (boyfriend.guardPosition == dad.guardPosition))
		{
			boyfriend.playSoundEffect('parry');
			damagePosture(1.5);

			if (PlayState.instance.health < 2)
				PlayState.instance.health += 0.33;

			boyfriend.combatHealth += 5;

			startSingGuard();

			if (boyfriend.hasReflexGuard && playerGuardActive)
			{
				reflexGuardTimer.cancel();
				playerGuardActive = false;
			}

			if ((boyfriend.hasReflexGuard && !boyfriend.animation.curAnim.name.startsWith('sing')) || (!boyfriend.hasReflexGuard))
			{
				// Brackets to make this less visually awful
				if (boyfriend.animation.getByName(appendDirection('combatParry', boyfriend.guardPosition)) != null)
				{
					// The "combatParry" animation itself works as a flag for CharacterExtras off a parry
					// Even if the block anim is otherwise the same, this is a more straightforward way to signal that info
					// Than trying to send a bool down the animation-call line somehow
					boyfriend.playAnim(appendDirection('combatParry', boyfriend.guardPosition), true);
				}
				else
				{
					boyfriend.playAnim(appendDirection('combatBlock', boyfriend.guardPosition), true);
				}
			}

			achievementPerformedAParry = true;
			if (manuallySwitchedGuard && boyfriend.guardPosition > 0)
				achievementBlockedNonLeftAttack = true;
		}
		else if (((dad.guardPosition == boyfriend.guardPosition) && playerGuardActive) || singGuard)
		{
			if (manuallySwitchedGuard && boyfriend.guardPosition > 0)
				achievementBlockedNonLeftAttack = true;

			boyfriend.playSoundEffect('block');

			if ((boyfriend.hasReflexGuard && !boyfriend.animation.curAnim.name.startsWith('sing')) || (!boyfriend.hasReflexGuard))
			{
				boyfriend.guardPosition = dad.guardPosition;
				manuallySwitchedGuard = false;

				switch (dad.guardPosition)
				{
					case 0:
						boyfriend.playAnim('combatBlockLEFT', true);
					case 1:
					case 2:
						boyfriend.playAnim('combatBlockUP', true);
					case 3:
						boyfriend.playAnim('combatBlockRIGHT', true);
				}
			}
			if (boyfriend.hasReflexGuard && playerGuardActive)
			{
				reflexGuardTimer.cancel();
				playerGuardActive = false;
			}

			if (PlayState.instance.health < 2)
				PlayState.instance.health += 0.01;

			boyfriend.combatHealth += 2;
			damagePosture();
		}

		hasParried = false;
		FlxG.watch.addQuick("hasParried", hasParried);

		cancelStates();

		if (attackDelay)
		{
			attackDelayTimer.cancel();
			attackDelay = false;
		}

		updateGuardUI(enemyGuard, 'normal');
	}

	function determineEnemyChain():Void
	{
		if (dad.placeInChain > dad.currentChain.chain.length - 1 || dad.currentChainName == 'neutral')
		{
			dad.currentChainName = dad.chainArray[Std.random(dad.chainArray.length)].name;

			for (i in 0...dad.chainArray.length)
			{
				if (dad.chainArray[i].name != dad.currentChainName)
					continue;

				dad.currentChain = dad.chainArray[i];
				dad.placeInChain = 0;
				dad.currentChainName = dad.currentChain.name;

				chooseEnemyChartlessAttack();
				break;
			}
		}
	}

	function chooseEnemyChartlessAttack():Void
	{
		if (dad.placeInChain > dad.currentChain.chain.length - 1)
		{
			determineEnemyChain();
			return;
		}

		for (i in 0...dad.attackArray.length)
		{
			if (dad.attackArray[i].name != dad.currentChain.chain[dad.placeInChain])
				continue;

			dad.currentAttack = dad.attackArray[i];
			if (dad.currentChain.direction_overrides[dad.placeInChain] != '')
			{
				if (dad.currentChain.direction_overrides[dad.placeInChain] == 'LEFT'
					|| dad.currentChain.direction_overrides[dad.placeInChain] == 'UP'
					|| dad.currentChain.direction_overrides[dad.placeInChain] == 'RIGHT')
					dad.currentAttack.direction = dad.currentChain.direction_overrides[dad.placeInChain];
			}
			break;
		}
	}

	function performEnemyChartlessAttack():Void
	{
		var currentDirection:Int = 0;

		switch (dad.currentAttack.direction)
		{
			case 'ANY':
				currentDirection = FlxG.random.int(0, 2);
				if (currentDirection > 0)
					++currentDirection;
			// case 'LEFT' is default, so no case needed
			case 'SPECIAL':
				currentDirection = 1;
			case 'UP':
				currentDirection = 2;
			case 'RIGHT':
				currentDirection = 3;
		}

		if (dad.currentAttack.duration > 0 && dad.currentAction == 'neutral')
		{
			dad.currentAction = 'startup';

			if (currentDirection != 1)
			{
				dad.guardPosition = currentDirection;
				updateGuardUI(enemyGuard, 'attack');
			}

			if (dad.currentAttack.startup_animation_name == 'combatWind')
			{
				dad.playAnim(appendDirection(dad.currentAttack.startup_animation_name, currentDirection, true)
					+ (dad.currentAttack.is_unblockable ? 'unblockable' : ''),
					true);
			}
			else
				dad.playAnim(dad.currentAttack.startup_animation_name, true);

			if (dad.currentAttack.step_based_timing)
			{
				dad.currentAction = 'stepStartup';
				dad.actionStepTimer = 0;
			}
			else
			{
				if (dad.actionTimer.active)
					dad.actionTimer.reset(dad.currentAttack.duration);
				else
					dad.actionTimer.start(dad.currentAttack.duration);
				dad.actionTimer.onComplete = onCompleteEnemyRecovery;
			}
		}
		else if (dad.currentAction == 'attack')
		{
			evaluateEnemyAttack(dad.currentAttack, false);
			dad.currentAction = 'recovery';

			if (dad.currentAttack.step_based_timing)
			{
				dad.currentAction = 'stepRecovery';
				dad.actionStepTimer = 0;
			}
			else
			{
				if (dad.actionTimer.active)
					dad.actionTimer.reset(dad.currentAttack.recovery);
				else
					dad.actionTimer.start(dad.currentAttack.recovery);
				dad.actionTimer.onComplete = onCompleteEnemyRecovery;
			}
		}
	}

	function onCompleteEnemyRecovery(tmr:FlxTimer)
	{
		dad.currentAction = 'neutral';
		++dad.placeInChain;
		chooseEnemyChartlessAttack();
		performEnemyChartlessAttack();
	}

	function enemyAttackLand(attackData:AttackData):Void
	{
		boyfriend.combatHealth -= attackData.damage;
		PlayState.instance.health -= attackData.stamina_damage;

		if (boyfriend.hasReflexGuard)
			playerGuardActive = false;

		hasStartedAttack = false;

		boyfriend.isBashed = false;
		playerWasBashedTimer.cancel();

		// dad.playSoundEffect('strike');
		dad.playSoundEffect(attackData.soundOnHit);

		switch (dad.guardPosition)
		{
			case 0:
				boyfriend.playAnim('combatHitLEFT', true);
			case 1:
				boyfriend.playAnim('combatHit', true);
			case 2:
				boyfriend.playAnim('combatHitUP', true);
			case 3:
				boyfriend.playAnim('combatHitRIGHT', true);
		}

		hitOverlay.animation.play('flash', true);
		hitOverlay.alpha = 1;

		cameraBounce(dad.guardPosition);
	}

	function playerAttackLand():Void
	{
		if (enemyPostureMechanic)
		{
			if (dad.posture >= dad.postureMax)
			{
				if (dad.isBashed)
				{
					reduceHealth(dad, boyfriend.baseDamage * 5);
					dad.posture -= (dad.postureMax / 2);

					boyfriend.playSoundEffect('postureBreak');
					cameraBounce(playerAttackPosition);
				}
				else
				{
					reduceHealth(dad, boyfriend.baseDamage);
					boyfriend.playSoundEffect('strike');
				}
			}
			else
			{
				reduceHealth(dad, boyfriend.baseDamage / 2);
				boyfriend.playSoundEffect('strike');
			}
		}
		else
		{
			boyfriend.playSoundEffect('strike');

			if (hasHitNote)
				reduceHealth(dad, boyfriend.baseDamage * 1.5);
			else
				reduceHealth(dad, boyfriend.baseDamage);
		}

		dad.guardPosition = boyfriend.guardPosition;

		switch (boyfriend.guardPosition)
		{
			case 0:
				dad.playAnim('combatHitLEFT', true);
			case 1:
			// Nope
			case 2:
				dad.playAnim('combatHitUP', true);
			case 3:
				dad.playAnim('combatHitRIGHT', true);
		}

		enemyWasBashedTimer.cancel();
		dad.isBashed = false;

		hasHitNoteTimer.cancel();
		hasHitNote = false;
	}

	/**
	 * Used to update what animations the guard widget is playing
	 *
	 * @param characterGuard 	A guard widget sprite group, mainly playerGuard or enemyGuard
	 * @param updateType 		A string to determine which animation for the guard to use. 'normal' animates normal,
	 *							'neutral' is like normal but without the initial flash animation, 'attack' does an orange arrow,
	 *							'inactive' disables all arrows (with the current guard position arrow keeping a black outline),
	 *							and 'singGuard' is a temporary all-guard
	 * 
	**/
	function updateGuardUI(characterGuard:FlxTypedGroup<FlxSprite>, updateType:String):Void
	{
		var hasReflexGuard:Bool = false;
		var guardPosition:Int = 0;

		if (characterGuard == playerGuard)
		{
			hasReflexGuard = boyfriend.hasReflexGuard;
			guardPosition = boyfriend.guardPosition;
		}
		else if (characterGuard == enemyGuard)
		{
			hasReflexGuard = dad.hasReflexGuard;
			guardPosition = dad.guardPosition;
		}

		var guardArrayPosition:Int = guardPosition > 0 ? guardPosition - 1 : guardPosition;

		characterGuard.forEach(function(spr:FlxSprite)
		{
			spr.animation.finishCallback = null;

			spr.visible = true;
			switch (updateType)
			{
				case 'normal':
					if (characterGuard.members[guardArrayPosition] == spr)
					{
						if (hasReflexGuard)
							spr.animation.play('reflex', true);
						else
							spr.animation.play('active', true);
					}
					else
						spr.animation.play('passive', true);
				case 'neutral':
					if (characterGuard.members[guardArrayPosition] == spr)
					{
						if (hasReflexGuard)
							spr.animation.play('reflex', true, false, 3);
						else
							spr.animation.play('active', true, false, 3);
					}
					else
						spr.animation.play('passive', true);
				case 'singGuard':
					if (hasReflexGuard)
					{
						if (characterGuard.members[guardArrayPosition] == spr)
							spr.animation.play('reflex', true);
						else
							spr.animation.play('singGuard', true);
					}
					else
						spr.animation.play('singGuard', true);
				case 'attack':
					if (characterGuard.members[guardArrayPosition] == spr)
					{
						spr.animation.play('attack', true);
					}
					else
						spr.animation.play('passive', true);
				case 'inactive':
					if (characterGuard.members[guardArrayPosition] == spr)
					{
						spr.animation.play('inactive', true);
					}
					else
						spr.animation.play('passive', true);
			}
		});
	}

	// Provides the automatic guarding/dodging when you are singing
	// Also acts as one of the main parry benefits of certain characters (Namely BF)
	function startSingGuard():Void
	{
		updateGuardUI(playerGuard, 'singGuard');

		singGuard = true;
		singGuardTimer.start(1, function(tmr:FlxTimer)
		{
			singGuard = false;
			updateGuardUI(playerGuard, 'neutral');
		});
	}

	function cancelSingGuard():Void
	{
		singGuard = false;
		if (singGuardTimer.active)
			singGuardTimer.reset(0);
	}

	public function noteMissCombatPunish():Void
	{
		if (!boyfriend.hasReflexGuard)
			updateGuardUI(playerGuard, 'neutral');

		cancelSingGuard();

		bufferNoteAttack = false;
		hasStartedAttack = false;

		FlxG.watch.addQuick("bufferNoteAttack", bufferNoteAttack);
	}

	public function noteGoodHitCombat(note:Note):Void
	{
		if (!note.isSustainNote)
			hasSustainAttacked = false;

		if (note.noteData != 1)
			boyfriend.guardPosition = note.noteData;
		manuallySwitchedGuard = false;

		hasHitNote = true;
		FlxG.watch.addQuick("hasHitNote", hasHitNote);

		var duration:Float = stepTimerCrochet / 2;
		/*var nextNote:Note = getSoonestNote('any', true, true);
			if (nextNote != null && nextNote.isSustainNote)
			{
				duration = stepTimerCrochet * 2.25;
		}*/

		if (hasHitNoteTimer.active)
			hasHitNoteTimer.reset(duration);
		else
			hasHitNoteTimer = new FlxTimer().start(duration, function(tmr:FlxTimer)
			{
				hasHitNote = false;
				// trace(hasHitNoteTimer.time);
				FlxG.watch.addQuick("hasHitNote", hasHitNote);
			});

		// You might notice the similarities to hasHitNote
		// Remember that hasHitNote can get cleared due to various circumstances, so having this separate variable/timer is important
		instantSingAttack = true;
		if (instantSingAttackTimer.active)
			instantSingAttackTimer.reset();
		else
			instantSingAttackTimer.start(duration, function(tmr:FlxTimer)
			{
				instantSingAttack = false;
			});

		hasStartedAttack = false;

		// Little animation tidbit to keep down-note attacks from getting monotonous
		if (note.noteData == 1)
		{
			downAttackPositionShift = true;

			initiateChain();
		}
		else
		{
			downAttackPositionShift = false;

			chainTimer.cancel();
			inChain = false;
		}

		boyfriend.isBashed = false;
		playerWasBashedTimer.cancel();

		startSingGuard();

		if (note.noteType == 'wind' || note.noteType == 'shortwind')
		{
			// Transfering this function to a variable since it (probably?) saves on performance
			// Dunno how taxing this function really is tbh
			//
			// Saves a single copy of getSoonestNote, lesgo
			var windNote:Note = getSoonestNote('attackNote');

			if (windNote != null)
				note.noteData = windNote.noteData;
		}

		if (note.noteData == 1)
			initiateChain();

		switch (note.noteType)
		{
			case '' | 'normal':
				if (bufferNoteAttack || attackDelay)
				{
					evaluateAttack();
				}
			case 'attack':
				// Sound effects playing way off sounds real bad
				// So this "balance" decision is pretty much to remedy that sound issue
				// It's rewarding precision, I swear
				if (note.rating == 'good' || note.rating == 'sick')
				{
					if (note.noteData == 1)
						evaluateAttack('attackNote');
					else
						playerAttack(0);
				}
			case 'wind':
				// Keep in mind for these wind cases that noteData gets changed to the soonest attack note
				boyfriend.playAnim(appendDirection('combatWind', note.noteData, true), true);
			case 'shortwind':
				if (boyfriend.animation.getByName(appendDirection('combatWindshort', note.noteData)) == null)
					boyfriend.playAnim(appendDirection('combatWind', note.noteData, true), true);
				else
					boyfriend.playAnim(appendDirection('combatWindshort', note.noteData, true), true);
		}
	}

	/**
	 * Reverses the order of the spriteOrder members array based on if the chosen character is behind or not
	 * This changes the draw order and controls who is layered in front of the other
	 * 
	 * This was done instead of a sort method since characters are organized by groups, and making a new group class to store a variable needed for
	 * organizing this all felt like overkill considering it's just flipping the spot of two actors.
	 * 
	 * This works off the assumption that spriteOrder only contains two actors: boyfriend, and dad
	 * If there's three or more characters I suggest writing out a new method. Probably a proper sort() function
	 * 
	 * @param character 'dad' moves dad to front, otherwise defaults to boyfriend
	 */
	public function moveCharacterToFront(?character:String):Void
	{
		var group:FlxSpriteGroup;

		if (character == 'dad')
			group = dadGroup;
		else
			group = boyfriendGroup;

		if (PlayState.instance.spriteOrder.members.indexOf(group) == 0)
			PlayState.instance.spriteOrder.members.reverse();
	}

	function setupEnemyPostureMechanic():Void
	{
		// PlayState.instance.healthBar.visible = false;

		postureBar = new FlxBar(PlayState.instance.healthBarBG.x + 4, PlayState.instance.healthBarBG.y + 24, RIGHT_TO_LEFT,
			Std.int(PlayState.instance.healthBarBG.width - 8), Std.int(PlayState.instance.healthBarBG.height - 8), dad, 'posture', 0, dad.postureMax);
		postureBar.scrollFactor.set();
		postureBar.createFilledBar(0xFF503838, 0xFFFDFF6E);
		combatUI.add(postureBar);

		enemyPostureMechanic = true;
	}

	function damagePosture(postureDamageModifer:Float = 1):Void
	{
		posturePause = true;

		// Timer length is a constant instead of some kind of stepTimerCrochet to maintain consistency between song speeds

		if (posturePauseTimer.active)
			posturePauseTimer.reset();
		else
			posturePauseTimer.start(3, function(tmr:FlxTimer)
			{
				posturePause = false;
			});

		dad.posture += boyfriend.postureDamage * postureDamageModifer;
	}

	// This is a scrapped mechanic where the Shrub was originally going to only act according to the beat
	// That ended up not playing so great though, so this is no longer really needed
	//
	// A known issue is that the indicator does not resync with the song, so some generated arrows and likely the timing window itself can get thrown off
	function setupTimingIndicator():Void
	{
		timerIndicator = new FlxTypedGroup<FlxSprite>();

		trace('start timer generate');
		for (i in 0...3)
		{
			var timingArrow:FlxSprite = new FlxSprite(0, 0);
			timingArrow.frames = Paths.getSparrowAtlas('notes/timingIndicator');
			timingArrow.antialiasing = true;
			timingArrow.setGraphicSize(Std.int(timingArrow.width * 0.7));
			timingArrow.updateHitbox();
			timingArrow.scrollFactor.set();

			switch (i)
			{
				case 0:
					timingArrow.animation.addByPrefix('beat', 'timingIndicator centerBeat', 24, false);
					timingArrow.animation.addByPrefix('passive', 'timingIndicator centerBeat0004');
				case 1:
					timingArrow.animation.addByPrefix('hit', 'timingIndicator leftBeatActive', 24, false);
					timingArrow.animation.addByPrefix('passive', 'timingIndicator leftBeatPassive');
				case 2:
					timingArrow.animation.addByPrefix('hit', 'timingIndicator rightBeatActive', 24, false);
					timingArrow.animation.addByPrefix('passive', 'timingIndicator rightBeatPassive');
			}

			timingArrow.screenCenter();
			timingArrow.y = (FlxG.height / 6);

			timerX = timingArrow.x;
			timerY = timingArrow.y;

			timingArrow.updateHitbox();
			timingArrow.scrollFactor.set();

			timingArrow.y -= 10;
			timingArrow.alpha = 0;
			FlxTween.tween(timingArrow, {y: timingArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * 1)});

			timingArrow.animation.play('passive');

			timerIndicator.add(timingArrow);
		}
	}

	// This was all written to support a timing indicator
	// Ended up scrapping the mechanic but it's left here
	// Doesn't self-correct on beat misalignments so be forewarned that it's not a complete feature
	//
	// Also, override isn't make this function on its own. I dunno how PlayState's seemingly making its beatHit override function despite
	// Nothing else existing but the beatHit override

	/*override function beatHit():Void
		{
			if (enableTimingIndicator)
			{
				if (timerReady)
				{
					timerArrowGroup.forEach(function(arrow:TimeIndicator)
					{
						arrow.beatCount++;
					});
				}

				timerIndicator.forEachAlive(function(spr:FlxSprite)
				{
					spr.animation.play('beat', true);
				});

				for (i in 0...2)
				{
					switch (i)
					{
						case 0:
							var timerArrow:TimeIndicator = new TimeIndicator((timerX - Conductor.crochet / 4), timerY, 'left', 0, 0);
							timerArrow.alpha = 0;
							timerArrowGroup.add(timerArrow);
						case 1:
							var timerArrow:TimeIndicator = new TimeIndicator((timerX + Conductor.crochet / 4), timerY, 'right', 0, 0);
							timerArrow.alpha = 0;
							timerArrowGroup.add(timerArrow);
					}
				}

				stepTime = 0;

				timerReady = true;
			}
	}*/
	public function combatStepHit():Void
	{
		if (PlayState.instance.generatedMusic)
			if (boyfriend.combatHealth <= boyfriend.combatHealthMax / 2)
				achievementHealthStepCount += 1;

		if (!dad.currentAction.startsWith('step'))
			dad.actionStepTimer = 0;

		if (dad.currentAction == 'neutral' && dad.currentAttack.step_based_timing)
			performEnemyChartlessAttack();

		if (dad.currentAction == 'stepStartup')
		{
			if (dad.actionStepTimer >= dad.currentAttack.duration)
			{
				dad.currentAction = 'attack';
				performEnemyChartlessAttack();
			}
		}
		else if (dad.currentAction == 'stepRecovery')
		{
			if (dad.actionStepTimer >= dad.currentAttack.recovery)
				onCompleteEnemyRecovery(null);
		}

		if (dad.currentAction.startsWith('step'))
			++dad.actionStepTimer;
	}

	/**
	 * Cancels any ongoing dodges and chains
	 */
	function cancelStates():Void
	{
		isDodgeTimer.cancel();
		isDodge = false;
		chainTimer.cancel();
		inChain = false;
	}

	function initiateChain():Void
	{
		inChain = true;
		if (chainTimer.active)
			chainTimer.reset();
		else
			chainTimer = new FlxTimer().start(stepTimerCrochet * 6, function(tmr:FlxTimer)
			{
				inChain = false;
			});
	}

	/**
		This function's purpose is to fix monotonous animations from multiple down arrow attacks.

		This makes repeated attacks with the same guard position shift the attack animation to a different guard.

		If downAttackPositionShift is on, but the attack position variable hasn't been updated yet, it will store the attack position.

		The stored attack position matching the player's current guard position is when this function executes the animation shift.
	**/
	function downAttackPositionShiftFunction():Void
	{
		if (downAttackPositionShift)
		{
			if (playerAttackPosition == boyfriend.guardPosition)
			{
				playerAttackPosition += 1;

				if (playerAttackPosition == 1)
					playerAttackPosition += 1;
				if (playerAttackPosition > 3)
					playerAttackPosition = 0;

				downAttackPositionShift = false;
			}
			else
				playerAttackPosition = boyfriend.guardPosition;
		}
		/*else
			{
				if (playerAttackPosition == boyfriend.guardPosition)
					downAttackPositionShift = true;
				playerAttackPosition = boyfriend.guardPosition;
		}*/
	}

	/**
		Checks which animation a character is playing.

		Can check 'startsWith' and 'endsWith'. Works around animation name prefixes such as the 'combat' prefix.
	**/
	function characterCurAnim(character:String, check:String, anim:String):Bool
	{
		var curAnimBool:Bool = false;

		if (character == 'boyfriend')
		{
			if (check == 'startsWith'
				&& boyfriend.animation.curAnim.name.startsWith(anim)
				|| check == 'endsWith'
				&& (boyfriend.animation.curAnim.name.endsWith(anim)))
				curAnimBool = true;
			else
				curAnimBool = false;
		}
		else if (character == 'dad')
		{
			if (check == 'startsWith'
				&& dad.animation.curAnim.name.startsWith(anim)
				|| check == 'endsWith'
				&& (dad.animation.curAnim.name.endsWith(anim)))
				curAnimBool = true;
			else
				curAnimBool = false;
		}

		// I think multiple returns that return the same result breaks the function, so that's all circumvented by just returning another variable
		return curAnimBool;
	}

	/**
	 * A function to sort through currently alive notes to narrow checks to only the next occurring note.
	 * 
	 * This function's defaults check for enemy combat notes.
	 * 
	 * NOTE: I discovered post making this that notes get sorted roughly by time anyway,
	 * Just to save reprogramming trouble this is an avant-garde way to check some note cases
	 *
	 * @param noteCheck 'any' to check any note, 'indicateNote' checks the note's indicateNote range, 'isCombatNote' checks isCombatNote range, 'bufferCheck' checks the range to buffer a player note attack, otherwise compares noteType to noteCheck string.
	 * @param mustPress Put in place of daNote.mustPress; true checks player notes, false checks opponent's
	 * @param ignoreFirst Gets the *second* soonest note, for comparing to a note right on hit, like in "noteGoodHitCombat", which would otherwise just pick up the same note that was hit
	**/
	function getSoonestNote(noteCheck:String = 'any', mustPress:Bool = false, ignoreFirst:Bool = false):Note
	{
		var nextNote:Note = null;
		var secondNote:Note = null;

		// This figures out which valid note is the soonest note to be played
		// This is used to fix picking up note signals from notes being too close together
		PlayState.instance.notes.forEachAlive(function(daNote:Note)
		{
			var performNoteCheck:Bool = false;

			if (daNote.mustPress == mustPress && !daNote.wasGoodHit && !daNote.tooLate)
			{
				switch (noteCheck)
				{
					case 'any':
						performNoteCheck = true;
					case 'bufferCheck':
						if (daNote.withinCombatRange)
							performNoteCheck = true;
					case 'isCombatNote':
						if (daNote.isCombatNote)
							performNoteCheck = true;
					case 'indicateNote':
						if (daNote.indicateCombatNote)
							performNoteCheck = true;
					default:
						if (daNote.noteType == noteCheck)
							performNoteCheck = true;
				}
			}

			if (performNoteCheck)
			{
				if (nextNote == null || nextNote != null && daNote.strumTime < nextNote.strumTime)
					nextNote = daNote;

				if (secondNote == null)
					secondNote = nextNote;
				else if (nextNote != null && daNote.strumTime < secondNote.strumTime && daNote.strumTime < nextNote.strumTime)
					secondNote = daNote;
			}
		});

		return (ignoreFirst ? secondNote : nextNote);
	}

	/**
	 * Tweens the camera one direction, back a slighter distance in the other direction, then returns to a neutral state.
	 * Results in a bounce-back camera effect, perfect for attack hits and other general motion-impact selling.
	 *
	 * Small randomization is applied in shift distance. Helps to prevent movements from feeling too static.
	 *
	 * Can be tweaked to apply a bounce in a particular direction based on where the maneuver came from
	 *
	 * @param direction 		Int value equivalent to note directions. Sets the direction of the initial movement
	 * @param flipBounceSide 	Default bounce directions assume the enemy side's perspective. Flips orientation of the bounce for use on player actions
	 * @param shift 			How much the camera moves
	 * @param duration 			How quickly the camera shakes
	 * 
	**/
	function cameraBounce(direction:Int = 0, flipBounceSide:Bool = false, shift:Float = 5, duration:Float = 0.02):Void
	{
		if (characterFlipSide)
			shift = -shift;

		var shiftX:Float = shift;
		var shiftY:Float = shift;

		switch (direction)
		{
			case 0:
				shiftX = -shiftX;

				shiftX += FlxG.random.float(-5, 0);
				shiftY += FlxG.random.float(0, 5);
			case 1:
				// Special attacks likely strike forward, so rightward direction
				// Also beefing up x movement to sell the impact better
				shiftX += 5;
				shiftX += FlxG.random.float(0, 5);

				// Also randomizing whether Y is upward or downwards for variety
				if (FlxG.random.bool())
					shiftY = -shiftY;
				shiftY += FlxG.random.float(-5, 5);
			case 2:
				// Nullifying shiftX so there's only slight X movement
				// Also, up attacks likely are biased downards
				shiftX = 0;
				shiftY = -shiftY;

				shiftX += FlxG.random.float(0, 5);
				shiftY += FlxG.random.float(-5, 0);
			case 3:
				// Left and right have reversed Y direction for variety
				shiftY = -shiftY;

				shiftX += FlxG.random.float(0, 5);
				shiftY += FlxG.random.float(-5, 0);
		}

		FlxTween.tween(FlxG.camera, {x: FlxG.camera.x + shiftX, y: FlxG.camera.y + shiftY}, duration, {
			ease: FlxEase.elasticOut,
			onComplete: function(twn:FlxTween)
			{
				FlxTween.tween(FlxG.camera, {x: FlxG.camera.x - shiftX - shiftX / 2, y: FlxG.camera.y - shiftY - shiftY / 2}, duration, {
					ease: FlxEase.elasticOut,
					onComplete: function(twn:FlxTween)
					{
						FlxTween.tween(FlxG.camera, {x: FlxG.camera.x + shiftX / 2, y: FlxG.camera.y + shiftY / 2}, duration, {
							ease: FlxEase.elasticOut
						});
					}
				});
			}
		});
	}

	// appendDirection() note
	// So this function is intended to shorten and automate a lot of animation switch statements
	// You may notice there are still a lot of switch statements and animations that don't use this
	//
	// Simply put: Looks a helluva lot less readable if you use this function at times.
	// Very dense if expressions can make the whole block look very muddy when the switch statement gets condensed this way
	// Use this function if you'd like, but that's the reason why it's not used super often to begin with
	//
	// (Also, this was written much later in a sort of code-cleanup phase.)

	/**
		Adds LEFT, DOWN, UP, and RIGHT to a string on 0, 1, 2, and 3 input.

		These directions correspond to guard direction and singing note directions.
	**/
	public static function appendDirection(string:String, direction:Int, downToSPECIAL:Bool = false):String
	{
		switch (direction)
		{
			case 0:
				string += 'LEFT';
			case 1:
				if (downToSPECIAL)
					string += 'SPECIAL'
				else
					string += 'DOWN';
			case 2:
				string += 'UP';
			case 3:
				string += 'RIGHT';
		}

		return string;
	}

	/**
	 * Returns true if PlayState.instance and PlayState.instance.COMBAT is not null
	 * 
	 * Used for preventing crashes from referencing combat variables, such as the hasHitNote bool.
	 * 
	 * It also prevents referencing PlayState.instance in general if in the animation test state
	 */
	public static function checkCombatInfoAvailable():Bool
	{
		if (PlayState.instance != null && PlayState.instance.COMBAT != null)
			return true;
		else
			return false;
	}

	/**
	 * Centralized place to alter health for the sake of tying events to health changes
	 */
	function reduceHealth(character:Character, amount:Float):Void
	{
		character.combatHealth -= amount;

		if (amount > 0)
			achievementCumulativeDamage += amount;

		#if ACHIEVEMENTS_ALLOWED
		var achieve:String = PlayState.instance.checkForAchievement(['bf_pain', 'shrub_pain']);
		if (achieve != null)
		{
			PlayState.instance.startAchievement(achieve);
			Achievements.unlockAchievement(achieve);
		}
		#end
	}
}
