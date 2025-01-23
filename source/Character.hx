package;

import Section.SwagSection;
import animateatlas.AtlasFrameMaker;
import flash.media.Sound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
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
	var death_soundName:Null<String>;
	var death_characterName:Null<String>;
	var idle_defaultFrame:Null<Int>;
	var has_reflexGuard:Null<Bool>;
	var has_unblockableNoteAttacks:Null<Bool>;
	var death_by_stamina:Null<Bool>;
	var default_guard_position:Null<Int>;
	var posture_max:Null<Float>;
	var posture_recoveryCoefficient:Null<Float>;
	var combat_healthMax:Null<Float>;
	var special_attack:Null<String>;
	var ifPlayer_damage:Float;
	var ifEnemy_damage:Float;
	var posture_damage:Float;
	var alternatingIdle:Null<Bool>;
	var characterExtras:Null<Array<String>>;
	var combatSoundEffects:Array<Array<String>>;
	var soundsToPickFromRandom:Array<Array<Dynamic>>;
	var soundsToVaryVolume:Array<Array<Dynamic>>;

	var attacks:Array<AttackData>;
	var chains:Array<ChainData>;
	var attack_effects:Null<Array<AttackEffectData>>;
	var startup_effects:Null<Array<StartupEffectData>>;
	var sounds:Null<Array<SoundData>>;
	var character_sounds:CharacterSounds;
	// End of changes
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

// Combat change
typedef AttackData =
{
	var name:Null<String>;
	var attack_animation_name:Null<String>;
	var startup_animation_name:Null<String>;
	var sound_on_hit:Null<String>;
	var sound_on_miss:Null<String>;

	var not_an_attack:Null<Bool>;
	var direction:Null<String>;

	var damage:Null<Float>;
	var posture_damage:Null<Float>;
	var stamina_damage:Null<Float>;
	var stamina_cost:Null<Float>;

	var health_recover:Null<Float>;
	var posture_recover:Null<Float>;

	var step_based_timing:Null<Bool>;
	var duration:Null<Float>;
	var recovery:Null<Float>;
	var chain_duration:Null<Float>;
	var hitstun:Null<Float>;

	var is_unblockable:Null<Bool>;
	var is_bash:Null<Bool>;

	var append_direction_to_anim_name:Null<Bool>;

	var on_hit:Null<String>;
	var on_block:Null<String>;
	var on_parry:Null<String>;
	var on_complete:Null<String>;
}

typedef ChainData =
{
	var name:String;

	var directions:Null<Array<String>>;
	var choice_weight:Null<Int>;
	var include_sing_attacks:Null<Bool>;
	var input_chain:Array<String>;

	var attack_chain:Array<String>;
}

typedef AttackEffectData =
{
	var name:String;
	var damage:Null<Float>;
	var posture_damage:Null<Float>;
	var stamina_damage:Null<Float>;
	var stamina_cost:Null<Float>;
	var health_recover:Null<Float>;
	var posture_recover:Null<Float>;
	var step_based_timing:Null<Bool>;
	var recovery:Null<Float>;
	var hitstun:Null<Float>;
	var sound:Null<String>;
}

typedef StartupEffectData =
{
	var name:String;
	var uninterruptible_stance:Null<Bool>;
	var can_block:Null<Bool>;
	var can_parry:Null<Bool>;
	var feint_direction:Null<String>;
}

typedef SoundData =
{
	var name:String;
	var file_name:String;
	var volume_min:Null<Float>;
	var volume_max:Null<Float>;
	var file_number_min:Null<Int>;
	var file_number_max:Null<Int>;
}

typedef CharacterSounds =
{
	var struck:String;
	var block:String;
	var parry:String;
	var out_of_stamina:String;
}

// End of changes

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
	public var deathByStamina:Bool = false;
	public var guardPosition:Int = 0;
	public var hasReflexGuard = true;
	public var postureMax:Float = 100;
	public var posture(default, set):Float = 0;
	public var postureRecoveryCoefficient:Float = 1;
	public var combatHealthMax:Float = 100;
	public var combatHealth(default, set):Float = 100;
	public var characterSprites:FlxTypedGroup<CharacterExtra> = new FlxTypedGroup<CharacterExtra>();
	public var characterExtraArray:Array<String> = [];

	public var attackMap:Map<String, AttackData> = new Map();
	public var chainMap:Map<String, ChainData> = new Map();
	public var attackEffectMap:Map<String, AttackEffectData> = new Map();
	public var startupEffectMap:Map<String, StartupEffectData> = new Map();
	public var soundMap:Map<String, SoundData> = new Map();
	public var characterSounds:CharacterSounds = null;

	public var currentChain:ChainData = {
		name: 'neutral',
		directions: [],
		include_sing_attacks: false,
		choice_weight: 1,
		input_chain: [],
		attack_chain: []
	}
	public var placeInChain:Int = 0;
	public var currentAttack:AttackData;

	public var actionTimer:FlxTimer = new FlxTimer();
	public var actionStepTimer:Int = 0;
	public var currentAction(default, set):String = 'neutral';
	public var blockCount:Int = 0;

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
				// Combat change
				// The amount of stored character info and jsons is a little more complex, so this task is getting relegated to a function
				/*
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
				 */
				var path:String = Paths.getValidCharacterPath(curCharacter);

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
				//
				// FUTURE NOTE:
				// I got a better understanding of this, potential will returbn
				if (json.death_soundName != null && isPlayer)
					GameOverSubstate.deathSoundName = json.death_soundName;
				if (json.death_characterName != null && isPlayer)
					GameOverSubstate.characterName = json.death_characterName;

				// Not sure if there's a cleaner way to iterate through these
				// Maybe check back once I make a combat json typedef later. Iteration could be possible there?
				if (json.idle_defaultFrame != null)
					idleDefaultFrame = json.idle_defaultFrame;
				if (json.has_reflexGuard != null)
					hasReflexGuard = json.has_reflexGuard;
				if (json.death_by_stamina != null)
					deathByStamina = json.death_by_stamina;
				if (json.default_guard_position != null)
					guardPosition = json.default_guard_position;
				if (json.posture_max != null)
					postureMax = json.posture_max;
				if (json.posture_recoveryCoefficient != null)
					postureRecoveryCoefficient = json.posture_recoveryCoefficient;
				if (json.combat_healthMax != null)
					combatHealthMax = json.combat_healthMax;
				if (json.alternatingIdle != null)
					alternatingIdle = json.alternatingIdle;

				generateCombatArrays(json);
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
				if (json.characterExtras != null)
				{
					characterExtraArray = json.characterExtras;
					if (characterExtraArray != null && characterExtraArray.length > 0)
					{
						for (i in characterExtraArray)
						{
							new CharacterExtra(x, y, this, i);
						}
					}
				}

				// This is where the idleDefaultFrame gets funky
				if (json.idle_defaultFrame == null)
				{
					var defaultIdle:FlxAnimation = null;

					defaultIdle = animation.getByName(Combat.appendDirection('idle', guardPosition));
					if (defaultIdle == null)
						defaultIdle = animation.getByName('idle');

					if (defaultIdle != null)
						idleDefaultFrame = defaultIdle.frames.length;
				}
				// End of changes
		}

		combatHealth = combatHealthMax;

		// dance() uses the combatIdle() function, which needs an animation to be played to prevent crashes
		playAnim('idle');

		currentAttack = generateAttack(null);
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

			if (currentAction == 'bashed' && !animToPlay.startsWith('combatHit'))
			{
				performAnim = false;
			}

			if (animToPlay.startsWith('idle'))
			{
				if (currentAction != 'neutral')
					performAnim = false;

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
					if (currentAction == 'hasParried' && animToPlay.startsWith('combatBlock') || animToPlay.startsWith('combatParry'))
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
	// Though WAV files are significantly bigger file sizes, they load  faster since they aren't compressed
	// Therefore, sound effects benefit best from using WAV files, while things like the song file should stay the MP3/OGG
	//
	// I've read other reasons for using WAV that implies advantages to MP3 that I'm unsure of, so take this advice with a grain of salt
	public function playSoundEffect(sound:String):Void
	{
		var curSound:Null<SoundData> = soundMap.get(sound);
		if (curSound == null)
			return;

		var soundVolume:Null<Float> = curSound.volume_min;
		if (soundVolume == null)
			soundVolume = curSound.volume_max;
		if (soundVolume == null)
			soundVolume = 1;

		if (curSound.volume_min != null && curSound.volume_max != null)
			soundVolume = FlxG.random.float(curSound.volume_min, curSound.volume_max);

		var soundNumber:String = '';
		if (curSound.file_number_min != null && curSound.file_number_max != null)
		{
			if (curSound.file_number_min > curSound.file_number_max)
			{
				var dummyInt:Int = curSound.file_number_min;
				curSound.file_number_min = curSound.file_number_max;
				curSound.file_number_max = dummyInt;
			}

			soundNumber = '' + FlxG.random.int(curSound.file_number_min, curSound.file_number_max);
		}

		if (Paths.sound(curSound.file_name + soundNumber).length <= 0)
			FlxG.sound.play(Paths.sound(curSound.file_name + soundNumber, null, true), soundVolume);
		else
			FlxG.sound.play(Paths.sound(curSound.file_name + soundNumber), soundVolume);
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

	public function generateAttack(attackData:Null<AttackData>):AttackData
	{
		if (attackData == null)
			attackData = {
				name: null,
				attack_animation_name: null,
				startup_animation_name: null,
				sound_on_hit: null,
				sound_on_miss: null,
				not_an_attack: null,
				direction: null,
				damage: null,
				posture_damage: null,
				stamina_damage: null,
				stamina_cost: null,
				health_recover: null,
				posture_recover: null,
				step_based_timing: null,
				duration: null,
				recovery: null,
				chain_duration: null,
				hitstun: null,
				is_unblockable: null,
				is_bash: null,
				append_direction_to_anim_name: null,
				on_hit: null,
				on_block: null,
				on_parry: null,
				on_complete: null
			}

		var newAttack:AttackData = {
			name: attackData.name,
			attack_animation_name: attackData.attack_animation_name,
			startup_animation_name: attackData.startup_animation_name,
			sound_on_hit: null,
			sound_on_miss: null,
			not_an_attack: attackData.not_an_attack,
			direction: attackData.direction,
			damage: attackData.damage,
			posture_damage: attackData.posture_damage,
			stamina_damage: attackData.stamina_damage,
			stamina_cost: attackData.stamina_cost,
			health_recover: attackData.health_recover,
			posture_recover: attackData.posture_recover,
			step_based_timing: attackData.step_based_timing,
			duration: attackData.duration,
			recovery: attackData.recovery,
			chain_duration: attackData.chain_duration,
			hitstun: attackData.hitstun,
			is_unblockable: attackData.is_unblockable,
			is_bash: attackData.is_bash,
			append_direction_to_anim_name: attackData.append_direction_to_anim_name,
			on_hit: attackData.on_hit,
			on_block: attackData.on_block,
			on_parry: attackData.on_parry,
			on_complete: attackData.on_complete
		};

		// These != null checks are to allow for attacks to be truncated a bit

		if (newAttack.name == null)
			newAttack.name = 'player_sing_attack';
		if (newAttack.direction == null)
			newAttack.direction = 'ANY';

		if (newAttack.attack_animation_name == null)
			newAttack.attack_animation_name = 'combatAttack';
		if (newAttack.startup_animation_name == null)
			newAttack.startup_animation_name = 'combatWind';

		if (newAttack.sound_on_hit == null)
			newAttack.sound_on_hit = '';
		if (newAttack.sound_on_miss == null)
			newAttack.sound_on_miss = 'miss';

		if (newAttack.not_an_attack == null)
			newAttack.not_an_attack = false;

		if (newAttack.direction == null)
			newAttack.direction = 'ANY';

		if (newAttack.append_direction_to_anim_name == null)
			newAttack.append_direction_to_anim_name = false;

		// To allow sing attacks to prune this variable
		if (newAttack.is_unblockable == null)
			newAttack.is_unblockable = false;

		// Above stat plus not_an_attack makes these unused
		if (newAttack.damage == null)
			newAttack.damage = 15;
		if (newAttack.stamina_damage == null)
			newAttack.stamina_damage = 0;
		if (newAttack.is_bash == null)
			newAttack.is_bash = false;

		// Enemy attacks don't need this, and players without posture mechanics
		if (newAttack.posture_damage == null)
			newAttack.posture_damage = 3;

		// For enemy attacks, since enemies don't use stamina
		if (newAttack.stamina_cost == null)
			newAttack.stamina_cost = 0.2;

		// Healing attacks are likely not the broad norm
		if (newAttack.health_recover == null)
			newAttack.health_recover = 0;
		if (newAttack.stamina_cost == null)
			newAttack.posture_recover = 0;

		if (newAttack.step_based_timing == null)
			newAttack.step_based_timing = false;

		if (newAttack.duration == null)
			newAttack.duration = 0;
		if (newAttack.recovery == null)
			newAttack.recovery = 0;

		if (newAttack.chain_duration == null)
		{
			if (newAttack.step_based_timing)
				newAttack.chain_duration = newAttack.recovery + 1;
			else
				newAttack.chain_duration = newAttack.recovery + 0.5;
		}

		if (newAttack.hitstun == null)
		{
			if (newAttack.step_based_timing)
				newAttack.hitstun = 2;
			else
				newAttack.hitstun = 0.5;
		}

		return newAttack;
	}

	function generateCombatArrays(characterFile:CharacterFile)
	{
		var attackDataArray:Array<AttackData> = characterFile.attacks;
		var chainDataArray:Array<ChainData> = characterFile.chains;
		var attackEffectDataArray:Array<AttackEffectData> = characterFile.attack_effects;
		var startupEffectDataArray:Array<StartupEffectData> = characterFile.startup_effects;
		var soundsArrayData:Array<SoundData> = characterFile.sounds;
		var characterSoundData:CharacterSounds = characterFile.character_sounds;

		if (attackDataArray == null)
			attackDataArray = [];
		for (i in 0...attackDataArray.length)
		{
			var attackData:AttackData = attackDataArray[i];

			attackMap.set(attackData.name, generateAttack(attackData));
		}

		if (chainDataArray == null)
			chainDataArray = [];
		for (i in 0...chainDataArray.length)
		{
			var chainData:ChainData = chainDataArray[i];

			var newChain:ChainData = {
				name: chainData.name,
				directions: chainData.directions,
				include_sing_attacks: chainData.include_sing_attacks,
				choice_weight: chainData.choice_weight,
				input_chain: chainData.input_chain,
				attack_chain: chainData.attack_chain
			};

			if (newChain.name == null)
				newChain.name = "nullChain" + i;

			if (newChain.directions == null)
				newChain.directions = [];

			if (newChain.include_sing_attacks == null)
				newChain.include_sing_attacks = false;

			if (newChain.choice_weight == null)
				newChain.choice_weight = 1;

			if (newChain.input_chain == null)
				newChain.input_chain = [];

			if (newChain.attack_chain == null)
				newChain.attack_chain = ['basic_attack'];

			chainMap.set(newChain.name, newChain);
		}

		if (attackEffectDataArray == null)
			attackEffectDataArray = [];
		for (i in 0...attackEffectDataArray.length)
		{
			var attackEffectData:AttackEffectData = attackEffectDataArray[i];

			// Remember to update fillNullAttackEffectData() when implementing a new value!
			var newAttackEffect:AttackEffectData = {
				name: attackEffectData.name,
				damage: attackEffectData.damage,
				posture_damage: attackEffectData.posture_damage,
				stamina_damage: attackEffectData.stamina_damage,
				stamina_cost: attackEffectData.stamina_cost,
				health_recover: attackEffectData.health_recover,
				posture_recover: attackEffectData.posture_recover,
				step_based_timing: attackEffectData.step_based_timing,
				recovery: attackEffectData.recovery,
				hitstun: attackEffectData.hitstun,
				sound: attackEffectData.sound
			}

			attackEffectMap.set(newAttackEffect.name, newAttackEffect);
		}

		if (startupEffectDataArray == null)
			startupEffectDataArray = [];
		for (i in 0...startupEffectDataArray.length)
		{
			var startupEffectData:StartupEffectData = startupEffectDataArray[i];

			var newStartupEffect:StartupEffectData = {
				name: startupEffectData.name,
				uninterruptible_stance: startupEffectData.uninterruptible_stance,
				can_block: startupEffectData.can_block,
				can_parry: startupEffectData.can_parry,
				feint_direction: startupEffectData.feint_direction
			}

			startupEffectMap.set(newStartupEffect.name, newStartupEffect);
		}

		if (soundsArrayData == null)
			soundsArrayData = [];
		for (i in 0...soundsArrayData.length)
		{
			var soundData:SoundData = soundsArrayData[i];

			var newSound:SoundData = {
				name: soundData.name,
				file_name: soundData.file_name,
				volume_min: soundData.volume_min,
				volume_max: soundData.volume_max,
				file_number_min: soundData.file_number_min,
				file_number_max: soundData.file_number_max
			}

			soundMap.set(newSound.name, newSound);
		}

		if (characterSoundData == null)
			characterSoundData = {
				struck: null,
				block: null,
				parry: null,
				out_of_stamina: null
			}

		if (characterSoundData.struck == null)
			characterSoundData.struck = 'hit';
		if (characterSoundData.block == null)
			characterSoundData.block = 'block';
		if (characterSoundData.parry == null)
			characterSoundData.parry = 'block';
		if (characterSoundData.out_of_stamina == null)
			characterSoundData.out_of_stamina = 'oos';

		characterSounds = {
			struck: characterSoundData.struck,
			block: characterSoundData.block,
			parry: characterSoundData.parry,
			out_of_stamina: characterSoundData.out_of_stamina,
		}
	}

	// Filling nulls is its own function since data being null in the first place is interpreted as deliberately excluded
	public static function fillNullAttackEffectData(newAttackEffect:AttackEffectData):AttackEffectData
	{
		if (newAttackEffect.name == null)
			newAttackEffect.name = 'nullAttackEffect';
		if (newAttackEffect.damage == null)
			newAttackEffect.damage = 0;
		if (newAttackEffect.posture_damage == null)
			newAttackEffect.posture_damage = 0;
		if (newAttackEffect.stamina_damage == null)
			newAttackEffect.stamina_damage = 0;
		if (newAttackEffect.stamina_cost == null)
			newAttackEffect.stamina_cost = 0;
		if (newAttackEffect.health_recover == null)
			newAttackEffect.health_recover = 0;
		if (newAttackEffect.posture_recover == null)
			newAttackEffect.posture_recover = 0;
		if (newAttackEffect.step_based_timing == null)
			newAttackEffect.step_based_timing = false;
		if (newAttackEffect.recovery == null)
			newAttackEffect.recovery = 0;
		if (newAttackEffect.hitstun == null)
			newAttackEffect.hitstun = 0;
		if (newAttackEffect.sound == null)
			newAttackEffect.sound = 'nullAttackSound';

		return newAttackEffect;
	}

	/**
	 * For debugging character actions
	 */
	function set_currentAction(Value:String):String
	{
		#if debug
		if (isPlayer)
			FlxG.watch.addQuick("BF Action", Value);
		else
			FlxG.watch.addQuick("Dad Action", Value);
		#end

		currentAction = Value;

		return Value;
	}

	function set_combatHealth(Value:Float):Float
	{
		var priorHealth = combatHealth;
		combatHealth = Value;

		if (Value < priorHealth && priorHealth > 0 && combatHealth <= 0 && PlayState.instance != null)
		{
			PlayState.instance.callOnLuas('onCharacterDefeat', [isPlayer ? 'boyfriend' : 'dad']);
		}

		return Value;
	}

	function set_posture(Value:Float):Float
	{
		var priorPosture = posture;
		posture = Value;

		if (Value > priorPosture && priorPosture < postureMax && posture >= postureMax && PlayState.instance != null)
		{
			PlayState.instance.callOnLuas('onCharacterPostureBreak', [isPlayer ? 'boyfriend' : 'dad']);
		}

		return Value;
	}
}
