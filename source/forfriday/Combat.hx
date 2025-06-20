package forfriday;

import backend.Song.SwagSong;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import forfriday.CharacterExtra;
import objects.Bar;
import objects.Character;
import objects.Note;

using StringTools;

// I tested switching the extension to just an FlxBasic to make sure there's not a ton of unneeded memory usage. Memory usage seems unchanged
//
// Essentially, the main purpose of extending PlayState in this case is to allow access to private PlayState variables without having to turn them public
// Variables like generatedMusic and healthBarBG probably should be public anyway but it's less engine stuff to have to monkey with
class Combat extends FlxBasic
{
	var boyfriend:Character = null;
	var dad:Character = null;
	var controls:Controls = null;

	public static var debugGodMode:Bool = false;

	public var combatUI = new FlxTypedGroup<FlxSprite>();
	public var timerArrowGroup = new FlxTypedGroup<TimeIndicator>();
	public var timerIndicator:FlxTypedGroup<FlxSprite> = null;

	public var combatPlayerHealthBar:Bar;
	public var combatEnemyHealthBar:Bar;

	public var playerPostureBar:Bar;
	public var enemyPostureBar:Bar;

	public var combatMechanics:Bool = true;
	public var enemyOnOffense:Bool = false;
	public var avoidStaleChains:Bool = true;
	public var avoidStaleChainOdds:Float = 0.75;

	public var isDodge:Bool = false;
	public var playerInputChainArray:Array<String> = [];

	public static var disableControls:Bool = false;
	public static var enableTimingIndicator:Bool = false;
	public static var combatVictory:Bool = false;
	public static var needCombatVictory:Array<String> = ['trial'];
	public static var singVictoryDisabled:Array<String> = ['dominion', 'dominion-reversal'];
	public static var combatVictoryDisabled:Array<String> = [''];
	public static var combatNoteTypes:Array<String> = ['attack', 'wind', 'shortwind', 'Attack Note', 'Attack Startup'];
	public static var characterFlipSide:Bool = false;

	var timerReady:Bool = false;
	var timerX:Float = 0;
	var timerY:Float = 0;
	var timerArrowScrollScale:Int = 2;

	var playerGuard:FlxTypedGroup<FlxSprite> = null;
	var enemyGuard:FlxTypedGroup<FlxSprite> = null;

	var playerGuardActive:Bool = false;
	var singGuard:Bool = false;
	var enemyAttackIndicated:Bool = false;

	var enemyPostureMechanic:Bool = false;
	var postureHealthCoefficient:Float = 1;
	var posturePause:Bool = false;

	var playerPreviousGuardPosition:Int = 0;
	var playerAttackPosition:Int = 0;
	var downAttackPositionShift:Bool = false;
	var hasSustainAttacked:Bool = false;

	var enemyMatchedPlayerGuard:Bool = false;

	public var attackTypeIndicator:FlxSprite = new FlxSprite(100, 450);

	var hitOverlay:FlxSprite;

	public var timerArray:Array<FlxTimer> = [];

	public var reflexGuardTimer:FlxTimer = new FlxTimer();
	public var singGuardTimer:FlxTimer = new FlxTimer();
	public var isDodgeTimer:FlxTimer = new FlxTimer();
	public var posturePauseTimer:FlxTimer = new FlxTimer();
	public var chainTimer:FlxTimer = new FlxTimer();
	public var attackDelayTimer:FlxTimer = new FlxTimer();

	public var stepTimerCrochet:Float = (Conductor.stepCrochet / 1000); // steps in milliseconds compatible with FlxTimer

	public var achievementPerformedAParry:Bool = false;
	public var achievementBlockedNonLeftAttack:Bool = false;
	public var achievementCumulativeDamage:Float = 0;
	public var achievementHealthStepCount:Int = 0;

	var manuallySwitchedGuard:Bool = false;

	// This is the core file for handling combat
	// Any change made to existing vanilla files will have a "Combat change" comment next to it

	public function new()
	{
		super();

		// Thanks to the fact that I keep butting into making a variable equal to an object just references the original object,
		// I can at least use this for some good
		// PlayState.instance.boyfriend used to be here like 150 times before
		boyfriend = PlayState.instance.boyfriend;
		dad = PlayState.instance.dad;
		controls = PlayState.instance.controls;

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
			trace('start combat new');
			trace(stepTimerCrochet);
			FlxG.watch.addQuick("BF Action", boyfriend.currentAction);
			FlxG.watch.addQuick("Dad Action", dad.currentAction);

			playerGuard = new FlxTypedGroup<FlxSprite>();
			enemyGuard = new FlxTypedGroup<FlxSprite>();

			trace('start SONG.player1');

			setupPostureMechanic();

			// Stamina uses vanilla health as resource
			// So if the character doesn't die the vanilla way, makes sense to just fill the resource off the bat
			if (!boyfriend.deathByStamina)
				PlayState.instance.health = PlayState.instance.healthBar.bounds.max;

			if (!boyfriend.hasReflexGuard)
				playerGuardActive = true;

			generateCombatBar('player', 'combatHealth');
			generateCombatBar('enemy', 'combatHealth');

			PlayState.instance.iconP1.y = 65;
			if (characterFlipSide)
			{
				PlayState.instance.iconP1.x = (FlxG.width / 2 - PlayState.instance.iconP1.width / 2);
			}
			else
			{
				PlayState.instance.iconP1.x = FlxG.width / 2;
			}
			if (ClientPrefs.data.downScroll)
				PlayState.instance.iconP1.y += 20;
			PlayState.instance.iconP1.x -= 35;
			PlayState.instance.iconP1.y += 10;

			PlayState.instance.iconP2.y = 35;
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

			timerArray.push(reflexGuardTimer);
			timerArray.push(singGuardTimer);
			timerArray.push(isDodgeTimer);
			timerArray.push(posturePauseTimer);
			timerArray.push(chainTimer);
			timerArray.push(dad.actionTimer);
			timerArray.push(boyfriend.actionTimer);

			for (flxTimer in timerArray)
			{
				flxTimer = new FlxTimer();
			}

			trace('finished create()');
		}
	}

	override function update(elapsed:Float)
	{
		if (combatMechanics)
		{
			if (PlayState.instance.generatedMusic)
			{
				// if (PlayState.SONG.notes[PlayState.instance.curSection].sectionNotes == [])
				if (!PlayState.instance.startingSong && !boyfriend.stunned && !PlayState.instance.paused)
				{
					if (enemyOnOffense)
					{
						determineEnemyChain();
						if (dad.currentAction == 'neutral' && !dad.currentAttack.step_based_timing)
							startEnemyAttack();
					}
				}

				// else
				evaluateCombatNotes();
				// All behavior for the enemy's notes are chunked into evaluateCombatNotes()
			}

			if (!disableControls && boyfriend.currentAction != 'bashed')
			{
				if (controls.GLEFT_P || controls.GUP_P || controls.GRIGHT_P)
				{
					cancelDodge();
					playerPreviousGuardPosition = boyfriend.guardPosition;

					var newGuardPosition:Int = 0;

					if (controls.GLEFT_P)
						newGuardPosition = 0;
					if (controls.GUP_P)
						newGuardPosition = 2;
					if (controls.GRIGHT_P)
						newGuardPosition = 3;

					switchGuard(playerGuard, 'normal', newGuardPosition);
					if (boyfriend.currentAction == 'neutral')
						changeAction(boyfriend, 'defending', 1);

					playerGuardActive = true;

					if (boyfriend.hasReflexGuard)
					{
						reflexGuardTimer.start(1, function(tmr:FlxTimer)
						{
							playerGuardActive = false;
							updateGuardUI(playerGuard, 'inactive');
						});
					}

					// Not sure if the note hit function occurs before or after this guard switch,
					// So to be generous with the only-left-guard achievement guard switches under singGuard are not counted
					// This way either note goes first and this doesn't apply, or notes go after and flip this to false
					if (!singGuard)
						manuallySwitchedGuard = true;
				}

				if (controls.DDOWN_P)
				{
					if (isDodgeTimer.active)
						isDodgeTimer.reset();
					else
						isDodge = true;
					isDodgeTimer.start(1, function(tmr:FlxTimer)
					{
						isDodge = false;
					});

					if (boyfriend.currentAction == 'neutral')
						changeAction(boyfriend, 'dodge', 1);

					boyfriend.playAnim('combatReadyDOWN', true);
				}

				if (controls.ATTACK_P && !playerIsWaitingToAttack())
				{
					// attackDelay is here to make a small delay before an attack is thrown if it's not unblockable
					// Unblockables account for buffering the attack in time to let a guard switch happen
					// This is here to provide a buffer before the attack is thrown to give some time to actually press the guard button before the attack is thrown
					if (boyfriend.currentAction == 'hasHitNote')
					{
						attackDelayTimer.cancel();
						validatePlayerAttack();
					}
					else if (!attackDelayTimer.active)
						attackDelayTimer.start(0.05, function(tmr:FlxTimer)
						{
							validatePlayerAttack();
						});

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

				if (controls.SPECIAL_P)
					startPlayerAttack('special');
			}

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

			if (combatEnemyHealthBar.percent >= 75)
				postureHealthCoefficient = 1;
			else if (combatEnemyHealthBar.percent >= 50 && combatEnemyHealthBar.percent < 75)
				postureHealthCoefficient = 0.66;
			else if (combatEnemyHealthBar.percent >= 0 && combatEnemyHealthBar.percent < 50)
				postureHealthCoefficient = 0.33;

			if (!posturePause && enemyPostureMechanic)
				dad.posture -= (elapsed * 8 * dad.postureRecoveryCoefficient * postureHealthCoefficient);

			if (!boyfriend.deathByStamina)
			{
				if (PlayState.instance.health <= 0)
					PlayState.instance.health = 0;

				PlayState.instance.health += (elapsed / 10);
			}

			if (enemyPostureBar != null)
			{
				if (dad.posture <= 0)
					dad.posture = 0;
				if (dad.posture >= dad.postureMax)
					dad.posture = dad.postureMax;
			}

			if (boyfriend.combatHealth >= combatPlayerHealthBar.bounds.max)
				boyfriend.combatHealth = combatPlayerHealthBar.bounds.max;

			if (boyfriend.combatHealth < 0)
				boyfriend.combatHealth = 0;

			if (dad.combatHealth >= combatEnemyHealthBar.bounds.max)
				dad.combatHealth = combatEnemyHealthBar.bounds.max;

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
		var leftGuardX:Float = 0;
		var upGuardY:Float = 0;
		for (i in 0...3)
		{
			var guardArrow:FlxSprite = new FlxSprite(50, 450);
			if (ClientPrefs.data.downScroll)
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
			attackTypeIndicator.frames = Paths.getSparrowAtlas('guards/fnfStyle/indicator');
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

	public function generateCombatBar(character:String, barType:String):Void
	{
		var barX:Float = 16;
		var barY:Float = 10;

		var barColorEmpty = 0xFFFF0000;
		var barColorFill = 0xFF66FF33;

		switch (barType)
		{
			case 'combatHealth':
				// L i t e r a l l y  nothing
			case 'posture':
				barY = PlayState.instance.healthBar.y - 36;
				barColorEmpty = 0xFF503838;
				barColorFill = 0xFFFDFF6E;
		}

		var bar = null;

		switch (character)
		{
			case 'player':
				barX += FlxG.width / 2;

				switch (barType)
				{
					case 'combatHealth':
						bar = new Bar(barX, barY, 'healthBar', function() return boyfriend.combatHealth, 0, boyfriend.combatHealthMax);
					case 'posture':
						bar = new Bar(barX, barY, 'healthBar', function() return boyfriend.posture, 0, boyfriend.postureMax);
				}
			case 'enemy':
				if (characterFlipSide)
					barX += FlxG.width / 2;

				switch (barType)
				{
					case 'combatHealth':
						bar = new Bar(barX, barY, 'healthBar', function() return dad.combatHealth, 0, dad.combatHealthMax);
					case 'posture':
						bar = new Bar(barX, barY, 'healthBar', function() return dad.posture, 0, dad.postureMax);
				}
		}

		bar.scale.set(0.5, 1);
		bar.scrollFactor.set();
		bar.setColors(barColorFill, barColorEmpty);

		combatUI.add(bar);

		switch (character)
		{
			case 'player':
				switch (barType)
				{
					case 'combatHealth':
						combatPlayerHealthBar = bar;
					case 'posture':
						playerPostureBar = bar;
				}
			case 'enemy':
				switch (barType)
				{
					case 'combatHealth':
						combatEnemyHealthBar = bar;
					case 'posture':
						enemyPostureBar = bar;
				}
		}
	}

	function evaluateCombatNotes():Void
	{
		var attackNoteToIndicate:Note = getSoonestNote('indicateNote');

		if (!enemyAttackIndicated)
		{
			if (attackNoteToIndicate != null)
			{
				if (attackNoteToIndicate.noteData != 1)
					dad.guardPosition = attackNoteToIndicate.noteData;

				if (attackNoteToIndicate.isSpecialNote || attackNoteToIndicate.isUnblockable)
				{
					if (dad.currentAction != 'bashed')
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
				if (daNote.wasGoodHit)
				{
					switch (daNote.noteType)
					{
						case 'Attack Note' | "attack":
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
								attackName = 'enemy_sing_special';

							attackData = dad.attackMap.get(attackName);

							if (!daNote.isSustainNote && attackData != null)
								executeEnemyAttack(attackData, ignoreIsBashed, daNote.noteData, forceUnblockable, deathNoteAttack);
						case 'Attack Startup' | "wind":
							if (dad.currentAction != 'bashed')
							{
								if (daNote.noteData != 1)
									dad.guardPosition = daNote.noteData;

								dad.playAnim(appendDirection('combatWind', daNote.noteData, true) + (daNote.isUnblockable ? 'unblockable' : ''), true);
							}
						case "shortwind":
							if (daNote.noteData != 1)
								dad.guardPosition = daNote.noteData;

							if (dad.animation.getByName(appendDirection('combatWindshort', daNote.noteData, true)
								+ (daNote.isUnblockable ? 'unblockable' : '')) == null)
								dad.playAnim(appendDirection('combatWind', daNote.noteData, true) + (daNote.isUnblockable ? 'unblockable' : ''), true);
							else
								dad.playAnim(appendDirection('combatWindshort', daNote.noteData, true) + (daNote.isUnblockable ? 'unblockable' : ''), true);
						default:
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
							updateGuardUI(enemyGuard, 'normal');
					}
				}
			}
		});
	}

	function determinePlayerChain(input:String):String
	{
		var nextAttack:String = 'attack';
		var inputAttack:String = input;

		nextAttack = inputAttack;

		playerInputChainArray.push(input);

		if (playerInputChainArray.length > 0)
			nextAttack = checkPlayerChain(input);

		if (nextAttack == null || playerInputChainArray.length == 0)
		{
			resetPlayerChain();
			playerInputChainArray.push(input);
			nextAttack = inputAttack;
		}

		++boyfriend.placeInChain;

		if (chainTimer.active)
			chainTimer.reset();
		else
			chainTimer = new FlxTimer().start(boyfriend.currentAttack.chain_duration, function(tmr:FlxTimer)
			{
				resetPlayerChain();
			});

		return nextAttack;
	}

	/**
	 * Iterates through the player's chains to find if the current input sequence has a match
	 * 
	 * This is its own function largely so nextAttack in determinePlayerChain() becomes null if no matches are found
	 */
	function checkPlayerChain(input:String):String
	{
		var nextAttack:String = null;

		for (chain in boyfriend.chainMap.iterator())
		{
			for (i in 0...chain.input_chain.length)
			{
				var shouldBreak:Bool = false;

				if (chain.input_chain[i] != playerInputChainArray[i])
					shouldBreak = true;
				if (chain.include_sing_attacks && chain.input_chain[i] == 'sing_' + playerInputChainArray[i])
					shouldBreak = false;

				if (shouldBreak)
					break;

				if (i != boyfriend.placeInChain)
					continue;

				// Reaching this point proves the chain is a match
				if (i >= chain.input_chain.length)
					resetPlayerChain();
				else
				{
					nextAttack = chain.attack_chain[boyfriend.placeInChain];
					boyfriend.currentChain = chain;
					break;
				}
			}
		}

		return nextAttack;
	}

	function resetPlayerChain():Void
	{
		boyfriend.placeInChain = 0;
		playerInputChainArray = [];
		boyfriend.currentChain = {
			name: 'neutral',
			directions: [],
			include_sing_attacks: false,
			choice_weight: 1,
			input_chain: [],
			attack_chain: []
		};
		chainTimer.cancel();
	}

	public function determinePlayerAttack(?attackName:String):AttackData
	{
		var currentAttack:AttackData = null;

		currentAttack = boyfriend.attackMap.get(attackName);

		if (currentAttack == null)
			currentAttack = boyfriend.attackMap.get('basic_attack');
		if (currentAttack == null)
			currentAttack = boyfriend.attackMap.get('player_sing_attack');
		if (currentAttack == null)
			currentAttack = Character.generateAttack(null);

		return currentAttack;
	}

	/**
	 * Gets an effect from a character's effect array
	 * @param character The character performing the attack
	 * @param effect Valid effects: 'onComplete', 'onHit', 'onBlock', 'onParry'
	 * @param attack Optionally check a specific attack. Can be left null to check the character's currentAttack
	 * @return AttackEffectData
	 */
	function getAttackEffect(character:Character, effect:String, ?attack:Null<AttackData>):Null<AttackEffectData>
	{
		var effectName:Null<String> = null;

		if (attack == null)
			attack = character.currentAttack;
		if (attack != null)
			switch (effect)
			{
				case 'onComplete':
					effectName = attack.on_complete;
				case 'onHit':
					effectName = attack.on_hit;
				case 'onBlock':
					effectName = attack.on_block;
				case 'onParry':
					effectName = attack.on_parry;
				case 'onMiss':
					effectName = attack.on_miss;
			}

		var attackEffectData:Null<AttackEffectData> = null;

		if (effectName != null)
			attackEffectData = character.attackEffectMap.get(effectName);

		if (attackEffectData == null)
			return null;

		var currentEffect:AttackEffectData = {
			name: attackEffectData?.name,
			damage: attackEffectData?.damage ?? 0,
			posture_damage: attackEffectData?.posture_damage,
			stamina_damage: attackEffectData?.stamina_damage ?? 0,
			stamina_cost: attackEffectData?.stamina_cost ?? 0,
			health_recover: attackEffectData?.health_recover ?? 0,
			posture_recover: attackEffectData?.posture_recover ?? 0,
			step_based_timing: attackEffectData?.step_based_timing ?? false,
			recovery: attackEffectData?.recovery ?? 0,
			hitstun: attackEffectData?.hitstun,
			sound: attackEffectData?.sound ?? ''
		}

		return currentEffect;
	}

	function getDefenseEffect(character:Character, effect:String = 'context', ?attack:Null<AttackData>):Null<DefendEffectData>
	{
		var effectName:Null<String> = null;
		var generalEffectName:Null<String> = null;

		if (attack == null)
			attack = character.currentAttack;
		if (attack != null)
		{
			switch (effect)
			{
				case 'startup':
					effectName = attack.on_startup_defense;
				case 'recovery':
					effectName = attack.on_recovery_defense;
				default:
					switch (character.currentAction)
					{
						case 'startup' | 'stepStartup':
							effectName = attack.on_startup_defense;
						case 'recovery' | 'stepRecovery':
							effectName = attack.on_recovery_defense;
						default:
							return null;
					}
			}

			generalEffectName = attack.on_defense;
		}

		var defendEffectData:Null<DefendEffectData> = null;
		var generalDefendEffectData:Null<DefendEffectData> = null;

		if (effectName != null)
			defendEffectData = character.defendEffectMap.get(effectName);

		if (generalEffectName != null)
			generalDefendEffectData = character.defendEffectMap.get(generalEffectName);

		if (defendEffectData == null)
			defendEffectData = generalDefendEffectData;
		if (defendEffectData == null)
			return null;

		var currentEffect:DefendEffectData = {
			name: defendEffectData?.name,
			uninterruptible: defendEffectData?.uninterruptible ?? generalDefendEffectData?.uninterruptible ?? false,
			can_block: defendEffectData?.can_block ?? generalDefendEffectData?.can_block ?? true,
			can_parry: defendEffectData?.can_parry ?? generalDefendEffectData?.can_parry ?? false,
			can_dodge: defendEffectData?.can_dodge ?? generalDefendEffectData?.can_dodge ?? false
		}

		return currentEffect;
	}

	/**
	 * Applies all stats of an attack effect at once.
	 * @param blockStunAttack If true, reapplies blockStun action on enemy with effect's hitstun instead
	 */
	function applyAttackEffect(attackEffect:AttackEffectData, attacker:Character, blockStunAttack:Bool = false, opponentUninterruptible:Null<Bool> = false):Void
	{
		if (attackEffect == null)
			return;

		if (opponentUninterruptible == null)
			opponentUninterruptible = false;

		var defender:Character = dad;

		if (attacker == dad)
			defender = boyfriend;

		if (attacker == boyfriend)
			damagePosture(attackEffect.posture_damage);

		reduceHealth(defender, attackEffect.damage);

		if (defender == boyfriend)
			PlayState.instance.health -= attackEffect.stamina_damage;
		if (attacker == boyfriend)
			PlayState.instance.health -= attackEffect.stamina_cost;

		attacker.combatHealth += attackEffect.health_recover;
		attacker.posture += attackEffect.posture_recover;

		if (attackEffect.hitstun != null && !opponentUninterruptible && !attacker.currentAttack.not_an_attack && !blockStunAttack)
			inflictHitstun(defender, attackEffect.hitstun);

		if (blockStunAttack)
			enemyBlockStun(attackEffect.hitstun);

		attacker.playSoundEffect(attackEffect.sound);
	}

	function validatePlayerAttack():Void
	{
		var executeAttack:Bool = true;

		var soonestNote:Note = getSoonestNote('bufferCheck', true);

		if (soonestNote != null && boyfriend.currentAction != 'hasHitNote')
		{
			var duration:Float = (soonestNote.strumTime - Conductor.songPosition + Conductor.safeZoneOffset * soonestNote.lateHitMult) / 500;

			changeAction(boyfriend, 'bufferNoteAttack', duration, function(tmr:FlxTimer)
			{
				boyfriend.currentAction = 'neutral';
			});

			return;
		}

		switch (boyfriend.currentAction)
		{
			case 'recovery' | 'hitstun':
				if (boyfriend.actionTimer.timeLeft <= 0.2)
				{
					boyfriend.actionTimer.onComplete = function(tmr:FlxTimer)
					{
						startPlayerAttack();
					};
				}

				executeAttack = false;
			case 'startup':
				playerAttackPosition = boyfriend.guardPosition;
				executeAttack = false;
		}

		if (characterIsStartingAttack(dad)
			&& !dad.currentAttack.is_feint
			&& !dad.currentAttack.not_an_attack
			&& dad.currentAction != 'bashed'
			&& dad.currentAttack.direction != 'SPECIAL')
		{
			var hasParried = false;
			var timeUntilAttack:Float = 0;

			if (dad.currentAction == 'startup' && dad.guardPosition == boyfriend.guardPosition)
			{
				if (dad.actionTimer.timeLeft <= 0.5)
				{
					hasParried = true;
					timeUntilAttack = dad.actionTimer.timeLeft;
				}
			}
			else if (dad.currentAction == 'stepStartup' && dad.guardPosition == boyfriend.guardPosition)
			{
				var timeCounter:Float = 0;
				var parryWindow:Int = 0;
				while (timeCounter < 0.7)
				{
					timeCounter += stepTimerCrochet;
					++parryWindow;
				}

				if (dad.actionStepTimer <= parryWindow)
				{
					hasParried = true;
					timeUntilAttack = parryWindow;
				}
			}
			else
			{
				var noteToParry:Note = getSoonestNote('isCombatNote');

				if (noteToParry != null && noteToParry.noteData == boyfriend.guardPosition)
				{
					hasParried = true;
					timeUntilAttack = (noteToParry.strumTime - Conductor.songPosition + Conductor.safeZoneOffset * noteToParry.lateHitMult) / 1000;
				}
			}

			if (hasParried)
			{
				executeAttack = false;

				changeAction(boyfriend, 'hasParried', timeUntilAttack, function(tmr:FlxTimer)
				{
					boyfriend.currentAction = 'neutral';
				});
			}
		}

		if (executeAttack || boyfriend.currentAction == 'hasHitNote')
		{
			if (boyfriend.deathByStamina && !debugGodMode)
			{
				if (PlayState.instance.health > (boyfriend.currentAttack.stamina_cost * 3)
					&& PlayState.instance.health <= (boyfriend.currentAttack.stamina_cost * 4))
					boyfriend.playSoundEffect(boyfriend.characterSounds.out_of_stamina, 0.4);
				else if (PlayState.instance.health > (boyfriend.currentAttack.stamina_cost * 2)
					&& PlayState.instance.health <= (boyfriend.currentAttack.stamina_cost * 3))
					boyfriend.playSoundEffect(boyfriend.characterSounds.out_of_stamina, 0.7);
				else if (PlayState.instance.health <= (boyfriend.currentAttack.stamina_cost * 2))
					boyfriend.playSoundEffect(boyfriend.characterSounds.out_of_stamina);
			}

			startPlayerAttack();
		}
	}

	function startPlayerAttack(input:String = 'attack', noteAttack:Bool = false):Void
	{
		if (boyfriend.currentAction == 'hasParried' && boyfriend.currentAction != 'hasHitNote')
			return;

		if (boyfriend.currentAction == 'hasHitNote' && !hasSustainAttacked)
		{
			input = 'sing_' + input;
		}
		else
			cancelSingGuard();

		boyfriend.currentAttack = determinePlayerAttack(determinePlayerChain(input));

		// Sustain notes trigger hasSustainAttacked to remove sing properties if more than one attack is thrown
		// Basically this is to prevent spamming attack during a sustain note from being optimal
		if (boyfriend.currentAction == 'hasHitNote')
			hasSustainAttacked = true;

		PlayState.instance.callOnLuas('onStartingAttack', ['boyfriend', boyfriend.currentAttack]);
		PlayState.instance.callOnLuas('onStartingPlayerAttack', [input, boyfriend.currentAttack]);

		if (noteAttack)
			boyfriend.currentAttack.stamina_cost = 0;

		PlayState.instance.health -= boyfriend.currentAttack.stamina_cost;

		if (!downAttackPositionShift)
			playerAttackPosition = boyfriend.guardPosition;

		downAttackPositionShiftFunction();

		moveCharacterToFront();

		cancelDodge();

		if (boyfriend.currentAttack.duration <= 0)
		{
			if (!boyfriend.currentAttack.not_an_attack)
			{
				if (dad.guardPosition == playerAttackPosition)
					enemyBlockStun();
				else if (dad.currentAction != 'blockStun')
					dad.guardPosition = playerAttackPosition;
			}

			executePlayerAttack();
		}
		else
		{
			if (boyfriend.currentAttack.direction == 'ANY')
				boyfriend.playAnim(appendDirection(boyfriend.currentAttack.startup_animation_name, playerAttackPosition, true)
					+ (boyfriend.currentAttack.is_unblockable ? 'unblockable' : ''),
					true);
			else
				boyfriend.playAnim(boyfriend.currentAttack.startup_animation_name
					+ boyfriend.currentAttack.direction
					+ (boyfriend.currentAttack.is_unblockable ? 'unblockable' : ''),
					true);

			changeAction(boyfriend, 'startup',
				boyfriend.currentAttack.step_based_timing ? boyfriend.currentAttack.duration * stepTimerCrochet : boyfriend.currentAttack.duration,
				function(tmr:FlxTimer)
				{
					executePlayerAttack();
				});

			if (!boyfriend.currentAttack.not_an_attack)
			{
				switch (dad.currentAction)
				{
					case 'blockStun' | 'recovery' | 'stepRecovery' | 'feint':
						dad.actionTimer.onComplete = function(tmr:FlxTimer)
						{
							enemyStartDefense();
						}
					case 'neutral' | 'hitstun':
						enemyStartDefense();
				}
			}
		}

		updateGuardUI(enemyGuard, 'normal');
	}

	function executePlayerAttack():Void
	{
		PlayState.instance.callOnLuas('onExecutingAttack', ['boyfriend', boyfriend.currentAttack]);
		applyAttackEffect(getAttackEffect(boyfriend, 'onComplete'), boyfriend);

		if (boyfriend.currentAttack.direction == 'ANY')
			boyfriend.playAnim(appendDirection(boyfriend.currentAttack.attack_animation_name, playerAttackPosition, true)
				+ (boyfriend.currentAttack.is_unblockable ? 'unblockable' : ''),
				true);
		else
			boyfriend.playAnim(boyfriend.currentAttack.attack_animation_name
				+ boyfriend.currentAttack.direction
				+ (boyfriend.currentAttack.is_unblockable ? 'unblockable' : ''),
				true);

		if (boyfriend.currentAttack.recovery > 0)
		{
			changeAction(boyfriend, 'recovery',
				boyfriend.currentAttack.step_based_timing ? boyfriend.currentAttack.recovery * stepTimerCrochet : boyfriend.currentAttack.recovery,
				function(tmr:FlxTimer)
				{
					boyfriend.currentAction = 'neutral';
				});
		}
		else
			boyfriend.currentAction = 'neutral';

		if (boyfriend.currentAttack.not_an_attack)
			return;

		PlayState.instance.callOnLuas('onAttacked', ['dad', boyfriend.currentAttack]);

		var enemyDefendEffect:Null<DefendEffectData> = getDefenseEffect(dad);

		if (dad.currentAction == 'dodge' || (enemyDefendEffect != null && enemyDefendEffect.can_dodge))
		{
			if (dad.currentAction == 'dodge')
				dad.playAnim('combatDodge', true);

			PlayState.instance.callOnLuas('onDodge', ['dad', boyfriend.currentAttack]);
			PlayState.instance.callOnLuas('onMiss', ['boyfriend', boyfriend.currentAttack]);
			applyAttackEffect(getAttackEffect(boyfriend, 'onMiss'), boyfriend);

			boyfriend.playSoundEffect(boyfriend.currentAttack.sound_on_miss);
		}
		else if ((enemyDefendEffect == null || enemyDefendEffect.can_block)
			&& ((boyfriend.guardPosition == dad.guardPosition && !boyfriend.currentAttack.is_unblockable && dad.currentAction != 'bashed')
				|| characterIsStartingAttack(dad)
				|| dad.currentAction == 'recovery'
				|| dad.currentAction == 'stepRecovery'
				|| dad.currentAction == 'hasParried'))
		{
			if (dad.currentAction == 'hasParried' || (enemyDefendEffect != null && enemyDefendEffect.can_parry))
				playerAttackParried();
			else
				playerAttackBlocked();
		}
		else
			playerAttackLand();

		if (!boyfriend.currentAttack.not_an_attack && !characterIsStartingAttack(dad))
			determineEnemyChain(true);

		updateGuardUI(enemyGuard, 'normal');
	}

	public function determineEnemyChain(forceChainChange:Bool = false):Void
	{
		if (dad.placeInChain > dad.currentChain.attack_chain.length - 1 || forceChainChange)
		{
			var count:Int = 0;
			for (chain in dad.chainMap.iterator())
			{
				if (chain.choice_weight <= 0)
					continue;

				count += chain.choice_weight;
			}

			var chosenChain:Int = Std.random(count) + 1;
			count = 0;

			for (chain in dad.chainMap.iterator())
			{
				if (chain.choice_weight <= 0)
					continue;

				count += chain.choice_weight;
				if (chosenChain >= count && chosenChain < count + chain.choice_weight)
				{
					if (avoidStaleChains && dad.currentChain == chain && Math.random() < avoidStaleChainOdds)
					{
						determineEnemyChain(true);
						return;
					}
					dad.currentChain = chain;
					break;
				}
			}

			if (dad.currentChain == null)
				dad.currentChain = {
					name: 'nullChain',
					directions: null,
					include_sing_attacks: false,
					choice_weight: 1,
					input_chain: null,
					attack_chain: ['basic_attack']
				}

			dad.placeInChain = 0;

			PlayState.instance.callOnLuas('onDetermineEnemyChain', [dad.currentChain, dad.placeInChain]);
			chooseEnemyAttack();
		}
	}

	public function resetEnemyChain():Void
	{
		dad.placeInChain = 0;
		dad.currentChain =
			{
				dad.currentChain = {
					name: 'neutral',
					directions: [],
					include_sing_attacks: false,
					choice_weight: 1,
					input_chain: [],
					attack_chain: []
				};
			};
	}

	public function chooseEnemyAttack():Void
	{
		if (dad.placeInChain > dad.currentChain.attack_chain.length - 1)
		{
			determineEnemyChain();
			return;
		}

		dad.currentAttack = dad.attackMap.get(dad.currentChain.attack_chain[dad.placeInChain]);

		if (dad.currentChain.directions == null)
			return;

		if (dad.currentChain.directions[dad.placeInChain] == 'LEFT'
			|| dad.currentChain.directions[dad.placeInChain] == 'UP'
			|| dad.currentChain.directions[dad.placeInChain] == 'RIGHT')
			dad.currentAttack.direction = dad.currentChain.directions[dad.placeInChain];
	}

	// This exists mainly for setting an attack directly through lua
	public function luaChangeEnemyAttack(attackName:String)
	{
		if (attackName == null)
			return;

		startEnemyAttack(dad.attackMap.get(attackName));
	}

	public function startEnemyAttack(attack:Null<AttackData> = null):Void
	{
		if (attack != null)
		{
			dad.currentAttack = attack;
			resetEnemyChain();
			dad.currentChain.attack_chain.push(attack.name);
		}

		PlayState.instance.callOnLuas('onStartingAttack', ['dad', dad.currentAttack]);

		var currentDirection:Int = 0;

		if (dad.currentAttack.duration > 0)
		{
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
				if (dad.actionTimer.active)
					dad.actionTimer.cancel();
			}
			else
			{
				changeAction(dad, 'startup', dad.currentAttack.duration, function(tmr:FlxTimer)
				{
					executeEnemyAttack();
				});
			}
		}
		else
			executeEnemyAttack();
	}

	function executeEnemyAttack(?attackData:AttackData, ignoreIsBashed:Bool = false, ?attackDirectionInt:Int, forceUnblockable:Bool = false,
			deathNoteAttack:Bool = false):Void
	{
		if (dad.currentAction == 'bashed' && !ignoreIsBashed)
			return;

		if (attackData == null)
			attackData = dad.currentAttack;

		enemyAttackIndicated = false;

		PlayState.instance.callOnLuas('onExecutingAttack', ['dad', dad.currentAttack]);

		changeAction(dad, 'feint', dad.currentAttack.recovery, function(tmr:FlxTimer)
		{
			dad.currentAction = 'neutral';
		});

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
				case 'ANY':
					attackDirectionInt = FlxG.random.int(0, 2);
					if (attackDirectionInt > 0)
						++attackDirectionInt;
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

		if (attackDirectionInt != 1)
			dad.guardPosition = attackDirectionInt;

		var attackAnimationName:String = '';

		if (attackData.append_direction_to_anim_name || attackData.direction == 'ANY')
			attackAnimationName = appendDirection(attackData.attack_animation_name, attackDirectionInt, true);
		else
			attackAnimationName = attackData.attack_animation_name;

		if (forceUnblockable)
			attackAnimationName += 'unblockable';

		dad.playAnim(attackAnimationName, true);

		if (dad.currentAttack.is_feint)
		{
			dad.playSoundEffect(attackData.sound_on_hit);
			determineEnemyChain(true);
			updateGuardUI(enemyGuard, 'normal');
			return;
		}

		applyAttackEffect(getAttackEffect(dad, 'onComplete'), dad);

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

		if (!attackData.not_an_attack)
			PlayState.instance.callOnLuas('onAttacked', ['boyfriend', dad.currentAttack]);

		var playerDefendEffect:Null<DefendEffectData> = getDefenseEffect(boyfriend);
		var attackEffectApplied:String = '';

		if (attackData.not_an_attack)
		{
			dad.playSoundEffect(attackData.sound_on_hit);
		}
		else if (attackData.direction == 'SPECIAL' || (playerDefendEffect != null && playerDefendEffect.can_dodge))
		{
			if (isDodge || singGuard)
			{
				PlayState.instance.callOnLuas('onDefend', ['boyfriend', dad.currentAttack]);
				PlayState.instance.callOnLuas('onDodge', ['boyfriend', dad.currentAttack]);
				applyAttackEffect(getAttackEffect(dad, 'onMiss'), dad);
				attackEffectApplied = 'onMiss';

				// The weapon the enemy is using likely has a greater influence on the kind of sound,
				// Compared to the player character's dodging method
				// Thus the sound is checking dad instead of boyfriend
				dad.playSoundEffect(attackData.sound_on_miss);

				if (!boyfriend.animation.curAnim.name.startsWith('sing'))
					boyfriend.playAnim('combatDodge', true);
			}
			else
			{
				// PlayState.instance.health -= 0.5;
				// dad.playSoundEffect(attackData.sound_on_hit);
				// boyfriend.playSoundEffect(boyfriend.characterSounds.struck);
				// boyfriend.playAnim('combatHit', true);

				enemyAttackLand(attackData);
			}
		}
		else if ((attackData.is_unblockable || forceUnblockable) && boyfriend.currentAction != 'hasParried' && !singGuard)
		{
			enemyAttackLand(attackData);
			attackEffectApplied = 'onHit';
		}
		else if ((dad.guardPosition != boyfriend.guardPosition) && !singGuard || !playerGuardActive && !singGuard)
		{
			enemyAttackLand(attackData);
			attackEffectApplied = 'onHit';
		}
		else if (boyfriend.currentAction == 'hasParried' && (boyfriend.guardPosition == dad.guardPosition))
		{
			PlayState.instance.callOnLuas('onDefend', ['boyfriend', dad.currentAttack]);
			PlayState.instance.callOnLuas('onParry', ['boyfriend', dad.currentAttack]);
			applyAttackEffect(getAttackEffect(dad, 'onParry'), dad);
			attackEffectApplied = 'onParry';

			boyfriend.playSoundEffect(boyfriend.characterSounds.parry);
			damagePosture();

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
			PlayState.instance.callOnLuas('onDefend', ['boyfriend', dad.currentAttack]);
			PlayState.instance.callOnLuas('onBlock', ['boyfriend', dad.currentAttack]);
			applyAttackEffect(getAttackEffect(dad, 'onBlock'), dad);
			attackEffectApplied = 'onBlock';

			if (manuallySwitchedGuard && boyfriend.guardPosition > 0)
				achievementBlockedNonLeftAttack = true;

			boyfriend.playSoundEffect(boyfriend.characterSounds.block);

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

		if (!dad.currentAttack.not_an_attack)
		{
			if (attackEffectApplied == '' || getAttackEffect(dad, attackEffectApplied)?.hitstun == null)
				inflictHitstun(boyfriend);
			resetPlayerChain();
			cancelDodge();
		}

		var enemyDefendEffect:Null<DefendEffectData> = getDefenseEffect(dad, 'recovery');

		if (enemyDefendEffect != null && !enemyDefendEffect.can_block)
			updateGuardUI(enemyGuard, 'inactive');
		else
			updateGuardUI(enemyGuard, 'normal');

		if (dad.currentAttack.step_based_timing)
		{
			dad.currentAction = 'stepRecovery';
			dad.actionStepTimer = 0;
			if (dad.actionTimer.active)
				dad.actionTimer.cancel();
		}
		else
			changeAction(dad, 'recovery', dad.currentAttack.recovery, function(tmr:FlxTimer)
			{
				if (enemyOnOffense)
					enemyContinueChain();
				else
					dad.currentAction = 'neutral';

				updateGuardUI(enemyGuard, 'normal');
			});

		if (!playerGuardActive && !singGuard)
			updateGuardUI(playerGuard, 'inactive');
	}

	function enemyBlockStun(?hitstunDuration:Null<Float>, stepBasedTiming:Bool = false):Void
	{
		var blockStunDuration:Float = 0.7;

		changeAction(dad, 'blockStun', blockStunDuration);

		if (hitstunDuration == null)
		{
			hitstunDuration = boyfriend.currentAttack.hitstun;
			if (boyfriend.currentAttack.step_based_timing)
				hitstunDuration *= stepTimerCrochet;
		}
		else if (stepBasedTiming)
			hitstunDuration *= stepTimerCrochet;

		if (hitstunDuration > blockStunDuration)
		{
			hitstunDuration -= blockStunDuration;

			dad.actionTimer.onComplete = function(tmr:FlxTimer)
			{
				inflictHitstun(dad, hitstunDuration);
			}
		}
		else
			dad.actionTimer.onComplete = function(tmr:FlxTimer)
			{
				dad.currentAction = 'neutral';
			}
	}

	function enemyStartDefense():Void
	{
		if (dad.guardPosition != playerAttackPosition)
		{
			switchGuard(enemyGuard, 'normal', playerAttackPosition);
			changeAction(dad, 'swappingGuard', boyfriend.currentAttack.duration);
		}
		else
			changeAction(dad, 'defending', boyfriend.currentAttack.duration);

		dad.actionTimer.onComplete = function(tmr:FlxTimer)
		{
			if (dad.currentAction == 'swappingGuard')
			{
				changeAction(dad, 'defending', boyfriend.actionTimer.timeLeft + 0.5, function(tmr:FlxTimer)
				{
					dad.currentAction = 'neutral';
				});
			}
			else
				dad.currentAction = 'neutral';
		}
	}

	function enemyContinueChain():Void
	{
		dad.currentAction = 'neutral';
		++dad.placeInChain;
		chooseEnemyAttack();
		startEnemyAttack();
	}

	function enemyAttackLand(attackData:AttackData):Void
	{
		PlayState.instance.callOnLuas('onHit', ['boyfriend', dad.currentAttack]);
		applyAttackEffect(getAttackEffect(dad, 'onHit'), dad);

		reduceHealth(boyfriend, attackData.damage);
		PlayState.instance.health -= attackData.stamina_damage;

		if (boyfriend.hasReflexGuard)
			playerGuardActive = false;

		dad.playSoundEffect(attackData.sound_on_hit);
		boyfriend.playSoundEffect(boyfriend.characterSounds.struck);

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

		cameraBounce(attackData.direction == 'SPECIAL' ? 1 : dad.guardPosition);
	}

	function playerAttackBlocked():Void
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

		if (dad.guardPosition == playerAttackPosition && dad.currentAction != 'swappingGuard')
		{
			enemyBlockStun();

			var newPosition:Int = FlxG.random.int(0, 2);
			if (newPosition > 0)
				++newPosition;

			// If the player hit off-guard to force a match, imposes 50/50 to stay the same side
			// In other words this is to prevent spamming a single side from being too effective
			if (enemyMatchedPlayerGuard && FlxG.random.int(0, 1) == 1)
				newPosition = playerAttackPosition;
			// Re-randomizing once to decrease chance that guard sticks to one side
			else if (newPosition == playerAttackPosition)
			{
				newPosition = FlxG.random.int(0, 2);
				if (newPosition > 0)
					++newPosition;
			}

			enemyMatchedPlayerGuard = false;

			dad.guardPosition = newPosition;
		}
		else
		{
			dad.guardPosition = playerAttackPosition;
			enemyMatchedPlayerGuard = true;
		}

		PlayState.instance.callOnLuas('onDefend', ['dad', boyfriend.currentAttack]);
		PlayState.instance.callOnLuas('onBlock', ['dad', boyfriend.currentAttack]);

		dad.playSoundEffect(dad.characterSounds.block);

		var effect:AttackEffectData = getAttackEffect(boyfriend, 'onBlock');

		if (effect != null)
		{
			if (effect.posture_damage == null)
				damagePosture();

			var blockStunAttack:Bool = false;
			if (dad.currentAction == 'blockStun')
				blockStunAttack = true;

			applyAttackEffect(effect, boyfriend, blockStunAttack);
		}
		else
		{
			if (dad.currentAction != 'blockStun')
				inflictHitstun(dad);
			damagePosture();
		}
	}

	function playerAttackParried():Void
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

		dad.guardPosition = playerAttackPosition;
		boyfriend.playAnim('combatHit', true);

		PlayState.instance.callOnLuas('onDefend', ['dad', boyfriend.currentAttack]);
		PlayState.instance.callOnLuas('onParry', ['dad', boyfriend.currentAttack]);

		dad.playSoundEffect(dad.characterSounds.parry);

		var effect:AttackEffectData = getAttackEffect(boyfriend, 'onParry');

		if (effect != null)
		{
			if (effect.posture_damage != null)
				damagePosture();

			applyAttackEffect(effect, boyfriend);
		}
	}

	function playerAttackLand():Void
	{
		dad.guardPosition = playerAttackPosition;

		switch (playerAttackPosition)
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

		dad.actionTimer.cancel();

		PlayState.instance.callOnLuas('onHit', ['dad', boyfriend.currentAttack]);

		var effect:AttackEffectData = getAttackEffect(boyfriend, 'onHit');

		// Intentionally done before potentially applying posture damage
		if (enemyPostureMechanic && dad.posture >= dad.postureMax && dad.currentAction == 'bashed')
		{
			dad.posture -= (dad.postureMax / 2);

			boyfriend.playSoundEffect('postureBreak');
			cameraBounce(playerAttackPosition);

			if (effect != null)
			{
				if (effect.damage != null)
					effect.damage *= 5;
				effect.posture_damage = 0;
				applyAttackEffect(effect, boyfriend);
			}
			else
			{
				reduceHealth(dad, boyfriend.currentAttack.damage * 5);
				inflictHitstun(dad);
			}
		}
		else
		{
			if (effect != null)
				applyAttackEffect(effect, boyfriend, false, getDefenseEffect(dad).uninterruptible);
			else
			{
				boyfriend.playSoundEffect(boyfriend.currentAttack.sound_on_hit);
				dad.playSoundEffect(dad.characterSounds.struck);
				reduceHealth(dad, boyfriend.currentAttack.damage);

				var enemyDefendEffect:Null<DefendEffectData> = null;

				if (characterIsStartingAttack(dad))
					enemyDefendEffect = getDefenseEffect(dad);

				if (enemyDefendEffect == null || (enemyDefendEffect != null && !enemyDefendEffect.uninterruptible))
					inflictHitstun(dad);
			}
		}
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

			// spr.visible = true;
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

	/**
	 * Includes logic for the guard-switch animation in addition to calling updateGuardUI()
	 *
	 * @param characterGuard 	A guard widget sprite group, mainly playerGuard or enemyGuard
	 * @param updateType 		A string to determine which animation for the guard to use. 'normal' animates normal,
	 *							'neutral' is like normal but without the initial flash animation, 'attack' does an orange arrow,
	 *							'inactive' disables all arrows (with the current guard position arrow keeping a black outline),
	 *							and 'singGuard' is a temporary all-guard
	 * @param newGuardPosition
	 * 
	**/
	function switchGuard(characterGuard:FlxTypedGroup<FlxSprite>, updateType:String, newGuardPosition:Int):Void
	{
		var character:Character = null;

		if (characterGuard == playerGuard)
			character = boyfriend;
		else if (characterGuard == enemyGuard)
			character = dad;
		else
			return;

		if (character.hasReflexGuard)
		{
			switch (newGuardPosition)
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
			switch (newGuardPosition)
			{
				case 0:
					switch (character.guardPosition)
					{
						case 2:
							character.playAnim('combatSwapUpLEFT', true);
						case 3:
							character.playAnim('combatSwapRightLEFT', true);
					}
				case 2:
					switch (character.guardPosition)
					{
						case 0:
							character.playAnim('combatSwapLeftUP', true);
						case 3:
							character.playAnim('combatSwapRightUP', true);
					}
				case 3:
					switch (character.guardPosition)
					{
						case 0:
							character.playAnim('combatSwapLeftRIGHT', true);
						case 2:
							character.playAnim('combatSwapUpRIGHT', true);
					}
			}
		}

		character.guardPosition = newGuardPosition;

		if (character == boyfriend && !singGuard || character != boyfriend)
			updateGuardUI(characterGuard, updateType);
	}

	/**
	 * Changes the action of an input character and sets up a timer.
	 * 
	 * Actions are tracked with the currentAction string and actionTimer, both of which are intended to change accordingly to each action.
	 * This means actions are mutually exclusive with each other.
	**/
	public function changeAction(character:Character, actionName:String, actionTimerDuration:Float, ?onComplete:FlxTimer->Void):Void
	{
		if (onComplete == null)
			onComplete = function(tmr:FlxTimer)
			{
				character.currentAction = 'neutral';
			}

		character.currentAction = actionName;
		if (character.actionTimer.active)
			character.actionTimer.reset(actionTimerDuration);
		else
			character.actionTimer.start(actionTimerDuration);

		character.actionTimer.onComplete = onComplete;
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
			if (boyfriend.hasReflexGuard)
				updateGuardUI(playerGuard, 'inactive');
			else
				updateGuardUI(playerGuard, 'neutral');
		});
	}

	function cancelSingGuard():Void
	{
		singGuard = false;
		if (singGuardTimer.active)
			singGuardTimer.reset(0);

		if (boyfriend.hasReflexGuard)
		{
			reflexGuardTimer.cancel();
			playerGuardActive = false;
		}
	}

	public function noteMissCombatPunish():Void
	{
		if (!boyfriend.hasReflexGuard)
			updateGuardUI(playerGuard, 'neutral');

		cancelSingGuard();
	}

	public function noteGoodHitCombat(note:Note):Void
	{
		if (!note.isSustainNote)
			hasSustainAttacked = false;

		if (note.noteData != 1)
			boyfriend.guardPosition = note.noteData;
		manuallySwitchedGuard = false;

		var hasHitNoteDuration:Float = (Conductor.safeZoneOffset * note.lateHitMult) / 1000;
		if (note.isSustainNote)
			hasHitNoteDuration += note.sustainLength / 1000;

		if (!playerIsWaitingToAttack() && (!note.isSustainNote))
			changeAction(boyfriend, 'hasHitNote', hasHitNoteDuration, function(tmr:FlxTimer)
			{
				boyfriend.currentAction = 'neutral';
			});

		// Little animation tidbit to keep down-note attacks from getting monotonous
		if (note.noteData == 1)
		{
			downAttackPositionShift = true;

			// initiateChain();
		}
		else
		{
			downAttackPositionShift = false;
		}

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

		// if (note.noteData == 1)
		//	initiateChain();

		switch (note.noteType)
		{
			case '' | 'normal':
				if (playerIsWaitingToAttack())
				{
					boyfriend.currentAction = 'hasHitNote';
					boyfriend.actionTimer.cancel();

					if (note.noteData == 1)
						startPlayerAttack('special', true);
					else
						startPlayerAttack('attack', true);
				}
			case 'attack':
				// Sound effects playing way off sounds real bad
				// So this "balance" decision is pretty much to remedy that sound issue
				// It's rewarding precision, I swear
				if (note.rating == 'good' || note.rating == 'sick')
				{
					if (note.noteData == 1)
						startPlayerAttack('special', true);
					else
						startPlayerAttack('attack', true);
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

	function playerIsWaitingToAttack():Bool
	{
		if (boyfriend.currentAction == 'bufferNoteAttack' || attackDelayTimer.active)
			return true;
		else
			return false;
	}

	function characterIsStartingAttack(character:Character):Bool
	{
		var actionArray:Array<String> = ['startup', 'stepStartup'];

		if (actionArray.contains(character.currentAction))
			return true;
		else
			return false;
	}

	/**
	 * @param foreCharacterName 'dad' moves dad to front, otherwise defaults to boyfriend
	 */
	public function moveCharacterToFront(?foreCharacterName:String):Void
	{
		var foreCharacter:FlxSpriteGroup;
		var backCharacter:FlxSpriteGroup;

		if (foreCharacterName == 'dad')
		{
			foreCharacter = PlayState.instance.dadGroup;
			backCharacter = PlayState.instance.boyfriendGroup;
		}
		else
		{
			foreCharacter = PlayState.instance.boyfriendGroup;
			backCharacter = PlayState.instance.dadGroup;
		}

		PlayState.instance.members.remove(foreCharacter);
		PlayState.instance.members.insert(PlayState.instance.members.indexOf(backCharacter) + 1, foreCharacter);
	}

	function setupPostureMechanic():Void
	{
		// PlayState.instance.healthBar.visible = false;

		generateCombatBar('player', 'posture');
		generateCombatBar('enemy', 'posture');

		enemyPostureMechanic = true;
	}

	public function setPostureMechanicMode(mode:String = 'disabled', resetPosture:Bool = true)
	{
		switch (mode)
		{
			case 'dad' | 'enemy':
				enemyPostureMechanic = true;

				enemyPostureBar.visible = true;
				longBar(enemyPostureBar);

				playerPostureBar.visible = false;
			case 'boyfriend' | 'player':
				enemyPostureMechanic = false;

				enemyPostureBar.visible = false;

				playerPostureBar.visible = true;
				longBar(playerPostureBar);
			case 'both':
				enemyPostureMechanic = true;

				enemyPostureBar.visible = true;
				shortBar(enemyPostureBar, characterFlipSide);

				playerPostureBar.visible = true;
				shortBar(playerPostureBar, !characterFlipSide);
			default:
				enemyPostureMechanic = false;

				enemyPostureBar.visible = false;
				playerPostureBar.visible = false;
		}

		if (resetPosture)
		{
			dad.posture = 0;
			boyfriend.posture = 0;
		}
	}

	public function longBar(bar:Bar)
	{
		bar.scale.set(1, 1);
		bar.screenCenter(X);
	}

	public function shortBar(bar:Bar, shiftToRight:Bool = false)
	{
		bar.scale.set(0.5, 1);
		bar.x = 16;

		if (shiftToRight)
			bar.x += FlxG.width / 2;
	}

	/**
	 * Posture is only tracked on the enemy
	 */
	function damagePosture(?damage:Float):Void
	{
		if (!enemyPostureMechanic)
			return;

		if (damage == null)
			damage = boyfriend.currentAttack.posture_damage;
		if (damage == null)
			return;

		posturePause = true;

		// Timer length is a constant instead of some kind of stepTimerCrochet to maintain consistency between song speeds

		if (posturePauseTimer.active)
			posturePauseTimer.reset();
		else
			posturePauseTimer.start(3, function(tmr:FlxTimer)
			{
				posturePause = false;
			});

		dad.posture += damage;
	}

	public function inflictHitstun(defender:Character, ?duration:Float, ?forceTiming:String = ''):Void
	{
		var initiator:Character;

		if (defender == boyfriend)
			initiator = dad;
		else
			initiator = boyfriend;

		var currentAttack:AttackData = initiator.currentAttack;

		if (duration == null)
			duration = currentAttack.hitstun;
		if (duration == null)
			return;

		switch (forceTiming)
		{
			case 'seconds':
			case 'steps':
				duration *= stepTimerCrochet;
			default:
				if (currentAttack.step_based_timing)
					duration *= stepTimerCrochet;
		}

		if (defender == boyfriend && currentAttack.is_bash)
			playerGuardActive = false;

		changeAction(defender, currentAttack.is_bash && !isDodge ? 'bashed' : 'hitstun', duration, function(tmr:FlxTimer)
		{
			if (defender == boyfriend && !defender.hasReflexGuard && defender.currentAction == 'bashed')
				playerGuardActive = true;

			defender.currentAction = 'neutral';

			if (defender == dad)
				enemyMatchedPlayerGuard = false;
		});
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

				timerReady = true;
			}
	}*/
	public function combatStepHit():Void
	{
		if (PlayState.instance.generatedMusic)
			if (boyfriend.combatHealth <= boyfriend.combatHealthMax / 2)
				achievementHealthStepCount += 1;

		//
		//
		// dad step logic
		if (!dad.currentAction.startsWith('step'))
			dad.actionStepTimer = 0;

		switch (dad.currentAction)
		{
			case 'neutral':
				if (dad.currentAttack.step_based_timing)
					startEnemyAttack();
			case 'stepStartup':
				if (dad.actionStepTimer >= dad.currentAttack.duration)
					executeEnemyAttack();
			case 'stepRecovery':
				if (dad.actionStepTimer >= dad.currentAttack.recovery)
					enemyContinueChain();
		}

		if (dad.currentAction.startsWith('step'))
			++dad.actionStepTimer;
	}

	/**
	 * Cancels any ongoing dodges and chains
	 */
	function cancelDodge():Void
	{
		isDodgeTimer.cancel();
		isDodge = false;
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
	 * Used for preventing crashes from referencing combat variables.
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

		if (character == dad && amount > 0)
			achievementCumulativeDamage += amount;

		#if ACHIEVEMENTS_ALLOWED
		/*var achieve:String = PlayState.instance.checkForAchievement(['bf_pain', 'shrub_pain']);
			if (achieve != null)
			{
				PlayState.instance.startAchievement(achieve);
				Achievements.unlockAchievement(achieve);
		}*/
		#end
	}
}
