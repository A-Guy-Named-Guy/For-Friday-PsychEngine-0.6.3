package;

import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

typedef SpriteFile =
{
	var animations:Array<SpriteAnimArray>;
	var image:String;
	var scale:Float;
	var global_offset:Array<Float>;
	var layer:Int;

	var flip_x:Bool;
	var no_antialiasing:Bool;
}

typedef SpriteAnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	var finishCallback:String;
	var angle:Float;
}

// I don't fully understand the effects of making this class a child of Character directly
// From what I gather, the fact that zDepth cannot be redefined if CharacterExtra extends Character instead of FlxSprite
// leads me to believe that extending Character would just make this some kind of pseudo-character that probably copies a bunch of memory like health values and whatnot
// Hard to get clear understanding of what's all going on here but that's why this isn't inheriting Character and goes straight for FlxSprite
class CharacterExtra extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public var generalOffset:Array<Float> = [0, 0];
	public var animAngle:Map<String, Float> = new Map<String, Float>();

	public var thisSprite:String = '';

	// Constant for organizing layers according to base character
	// (e.g. layer 1 for bf's face, unblockable effect is layer 2 to ensure it overlaps both bf himself and his face)
	// Basically this number is added to this object's zDepth so it layers with the base character properly
	public var layer:Int = 1;
	public var zDepth:Int = 0;

	public var isPlayer:Bool = true;
	public var curCharacter:String = '';
	public var animationsArray:Array<SpriteAnimArray> = [];
	public var positionArray:Array<Float> = [0, 0];

	// For Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var curEffect:Bool = false;
	public var debugMode:Bool = false;

	public var animCallbacks:Map<String, String> = new Map<String, String>();

	public static var validCallbacks:Array<String> = ['', 'finish', 'toLoopAnim', 'fade'];

	public function new(x:Float, y:Float, character:Character, name:String)
	{
		super(x, y);

		this.thisSprite = name;
		// Not assigning the entire character to a Character variable since I believe that probably duplicates the character data for each sprite
		// Basically that eats up far more memory than needed, so just pull whatever info you need on construction
		this.curCharacter = character.curCharacter;
		this.isPlayer = character.isPlayer;
		character.characterSprites.add(this);

		// Character does this and causes a mismatch if it's not replicated here
		if (isPlayer)
			flipX = !flipX;

		visible = false;

		animation.finishCallback = function(name:String)
		{
			switch (animCallbacks.get(animation.curAnim.name))
			{
				case 'toLoopAnim':
					if (visible && alpha > 0)
						playAnim(animation.curAnim.name + 'LOOP');
				case 'finish':
					visible = false;
				case 'fade':
					FlxTween.tween(this, {alpha: 0}, 0.05, {ease: FlxEase.quadIn});
			}
		}

		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':
			// Also I yoinked this whole thing from PsychEngine's json method
			default:
				var spritePath:String = 'characters/characterExtras/' + thisSprite + '.json';

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(spritePath);
				if (!FileSystem.exists(path))
				{
					path = Paths.getPreloadPath(spritePath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(spritePath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/' + Character.DEFAULT_CHARACTER +
						'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:SpriteFile = cast Json.parse(rawJson);
				var spriteType = "sparrow";
				// sparrow
				// packer
				// texture
				#if MODS_ALLOWED
				var modTxtToFind:String = Paths.modsTxt(json.image);
				var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);

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

				if (json.global_offset != null)
					generalOffset = json.global_offset;
				layer = json.layer;

				flipX = !!json.flip_x;
				if (json.no_antialiasing)
				{
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.scale != 1)
				{
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

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

						if (anim.finishCallback != null)
						{
							animCallbacks.set(animAnim, anim.finishCallback);
						}
					}
				}
				else
				{
					quickAnimAdd('idle', 'BF idle dance');
				}

				playAnim('idle');
		}

		originalFlipX = flipX;
		zDepth += layer;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function animate(x:Float, y:Float, curAnim:String, zDepth:Int, guardPosition:Int = 0):Void
	{
		// Layering may end up incorrect on first use of anim without this zDepth check
		this.zDepth = zDepth + layer;
		// Double-checking x and y of sprite matches parent Character so offsets will work
		this.x = x;
		this.y = y;

		if (animation.getByName(curAnim) != null)
			playAnim(curAnim, true);
		// alpha == 1 checks if something is in the middle of fading out
		else if (alpha == 1)
			visible = false;
	}

	// Private since ideally this function should only need to be called within this class
	// One-stop shop for controlling CharacterExtra animations. Easier and more dynamic than having to directly call every case an animation should change
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		visible = true;
		alpha = 1;

		animation.play(AnimName, Force, Reversed, Frame);

		// Offset logic tweaked a bit to add in a generalOffset component
		var daOffset:Array<Float> = [0, 0];

		if (animOffsets.exists(AnimName))
			daOffset = animOffsets.get(AnimName);

		offset.set(daOffset[0] + generalOffset[0], daOffset[1] + generalOffset[1]);

		var daAngle:Float = 0;
		if (animAngle.exists(AnimName))
			daAngle += animAngle.get(AnimName);

		angle = daAngle;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets.set(name, [x, y]);
	}

	public function addAngle(name:String, degree:Float = 0)
	{
		animAngle.set(name, degree);
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}
}
