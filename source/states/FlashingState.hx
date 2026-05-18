package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var bg:FlxSprite;
	var panel:FlxSprite;

	var warnText:FlxText;
	var infoText:FlxText;

	var allowInput:Bool = false;

	override function create()
	{
		super.create();

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		bg = new FlxSprite().makeGraphic(
			Std.int(FlxG.width),
			Std.int(FlxG.height),
			0xFF000000
		);

		bg.alpha = 0;

		add(bg);

		panel = new FlxSprite().makeGraphic(
			900,
			420,
			0xFF111111
		);

		panel.screenCenter();
		panel.alpha = 0;
		panel.scale.set(0.7, 0.7);

		add(panel);

		var titleText:FlxText = new FlxText(
			0,
			panel.y + 30,
			FlxG.width,
			"WARNING",
			42
		);

		titleText.setFormat(
			"VCR OSD Mono",
			42,
			FlxColor.RED,
			CENTER,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		titleText.alpha = 0;

		add(titleText);

		warnText = new FlxText(
			0,
			panel.y + 110,
			FlxG.width,
			"This Mod contains flashing lights\nand visual effects.",
			32
		);

		warnText.setFormat(
			"VCR OSD Mono",
			32,
			FlxColor.WHITE,
			CENTER,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		warnText.alpha = 0;

		add(warnText);

		#if mobile
		var controlsText:String =
			"Press A to disable flashing lights\nPress B to continue";
		#else
		var controlsText:String =
			"Press ENTER to disable flashing lights\nPress ESCAPE to continue";
		#end

		infoText = new FlxText(
			0,
			panel.y + 270,
			FlxG.width,
			controlsText,
			24
		);

		infoText.setFormat(
			"VCR OSD Mono",
			24,
			FlxColor.GRAY,
			CENTER,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		infoText.alpha = 0;

		add(infoText);

		controls.isInSubstate = false;

		#if mobile
		addTouchPad("NONE", "A_B");
		#end

		introAnimation(
			titleText
		);
	}

	function introAnimation(titleText:FlxText):Void
	{
		FlxTween.tween(
			bg,
			{alpha: 0.75},
			0.5
		);

		FlxTween.tween(
			panel,
			{
				alpha: 1,
				"scale.x": 1,
				"scale.y": 1
			},
			0.7,
			{
				ease: FlxEase.backOut
			}
		);

		FlxTween.tween(
			titleText,
			{alpha: 1},
			0.4,
			{
				startDelay: 0.15
			}
		);

		FlxTween.tween(
			warnText,
			{alpha: 1},
			0.4,
			{
				startDelay: 0.3
			}
		);

		FlxTween.tween(
			infoText,
			{alpha: 1},
			0.4,
			{
				startDelay: 0.45,
				onComplete: function(twn:FlxTween)
				{
					allowInput = true;
				}
			}
		);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!allowInput || leftState)
			return;

		var accepted:Bool = controls.ACCEPT;
		var declined:Bool = controls.BACK;

		#if mobile
		accepted = accepted || touchPad.buttonA.justPressed;
		declined = declined || touchPad.buttonB.justPressed;
		#end

		if (accepted)
		{
			leftState = true;

			ClientPrefs.data.flashing = false;
			ClientPrefs.saveSettings();

			FlxG.sound.play(
				Paths.sound('confirmMenu')
			);

			exitAnimation(true);
		}

		if (declined)
		{
			leftState = true;

			FlxG.sound.play(
				Paths.sound('cancelMenu')
			);

			exitAnimation(false);
		}
	}

	function exitAnimation(disabled:Bool):Void
	{
		allowInput = false;

		if (disabled)
		{
			FlxFlicker.flicker(
				warnText,
				1,
				0.08,
				false,
				false
			);
		}

		FlxTween.tween(
			panel.scale,
			{
				x: 0.8,
				y: 0.8
			},
			0.4,
			{
				ease: FlxEase.quadIn
			}
		);

		FlxTween.tween(
			panel,
			{alpha: 0},
			0.5
		);

		FlxTween.tween(
			warnText,
			{alpha: 0},
			0.35
		);

		FlxTween.tween(
			infoText,
			{alpha: 0},
			0.35
		);

		FlxTween.tween(
			bg,
			{alpha: 0},
			0.6,
			{
				onComplete: function(twn:FlxTween)
				{
					new FlxTimer().start(
						0.1,
						function(tmr:FlxTimer)
						{
							MusicBeatState.switchState(
								new TitleState()
							);
						}
					);
				}
			}
		);
	}
}