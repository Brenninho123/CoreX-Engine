package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int = 0;

	@:noCompletion
	private var times:Array<Float> = [];

	@:noCompletion
	private var cacheCount:Int = 0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		selectable = false;
		mouseEnabled = false;
		multiline = false;
		wordWrap = false;
		autoSize = LEFT;

		defaultTextFormat = new TextFormat("_sans", 16, color, true);

		width = 200;
		height = 32;

		text = "FPS: 0";

		#if mobile
		scaleX = 1.2;
		scaleY = 1.2;
		#end
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp();

		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		cacheCount = times.length;

		currentFPS = cacheCount > FlxG.drawFramerate
			? FlxG.drawFramerate
			: cacheCount;

		updateText();
	}

	public dynamic function updateText():Void
	{
		text = 'FPS: $currentFPS';

		if (currentFPS >= 110)
			textColor = 0xFFFFFFFF;
		else if (currentFPS >= 80)
			textColor = 0xFFFFFF00;
		else if (currentFPS >= 45)
			textColor = 0xFFFF8800;
		else
			textColor = 0xFFFF0000;
	}

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1):Void
	{
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;

		scaleX = scale;
		scaleY = scale;
	}
}