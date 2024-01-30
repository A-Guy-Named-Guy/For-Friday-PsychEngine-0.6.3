package;

import animateatlas.AtlasFrameMaker;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxImageFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
// import lime.math.Rectangle;
import openfl.utils.Assets;

using StringTools;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

class ReflexGuardArrow extends FlxSprite
{
	public var guardArrowPosition:Int;

	var parentArrow:FlxSprite;
	var reflexTimer:FlxTimer;
	var singGuardTimer:FlxTimer;

	var thisAngle:Int;
	var arrowClipBox:FlxRect;

	public function new(backgroundArrow:FlxSprite, reflexTimer:FlxTimer, singGuardTimer:FlxTimer, guardArrowValue:Int, color:FlxColor, angle:Int, image:String)
	{
		parentArrow = backgroundArrow;
		this.reflexTimer = reflexTimer;
		this.singGuardTimer = singGuardTimer;

		super(parentArrow.x, parentArrow.y);
		guardArrowPosition = guardArrowValue;
		thisAngle = angle;

		loadGraphic(Paths.image(image));

		arrowClipBox = new FlxRect(0, 0, parentArrow.width, parentArrow.height);
	}

	override function update(elapsed:Float):Void
	{
		if (reflexTimer.active || singGuardTimer.active)
		{
			x = parentArrow.x;
			y = parentArrow.y;
			visible = true;

			angle = 0;
			arrowClipBox.width = parentArrow.width;

			var timeLeft = singGuardTimer.active ? singGuardTimer.timeLeft : reflexTimer.timeLeft;

			// This whole bar-stamping method I swiped from FlxBar
			// It took a lot of fiddling to figure out how to get things working though
			// One of the more complicated bits to get put together so far
			var scaleInterval:Float = parentArrow.width / 100;
			var interval:Float = Math.round(Std.int(timeLeft * parentArrow.width / scaleInterval) * scaleInterval);

			arrowClipBox.width = Std.int(interval);
			frame = frame.clipTo(arrowClipBox, frame);

			angle = thisAngle;
		}
		else
			visible = false;
	}
}
