package objects;

import backend.Song;
import backend.animation.PsychAnimationController;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import forfriday.CharacterExtra;
import forfriday.Combat;
import haxe.Json;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import states.stages.objects.TankmenBG;

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
	var vocals_file:String;
	@:optional var _editor_isPlayer:Null<Bool>;

	// Combat change
	var combat_data:CombatFile;
	// End of change
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
typedef CombatFile =
{
	var death_soundName:Null<String>;
	var death_characterName:Null<String>;
	var idle_defaultFrame:Null<Int>;
	var has_reflexGuard:Null<Bool>;
	var death_by_stamina:Null<Bool>;
	var default_guard_position:Null<Int>;
	var posture_max:Null<Float>;
	var posture_recoveryCoefficient:Null<Float>;
	var combat_healthMax:Null<Float>;
	var alternatingIdle:Null<Bool>;
	var characterExtras:Null<Array<String>>;
	var combatSoundEffects:Array<Array<String>>;
	var soundsToPickFromRandom:Array<Array<Dynamic>>;
	var soundsToVaryVolume:Array<Array<Dynamic>>;

	var attacks:Array<AttackData>;
	var chains:Array<ChainData>;
	var attack_effects:Null<Array<AttackEffectData>>;
	var defense_effects:Null<Array<DefendEffectData>>;
	var sounds:Null<Array<SoundData>>;
	var character_sounds:CharacterSounds;
}

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
	var is_feint:Null<Bool>;

	var append_direction_to_anim_name:Null<Bool>;

	var on_hit:Null<String>;
	var on_block:Null<String>;
	var on_parry:Null<String>;
	var on_miss:Null<String>;
	var on_complete:Null<String>;

	var on_startup_defense:Null<String>;
	var on_recovery_defense:Null<String>;
	var on_defense:Null<String>;
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

typedef DefendEffectData =
{
	var name:String;
	var uninterruptible:Null<Bool>;
	var can_block:Null<Bool>;
	var can_parry:Null<Bool>;
	var can_dodge:Null<Bool>;
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
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	// Combat change
	// public var isPlayer:Bool = false;
	public var isPlayer(default, set):Bool = false;
	// End of change
	public var curCharacter:String = DEFAULT_CHARACTER;

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
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;
	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	// Combat changes
	// Variables for characters
	public var zDepth:Int = 0;
	public var idleDefaultFrame:Int = 10;
	public var playerOneFlipSide:Bool = false;
	public var alternatingIdle:Bool = false;
	public var deathByStamina:Bool = false;
	public var guardPosition:Int = 0;
	public var defaultGuardPosition:Int = 0;
	public var hasReflexGuard = true;
	public var postureMax:Float = 100;
	public var posture(default, set):Float = 0;
	public var postureRecoveryCoefficient:Float = 1;
	public var combatHealthMax:Float = 100;
	public var combatHealth(default, set):Float = 100;
	public var characterSprites:FlxTypedGroup<CharacterExtra> = new FlxTypedGroup<CharacterExtra>();
	public var characterExtraArray:Array<String> = [];
	public var curSpriteGroup:FlxSpriteGroup = null;

	public var attackMap:Map<String, AttackData> = new Map();
	public var chainMap:Map<String, ChainData> = new Map();
	public var attackEffectMap:Map<String, AttackEffectData> = new Map();
	public var defendEffectMap:Map<String, DefendEffectData> = new Map();
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

	// End of changes

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();
		this.isPlayer = isPlayer;
		changeCharacter(character);

		switch (curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
			case 'pico-blazin', 'darnell-blazin':
				skipDance = true;
		}
	}

	public function changeCharacter(character:String)
	{
		animationsArray = [];
		animOffsets = [];
		curCharacter = character;
		// Combat change
		// For character file support
		// var characterPath:String = 'characters/$character.json';
		var characterPath:String = 'characters/$character/$character.json';
		if (!Paths.characterFileExists(character, false, character, '.json'))
			characterPath = 'characters/$character.json';
		// End of changes

		var path:String = Paths.getPath(characterPath, TEXT);
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
		#else
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER +
				'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
			missingCharacter = true;
			missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
			missingText.alignment = CENTER;
		}

		try
		{
			#if MODS_ALLOWED
			loadCharacterFile(Json.parse(File.getContent(path)));
			#else
			loadCharacterFile(Json.parse(Assets.getText(path)));
			#end
		}
		catch (e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}

		skipDance = false;
		hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
		recalculateDanceIdle();
		dance();
	}

	public function loadCharacterFile(json:Dynamic)
	{
		isAnimateAtlas = false;

		#if flxanimate
		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
			isAnimateAtlas = true;
		#end

		scale.set(1, 1);
		updateHitbox();

		if (!isAnimateAtlas)
		{
			frames = Paths.getMultiAtlas(json.image.split(','));
		}
		#if flxanimate
		else
		{
			atlas = new FlxAnimate();
			atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(atlas, json.image);
			}
			catch (e:haxe.Exception)
			{
				FlxG.log.warn('Could not load atlas ${json.image}: $e');
				trace(e.stack);
			}
		}
		#end

		imageFile = json.image;
		jsonScale = json.scale;
		if (json.scale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		positionArray = json.position;
		cameraPosition = json.camera_position;

		// data
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = (json.flip_x != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = json.vocals_file != null ? json.vocals_file : '';
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer;

		// Combat changes

		switchCombatJson(json.combat_data);

		if (currentAttack == null)
			currentAttack = Reflect.copy(generateAttack(null));
		// End of changes

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		// animations
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

				if (!isAnimateAtlas)
				{
					if (animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				#if flxanimate
				else
				{
					if (animIndices != null && animIndices.length > 0)
						atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else
						atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
				}
				#end

				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else
					addOffset(anim.anim, 0, 0);
			}
		}
		#if flxanimate
		if (isAnimateAtlas)
			copyAtlasValues();
		#end

		// Combat change
		if (json.characterExtras != null)
		{
			characterExtraArray = json.characterExtras;
			generateCharacterExtras();
		}
		// End of change

		// trace('Loaded file to character ' + curCharacter);
	}

	override function update(elapsed:Float)
	{
		// Combat change
		// Centralizes animations that need to reset to idle to keep update() here less cluttered
		resetToIdleDefaultFrame();

		if (isAnimateAtlas)
			atlas.update(elapsed);

		if (debugMode
			|| (!isAnimateAtlas && animation.curAnim == null)
			|| (isAnimateAtlas && (atlas.anim.curInstance == null || atlas.anim.curSymbol == null)))
		{
			super.update(elapsed);
			return;
		}

		if (heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if (heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if (specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if (specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
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
				if (isAnimationFinished())
					playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}

		if (getAnimationName().startsWith('sing'))
			holdTimer += elapsed;
		else if (isPlayer)
			holdTimer = 0;

		if (!isPlayer
			&& holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if (isAnimationFinished() && hasAnimation('$name-loop'))
			playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
	{
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curInstance == null || atlas.anim.curSymbol == null);
	}

	var _lastPlayedAnimation:String;

	inline public function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}

	public function isAnimationFinished():Bool
	{
		if (isAnimationNull())
			return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function finishAnimation():Void
	{
		if (isAnimationNull())
			return;

		if (!isAnimateAtlas)
			animation.curAnim.finish();
		else
			atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public function hasAnimation(anim:String):Bool
	{
		return animOffsets.exists(anim);
	}

	public var animPaused(get, set):Bool;

	private function get_animPaused():Bool
	{
		if (isAnimationNull())
			return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}

	private function set_animPaused(value:Bool):Bool
	{
		if (isAnimationNull())
			return value;
		if (!isAnimateAtlas)
			animation.curAnim.paused = value;
		else
		{
			if (value)
				atlas.pauseAnimation();
			else
				atlas.resumeAnimation();
		}

		return value;
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
			else if (hasAnimation('idle' + idleSuffix))
				playAnim('idle' + idleSuffix);
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		// Combat Change
		if (!animCanBeInterrupted(AnimName))
			return;
		// End of change

		specialAnim = false;
		if (!isAnimateAtlas)
		{
			animation.play(AnimName, Force, Reversed, Frame);
		}
		else
		{
			atlas.anim.play(AnimName, Force, Reversed, Frame);
			atlas.update(0);
		}
		_lastPlayedAnimation = AnimName;

		if (hasAnimation(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
		// else offset.set(0, 0);

		// Combat change
		// Takes care of starting the check for whether extra sprites need to animate
		if (characterSprites.length > 0)
			animateExtraSprites(AnimName);
		// Combat change

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function loadMappedAnims():Void
	{
		try
		{
			var songData:SwagSong = Song.getChart('picospeaker', Paths.formatToSongPath(Song.loadedSongName));
			if (songData != null)
				for (section in songData.notes)
					for (songNotes in section.sectionNotes)
						animationNotes.push(songNotes);

			TankmenBG.animationNotes = animationNotes;
			animationNotes.sort(sortAnims);
		}
		catch (e:Dynamic)
		{
		}
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
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

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

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	@:allow(states.editors.CharacterEditorState)
	public var isAnimateAtlas(default, null):Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;

	public override function draw()
	{
		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;
		if (missingCharacter)
		{
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		if (isAnimateAtlas)
		{
			if (atlas.anim.curInstance != null)
			{
				copyAtlasValues();
				atlas.draw();
				alpha = lastAlpha;
				color = lastColor;
				if (missingCharacter && visible)
				{
					missingText.x = getMidpoint().x - 150;
					missingText.y = getMidpoint().y - 10;
					missingText.draw();
				}
			}
			return;
		}
		super.draw();
		if (missingCharacter && visible)
		{
			alpha = lastAlpha;
			color = lastColor;
			missingText.x = getMidpoint().x - 150;
			missingText.y = getMidpoint().y - 10;
			missingText.draw();
		}
	}

	public function copyAtlasValues()
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}

	public override function destroy()
	{
		atlas = FlxDestroyUtil.destroy(atlas);
		super.destroy();
	}
	#end

	// Combat change*
	// Note that EVERY function from here on is a combat change
	function animCanBeInterrupted(animToPlay:String):Bool
	{
		var performAnim:Bool = true;

		if (animation.curAnim != null)
		{
			/*
				var idleActionBlacklist:Array<String> = [
					'startup',
					'stepStartup',
					'recovery',
					'stepRecovery',
					'blockStun',
					'defending',
					'hitstun',
					'swappingGuard',
					'bashed'
				];

				switch (curCharacter)
				{
					case 'shrub':
						if (animToPlay.startsWith('idle') && Conductor.songPosition >= 0 && animation.curAnim.name == 'salute')
							performAnim = false;
					case 'shrubSerious':
						if (animToPlay.startsWith('idle') && animation.curAnim.name == 'transition')
							performAnim = false;
				}

				if (animToPlay.startsWith('idle') && idleActionBlacklist.contains(currentAction))
				{
					if (!animation.finished)
						performAnim = false;
				}
			 */

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

	public function generateCharacterExtras()
	{
		if (characterSprites.length > 0)
		{
			characterSprites.forEach(function(extra:CharacterExtra)
			{
				extra.destroy();
			});
			characterSprites.clear();
		}

		if (characterExtraArray.length > 0)
			for (name in characterExtraArray)
				new CharacterExtra(x, y, this, name);
	}

	// Handles animating extra sprites, such as bf's alternate faces when blocking and parrying
	function animateExtraSprites(curAnim:String):Void
	{
		characterSprites.forEach(function(spr:CharacterExtra)
		{
			spr.animate(x, y, curAnim, zDepth, guardPosition);
		});

		if (curSpriteGroup != null)
			curSpriteGroup.sort(PlayState.sortByZ);
	}

	// SOUND EFFECT FILE TYPE NOTE:
	// All of the base game's sound files are both MP3 and OGG files
	// However, these sound effects are WAV files, and there is a reason for it
	//
	// Though WAV files are significantly bigger file sizes, they load  faster since they aren't compressed
	// Therefore, sound effects benefit best from using WAV files, while things like the song file should stay the MP3/OGG
	//
	// I've read other reasons for using WAV that implies advantages to MP3 that I'm unsure of, so take this advice with a grain of salt
	public function playSoundEffect(sound:String, volumeMultiplier:Float = 1):Void
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

		soundVolume *= volumeMultiplier;
		if (soundVolume > 1)
			soundVolume = 1;
		if (soundVolume < 0)
			return;

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

		FlxG.sound.play(Paths.sound(curSound.file_name + soundNumber, true), soundVolume);
	}

	// Used in update() to determine if a reset to idle is needed
	function resetToIdleDefaultFrame():Void
	{
		if (animation.curAnim != null)
		{
			if (!animation.curAnim.finished)
				return;

			if (animation.curAnim.name.startsWith("combatDodge"))
			{
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
				if (animation.curAnim.name.startsWith("combatReady"))
					playAnim('idle', true, false, idleDefaultFrame);
			}
		}
	}

	public static function generateAttack(attackData:Null<AttackData> = null, ?existingAttack:Null<AttackData>):AttackData
	{
		var newAttack:AttackData = {
			name: attackData?.name,
			attack_animation_name: attackData?.attack_animation_name ?? existingAttack?.attack_animation_name ?? 'combatAttack',
			startup_animation_name: attackData?.startup_animation_name ?? existingAttack?.startup_animation_name ?? 'combatWind',
			sound_on_hit: attackData?.sound_on_hit ?? existingAttack?.sound_on_hit ?? '',
			sound_on_miss: attackData?.sound_on_miss ?? existingAttack?.sound_on_miss ?? 'miss',
			not_an_attack: attackData?.not_an_attack ?? existingAttack?.not_an_attack ?? false,
			direction: attackData?.direction ?? existingAttack?.direction ?? 'ANY',

			damage: attackData?.damage ?? existingAttack?.damage ?? 15,
			posture_damage: attackData?.posture_damage ?? existingAttack?.posture_damage ?? 3,
			stamina_damage: attackData?.stamina_damage ?? existingAttack?.stamina_damage ?? 0,
			stamina_cost: attackData?.stamina_cost ?? existingAttack?.stamina_cost ?? 0.2,
			health_recover: attackData?.health_recover ?? existingAttack?.health_recover ?? 0,
			posture_recover: attackData?.posture_recover ?? existingAttack?.posture_recover ?? 0,

			step_based_timing: attackData?.step_based_timing ?? existingAttack?.step_based_timing ?? false,
			duration: attackData?.duration ?? existingAttack?.duration ?? 1,
			recovery: attackData?.recovery ?? existingAttack?.recovery ?? 1,
			chain_duration: attackData?.chain_duration ?? existingAttack?.chain_duration,
			hitstun: attackData?.hitstun ?? existingAttack?.hitstun,

			is_unblockable: attackData?.is_unblockable ?? existingAttack?.is_unblockable ?? false,
			is_bash: attackData?.is_bash ?? existingAttack?.is_bash ?? false,
			is_feint: attackData?.is_feint ?? existingAttack?.is_feint ?? false,
			append_direction_to_anim_name: attackData?.append_direction_to_anim_name ?? existingAttack?.append_direction_to_anim_name ?? false,

			on_hit: attackData?.on_hit ?? existingAttack?.on_hit,
			on_block: attackData?.on_block ?? existingAttack?.on_block,
			on_parry: attackData?.on_parry ?? existingAttack?.on_parry,
			on_complete: attackData?.on_complete ?? existingAttack?.on_complete,

			on_miss: attackData?.on_miss ?? existingAttack?.on_miss,
			on_startup_defense: attackData?.on_startup_defense ?? existingAttack?.on_startup_defense,
			on_recovery_defense: attackData?.on_recovery_defense ?? existingAttack?.on_recovery_defense,
			on_defense: attackData?.on_defense ?? existingAttack?.on_defense,
		};

		if (newAttack.chain_duration == null)
		{
			if (newAttack.step_based_timing)
				newAttack.chain_duration = newAttack.recovery + 2;
			else
				newAttack.chain_duration = newAttack.recovery + 0.33;
		}

		if (newAttack.hitstun == null)
		{
			if (newAttack.step_based_timing)
				newAttack.hitstun = 2;
			else
				newAttack.hitstun = 0.33;
		}

		return newAttack;
	}

	public static function generateChain():ChainData
	{
		var newChain:ChainData = {
			name: "nullChain",
			directions: [],
			include_sing_attacks: false,
			choice_weight: 1,
			input_chain: [],
			attack_chain: []
		};

		return newChain;
	}

	function generateCombatArrays(characterFile:CombatFile)
	{
		var attackDataArray:Array<AttackData> = characterFile.attacks;
		var chainDataArray:Array<ChainData> = characterFile.chains;
		var attackEffectDataArray:Array<AttackEffectData> = characterFile.attack_effects;
		var defendEffectDataArray:Array<DefendEffectData> = characterFile.defense_effects;
		var soundsArrayData:Array<SoundData> = characterFile.sounds;
		var characterSoundData:CharacterSounds = characterFile.character_sounds;

		if (attackDataArray != null)
			for (i in 0...attackDataArray.length)
			{
				var attackData:AttackData = attackDataArray[i];
				var existingAttack = attackMap.get(attackData.name);

				attackMap.set(attackData.name, generateAttack(attackData, attackMap.get(attackData.name)));
			}

		if (chainDataArray != null)
			for (i in 0...chainDataArray.length)
			{
				var chainData:ChainData = chainDataArray[i];
				var existingChain = chainMap.get(chainData.name);

				var newChain:ChainData = {
					name: chainData?.name ?? existingChain?.name ?? "nullChain" + i,
					directions: chainData?.directions ?? existingChain?.directions ?? [],
					include_sing_attacks: chainData?.include_sing_attacks ?? existingChain?.include_sing_attacks ?? false,
					choice_weight: chainData?.choice_weight ?? existingChain?.choice_weight ?? 1,
					input_chain: chainData?.input_chain ?? existingChain?.input_chain ?? [],
					attack_chain: chainData?.attack_chain ?? existingChain?.attack_chain ?? ['basic_attack']
				};

				chainMap.set(newChain.name, newChain);
			}

		if (attackEffectDataArray != null)
			for (i in 0...attackEffectDataArray.length)
			{
				var attackEffectData:AttackEffectData = attackEffectDataArray[i];
				var existingAttackEffect = attackEffectMap.get(attackEffectData.name);

				var newAttackEffect:AttackEffectData = {
					name: attackEffectData?.name ?? existingAttackEffect?.name,
					damage: attackEffectData?.damage ?? existingAttackEffect?.damage,
					posture_damage: attackEffectData?.posture_damage ?? existingAttackEffect?.posture_damage,
					stamina_damage: attackEffectData?.stamina_damage ?? existingAttackEffect?.stamina_damage,
					stamina_cost: attackEffectData?.stamina_cost ?? existingAttackEffect?.stamina_cost,
					health_recover: attackEffectData?.health_recover ?? existingAttackEffect?.health_recover,
					posture_recover: attackEffectData?.posture_recover ?? existingAttackEffect?.posture_recover,
					step_based_timing: attackEffectData?.step_based_timing ?? existingAttackEffect?.step_based_timing,
					recovery: attackEffectData?.recovery ?? existingAttackEffect?.recovery,
					hitstun: attackEffectData?.hitstun ?? existingAttackEffect?.hitstun,
					sound: attackEffectData?.sound ?? existingAttackEffect?.sound
				}

				attackEffectMap.set(newAttackEffect.name, newAttackEffect);
			}

		if (defendEffectDataArray != null)
			for (i in 0...defendEffectDataArray.length)
			{
				var defendEffectData:DefendEffectData = defendEffectDataArray[i];
				var existingDefendEffect = defendEffectMap.get(defendEffectData.name);

				var newStartupEffect:DefendEffectData = {
					name: defendEffectData?.name ?? existingDefendEffect?.name,
					uninterruptible: defendEffectData?.uninterruptible ?? existingDefendEffect?.uninterruptible,
					can_block: defendEffectData?.can_block ?? existingDefendEffect?.can_block,
					can_parry: defendEffectData?.can_parry ?? existingDefendEffect?.can_parry,
					can_dodge: defendEffectData?.can_dodge ?? existingDefendEffect?.can_dodge
				}

				defendEffectMap.set(newStartupEffect.name, newStartupEffect);
			}

		if (soundsArrayData != null)
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

		characterSoundData.struck = characterSoundData.struck ?? 'hit';
		characterSoundData.block = characterSoundData.block ?? 'block';
		characterSoundData.parry = characterSoundData.parry ?? 'block';
		characterSoundData.out_of_stamina = characterSoundData.out_of_stamina ?? 'oos';

		characterSounds = {
			struck: characterSoundData.struck,
			block: characterSoundData.block,
			parry: characterSoundData.parry,
			out_of_stamina: characterSoundData.out_of_stamina,
		}
	}

	public function switchCombatJson(combatJson:CombatFile)
	{
		if (combatJson == null)
			combatJson = {
				death_soundName: null,
				death_characterName: null,
				idle_defaultFrame: null,
				has_reflexGuard: null,
				death_by_stamina: null,
				default_guard_position: null,
				posture_max: null,
				posture_recoveryCoefficient: null,
				combat_healthMax: null,
				alternatingIdle: null,
				characterExtras: null,
				combatSoundEffects: null,
				soundsToPickFromRandom: null,
				soundsToVaryVolume: null,

				attacks: null,
				chains: null,
				attack_effects: null,
				defense_effects: null,
				sounds: null,
				character_sounds: null
			};

		// The ?? means it'll use the value after if the json value was null
		idleDefaultFrame = combatJson.idle_defaultFrame ?? idleDefaultFrame ?? 10;
		hasReflexGuard = combatJson.has_reflexGuard ?? hasReflexGuard ?? true;
		deathByStamina = combatJson.death_by_stamina ?? deathByStamina ?? false;
		postureMax = combatJson.posture_max ?? postureMax ?? 100;
		postureRecoveryCoefficient = combatJson.posture_recoveryCoefficient ?? postureRecoveryCoefficient ?? 1;
		combatHealthMax = combatJson.combat_healthMax ?? combatHealthMax ?? 100;
		alternatingIdle = combatJson.alternatingIdle ?? alternatingIdle ?? false;

		guardPosition = combatJson.default_guard_position ?? guardPosition ?? 0;
		if (guardPosition == 1 || guardPosition < 0 || guardPosition > 3)
			guardPosition = 0;
		defaultGuardPosition = guardPosition;

		generateCombatArrays(combatJson);
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

	function set_isPlayer(Value:Bool):Bool
	{
		if (isPlayer != Value)
		{
			characterSprites.forEach(function(cha:CharacterExtra)
			{
				cha.isPlayer = Value;
				cha.flipX = !cha.flipX;
			});
		}

		isPlayer = Value;

		return Value;
	}

	// End of functions
}
