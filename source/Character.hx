package;

import Section.SwagSection;
import animateatlas.AtlasFrameMaker;
import flash.media.Sound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import forfriday.CharacterExtra;
import forfriday.Combat;
import haxe.Json;
import haxe.format.JsonParser;
import openfl.utils.AssetType;
import openfl.utils.Assets;

using StringTools;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;

	// Combat changes
	var death_soundName:String;
	var death_characterName:String;
	var idle_defaultFrame:Int;
	var has_reflexGuard:Bool;
	var has_unblockableNoteAttacks:Bool;
	var stamina_cost:Float;
	var default_guard_position:Int;
	var posture_max:Float;
	var posture_recoveryCoefficient:Float;
	var combat_healthMax:Float;
	var special_attack:String;
	var ifPlayer_damage:Float;
	var ifEnemy_damage:Float;
	var posture_damage:Float;
	var alternatingIdle:Bool;
	var characterExtras:Array<String>;
	var combatSoundEffects:Array<Array<String>>;
	var soundsToPickFromRandom:Array<Array<Dynamic>>;
	var soundsToVaryVolume:Array<Array<Dynamic>>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

// Combat changes
// The changes to this file are the sole exception to the "minimal codebase changes" philosophy,
// As there's far too much potential for streamlining things
// Thankfully this should mostly be additions rather than having to adapt systems
// (with exception to a new animation-check inside playAnim(), and some other things along those lines)
class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;
	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;
	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];
	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var hasMissAnimations:Bool = false;
	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public static var DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	// Combat changes
	// Variables for characters
	public var zDepth:Int = 0;
	public var idleDefaultFrame:Int = 10;
	public var playerOneFlipSide:Bool = false;
	public var alternatingIdle:Bool = false;
	public var guardPosition:Int = 0;
	public var isBashed = false;
	public var hasReflexGuard = true;
	public var hasUnblockableNoteAttacks = true;
	public var special:String = 'recover';
	public var postureMax:Float = 100;
	public var posture:Float = 0;
	public var postureRecoveryCoefficient:Float = 1;
	public var combatHealthMax:Float = 100;
	public var combatHealth:Float = 100;
	public var baseDamage:Float = 2;
	public var staminaCost:Float = 0.2;
	public var postureDamage:Float = 3;
	public var characterSprites:FlxTypedGroup<CharacterExtra> = new FlxTypedGroup<CharacterExtra>();
	public var characterExtraArray:Array<String> = [];

	public var soundEffects:Map<String, String> = new Map();
	public var soundRandomPicks:Map<String, Array<Int>> = new Map();
	public var soundVolumeVariance:Map<String, Array<Float>> = new Map();

	// End changes
	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;
		var library:String = null;
		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':

			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path))
				{
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER +
						'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				var spriteType = "sparrow";
				// sparrow
				// packer
				// texture
				#if MODS_ALLOWED
				var modTxtToFind:String = Paths.modsTxt(json.image);
				var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);

				// var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				// var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();

				if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
				#end
				{
					spriteType = "packer";
				}

				#if MODS_ALLOWED
				var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
				var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);

				// var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				// var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();

				if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
				#end
				{
					spriteType = "texture";
				}

				switch (spriteType)
				{
					case "packer":
						frames = Paths.getPackerAtlas(json.image);

					case "sparrow":
						frames = Paths.getSparrowAtlas(json.image);

					case "texture":
						frames = AtlasFrameMaker.construct(json.image);
				}
				imageFile = json.image;

				if (json.scale != 1)
				{
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				// Combat changes
				// Changing the death sound does not natively have a way to change it per character
				// Changing death animations is possible by just defining the relevant animations in the json
				if (json.death_soundName != null && isPlayer)
					GameOverSubstate.deathSoundName = json.death_soundName;
				if (json.death_characterName != null && isPlayer)
					GameOverSubstate.characterName = json.death_characterName;

				// Preferred to have some kind of null-check so the declared variables could be defaulted to
				// I don't know how to navigate things well enough to figure out how to pull that off cleanly though
				idleDefaultFrame = json.idle_defaultFrame;
				hasReflexGuard = json.has_reflexGuard;
				hasUnblockableNoteAttacks = json.has_unblockableNoteAttacks;
				staminaCost = json.stamina_cost;
				guardPosition = json.default_guard_position;
				postureMax = json.posture_max;
				postureRecoveryCoefficient = json.posture_recoveryCoefficient;
				combatHealthMax = json.combat_healthMax;
				special = json.special_attack;
				if (isPlayer)
					baseDamage = json.ifPlayer_damage;
				else
					baseDamage = json.ifEnemy_damage;
				postureDamage = json.posture_damage;
				alternatingIdle = json.alternatingIdle;

				if (json.combatSoundEffects != null && json.soundsToPickFromRandom != null && json.soundsToVaryVolume != null)
				{
					for (i in 0...json.combatSoundEffects.length)
					{
						var curArray:Array<String> = json.combatSoundEffects[i];
						soundEffects.set(curArray[0], curArray[1]);
					}
					for (i in 0...json.soundsToPickFromRandom.length)
					{
						var curArray:Array<Dynamic> = json.soundsToPickFromRandom[i];
						soundRandomPicks.set(curArray[0], curArray[1]);
					}
					for (i in 0...json.soundsToVaryVolume.length)
					{
						var curArray:Array<Dynamic> = json.soundsToVaryVolume[i];
						soundVolumeVariance.set(curArray[0], curArray[1]);
					}
				}

				// End of changes

				positionArray = json.position;
				cameraPosition = json.camera_position;
				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if (json.no_antialiasing)
				{
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if (!ClientPrefs.globalAntialiasing)
					antialiasing = false;

				animationsArray = json.animations;
				if (animationsArray != null && animationsArray.length > 0)
				{
					for (anim in animationsArray)
					{
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; // Bruh
						var animIndices:Array<Int> = anim.indices;
						if (animIndices != null && animIndices.length > 0)
						{
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						}
						else
						{
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if (anim.offsets != null && anim.offsets.length > 1)
						{
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
					}
				}
				else
				{
					quickAnimAdd('idle', 'BF idle dance');
				}
				// trace('Loaded file to character ' + curCharacter);

				// Combat change
				characterExtraArray = json.characterExtras;
				if (characterExtraArray != null && characterExtraArray.length > 0)
				{
					for (i in characterExtraArray)
					{
						new CharacterExtra(x, y, this, i);
					}
				}
				// End of changes
		}

		combatHealth = combatHealthMax;

		// dance() uses the combatIdle() function, which needs an animation to be played to prevent crashes
		playAnim('idle');
		// End of changes

		originalFlipX = flipX;

		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;

			/*// Doesn't flip for BF, since his are already in the right place???
				if (!curCharacter.startsWith('bf'))
				{
					// var animArray
					if(animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
					{
						var oldRight = animation.getByName('singRIGHT').frames;
						animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
						animation.getByName('singLEFT').frames = oldRight;
					}

					// IF THEY HAVE MISS ANIMATIONS??
					if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
					{
						var oldMiss = animation.getByName('singRIGHTmiss').frames;
						animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
						animation.getByName('singLEFTmiss').frames = oldMiss;
					}
			}*/
		}

		switch (curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}
	}

	override function update(elapsed:Float)
	{
		// Combat change
		// Centralizes animations that need to reset to idle to keep update() here less cluttered
		resetToIdleDefaultFrame();

		if (!debugMode && animation.curAnim != null)
		{
			if (heyTimer > 0)
			{
				heyTimer -= elapsed * PlayState.instance.playbackRate;
				if (heyTimer <= 0)
				{
					if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			switch (curCharacter)
			{
				case 'pico-speaker':
					if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
					{
						var noteData:Int = 1;
						if (animationNotes[0][1] > 2)
							noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if (animation.curAnim.finished)
						playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			}

			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}
		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		// Combat change
		// Idle logic's more complex, so a function was made to handle it
		// Since Characters store a lot more individual stats than before, certain idle-cases are better to be defined up above with other character stats
		// Than to write out different idle systems in here
		//
		// What that means is sorting out stuff like "should the character use an up-down breathing animation"
		// is the alternatingIdle bool that's flipped at the first curCharacter switch
		// Thus just resolve any different idles under this function instead
		combatIdle();

		// Combat change
		// This is largely deprecated by combatIdle, but is kept so girlfriend's idle doesn't break
		// SO FOR THIS REASON:
		// Don't use danceIdle for combat characters! Consider the "alternatingIdle" bool instead, as it flags a similar system
		if (danceIdle)
		{
			if (!debugMode && !skipDance && !specialAnim)
			{
				if (danceIdle)
				{
					danced = !danced;

					if (danced)
						playAnim('danceRight' + idleSuffix);
					else
						playAnim('danceLeft' + idleSuffix);
				}
				else if (animation.getByName('idle' + idleSuffix) != null)
				{
					playAnim('idle' + idleSuffix);
				}
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;

		// Combat change
		// Throw the whole playAnim function under the evaluateAnim check
		// This evaluateAnim function centralizes most of the checks for whether an animation should be interrupted
		if (debugMode || evaluateAnim(AnimName))
		{
			animation.play(AnimName, Force, Reversed, Frame);

			var daOffset = animOffsets.get(AnimName);
			if (animOffsets.exists(AnimName))
			{
				offset.set(daOffset[0], daOffset[1]);
			}
			else
				offset.set(0, 0);

			// Combat change
			// Takes care of starting the check for whether extra sprites need to animate
			if (characterSprites.length > 0)
				animateExtraSprites(AnimName);

			if (curCharacter.startsWith('gf'))
			{
				if (AnimName == 'singLEFT')
				{
					danced = true;
				}
				else if (AnimName == 'singRIGHT')
				{
					danced = false;
				}

				if (AnimName == 'singUP' || AnimName == 'singDOWN')
				{
					danced = !danced;
				}
			}
		}
	}

	function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				animationNotes.push(songNotes);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	// Combat change*
	// Note that EVERY function from here on is a combat change
	//
	// Centralizes checks for whether an animation should be allowed to play, or if the animation currently active shouldn't be interrupted.
	function evaluateAnim(animToPlay:String):Bool
	{
		var performAnim:Bool = true;

		// It seems animation.curAnim is the culprit for crashes if a playAnim() is not done for a character on construction
		if (animation.curAnim != null)
		{
			switch (curCharacter)
			{
				case 'shrub':
					if (animToPlay.startsWith('idle') && Conductor.songPosition >= 0 && animation.curAnim.name == 'salute')
						performAnim = false;
				case 'shrubSerious':
					if (animToPlay.startsWith('idle') && animation.curAnim.name == 'transition')
						performAnim = false;
			}

			if (isBashed && !animToPlay.startsWith('combatHit'))
			{
				performAnim = false;
			}

			if (animToPlay.startsWith('idle'))
			{
				if (animation.curAnim.name.startsWith("sing") || animation.curAnim.name.startsWith("combat"))
				{
					if (!animation.finished)
						performAnim = false;
				}
			}

			// Hitting a direction can end up overriding singing anims without this check
			if (animToPlay.startsWith('combatReady') || animToPlay.startsWith('combatSwap'))
			{
				// Prevents the guard-swapping animations in cases where an animation should be allowed to finish,
				// Or animations that are allowed to be interrupted (usually default states like idles, or interrupting itself)
				if (!animation.curAnim.finished
					&& (!animation.curAnim.name.startsWith('idle')
						&& !animation.curAnim.name.endsWith('Dodge')
						&& !animation.curAnim.name.startsWith('combatReady')
						&& !animation.curAnim.name.startsWith('sing')))
					performAnim = false;

				// Only disables the ready animations while singing notes are active in the relevant direction
				// Without this, ready animations would not play while any singing note was active, regardless if it's one that can be hit yet
				// This is a quality concern,
				// Most definitely *not* to allow for screwing around during charts
				// c;
				//
				// That all being said, checking notes in a forEachAlive function didn't work out
				// The note that was hit is probably cleared by reaching this point?
				// This method checks the singing animation instead, as that gets setup properly prior to the ready animation getting determined here
				// Basically trying to check the hit note directly doesn't work
				if (animation.curAnim.name.startsWith('sing'))
				{
					if ((animation.curAnim.name.endsWith('LEFT') && animToPlay.endsWith('LEFT'))
						|| (animation.curAnim.name.endsWith('DOWN') && animToPlay.endsWith('DOWN'))
						|| (animation.curAnim.name.endsWith('UP') && animToPlay.endsWith('UP'))
						|| (animation.curAnim.name.endsWith('RIGHT') && animToPlay.endsWith('RIGHT')))
						performAnim = false;
				}
			}

			if (animToPlay.startsWith('sing'))
			{
				// Forces attack animation to play if it's not least two frames in
				// This is a visual-quality thing that mitigates attack anim skips if the sing animation would otherwise interrupt
				// Still happens sometimes so, dubiously helpful
				if (animation.curAnim.name.endsWith('combatAttack') && animation.curAnim.curFrame <= 2 && isPlayer)
					performAnim = false;
			}

			if (animation.curAnim.name.startsWith('sing'))
			{
				// Priority on the parry animation since it's a more deliberate action
				if (Combat.checkCombatInfoAvailable() && isPlayer)
					if (PlayState.instance.COMBAT.hasParried
						&& animToPlay.startsWith('combatBlock')
						|| animToPlay.startsWith('combatParry'))
						performAnim = false;
			}
		}

		return performAnim;
	}

	// Combat change
	// Greatly condenses the idle logic
	function combatIdle():Void
	{
		if (!hasReflexGuard)
		{
			// Be careful reading this, as the redundant alternatingIdle checks and that return are necessary
			// Basically it'll default to a standard idle unless it needs to animate the second part (like from an inhale to exhale animation)
			// The return is just to keep it from interrupting the animation
			if (alternatingIdle
				&& animation.curAnim.name.startsWith('idle')
				&& !animation.curAnim.name.startsWith('idleDown')
				&& animation.finished)
			{
				switch (guardPosition)
				{
					case 0:
						playAnim('idleDownLEFT', true);
					case 1:
					case 2:
						playAnim('idleDownUP', true);
					case 3:
						playAnim('idleDownRIGHT', true);
				}
			}
			else if (alternatingIdle && animation.curAnim.name.startsWith('idleDown') && !animation.finished)
				return;
			else
			{
				switch (guardPosition)
				{
					case 0:
						playAnim('idleLEFT');
					case 1:
					// Nah
					case 2:
						playAnim('idleUP');
					case 3:
						playAnim('idleRIGHT');
				}
			}
		}
		else
			playAnim('idle');
	}

	// Handles animating extra sprites, such as bf's alternate faces when blocking and parrying
	function animateExtraSprites(curAnim:String):Void
	{
		characterSprites.forEach(function(spr:CharacterExtra)
		{
			spr.animate(x, y, curAnim, zDepth, guardPosition);
		});
	}

	// SOUND EFFECT FILE TYPE NOTE:
	// All of the base game's sound files are both MP3 and OGG files
	// However, these sound effects are WAV files, and there is a reason for it
	//
	// Though WAV files are significantly bigger file sizes, they load significantly faster since they aren't compressed
	// Therefore, sound effects benefit best from using WAV files, while things like the song file should stay the MP3/OGG
	//
	// I've read other reasons for using WAV that implies advantages to MP3 that I'm unsure of, so take this advice with a grain of salt
	public function playSoundEffect(sound:String):Void
	{
		var curSound:String = soundEffects.get(sound);

		var soundNumber:String = '';
		var soundVolume:Float = 1;

		if (soundRandomPicks.exists(curSound))
		{
			var numberArray:Array<Int> = soundRandomPicks.get(curSound);
			soundNumber = '' + FlxG.random.int(numberArray[0], numberArray[1]);
		}

		if (soundVolumeVariance.exists(curSound))
		{
			var numberArray:Array<Float> = soundVolumeVariance.get(curSound);
			soundVolume = FlxG.random.float(numberArray[0], numberArray[1]);
		}

		if (Paths.sound(curSound + soundNumber).length <= 0)
			FlxG.sound.play(Paths.sound(curSound + soundNumber, null, true), soundVolume);
		else
			FlxG.sound.play(Paths.sound(curSound + soundNumber), soundVolume);
	}

	// Used in update() to determine if a reset to idle is needed
	function resetToIdleDefaultFrame():Void
	{
		if (animation.curAnim != null)
		{
			if (animation.curAnim.name.startsWith("combatDodge"))
			{
				if (Combat.checkCombatInfoAvailable())
					if (PlayState.instance.COMBAT.isDodge)
						return;

				if (hasReflexGuard)
				{
					playAnim('idle', true, false, idleDefaultFrame);
				}
				else
				{
					switch (guardPosition)
					{
						case 0:
							playAnim('idleLEFT', true, false, idleDefaultFrame);
						case 2:
							playAnim('idleUP', true, false, idleDefaultFrame);
						case 3:
							playAnim('idleRIGHT', true, false, idleDefaultFrame);
					}
				}
			}

			if (hasReflexGuard)
			{
				if (animation.curAnim.name.startsWith("combatReady") && animation.finished)
					playAnim('idle', true, false, idleDefaultFrame);
			}
		}
	}
}
