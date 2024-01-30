package;

import PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

using StringTools;

class TimeIndicator extends FlxSprite
{
	public var side:String = 'left';
	public var beatCount:Int = 0;
	public var timeExisted:Float = 0;

	public function new(x:Float, y:Float, side:String, beatCount:Int, timeExisted:Float)
	{
		super(x, y);

		this.side = side;

		frames = Paths.getSparrowAtlas('notes/timingIndicator');

		if (side == 'left')
		{
			animation.addByPrefix('activeLeft', 'timingIndicator leftBeatActive0000', 24, false);
			animation.play('activeLeft');
		}
		else
		{
			animation.addByPrefix('activeRight', 'timingIndicator rightBeatActive0000', 24, false);
			animation.play('activeRight');
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
		antialiasing = true;
	}
}
