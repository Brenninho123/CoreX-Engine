package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;

import lime.app.Application;

import options.OptionsState;
import states.editors.MasterEditorMenu;

class MainMenuState extends MusicBeatState
{
	public static var engineVersion:String = "0.1.0";
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits',
		'options'
	];

	var bg:FlxSprite;
	var checker:FlxSprite;
	var magenta:FlxSprite;

	var camFollow:FlxObject;

	var selectedSomethin:Bool = false;

	var versionText:FlxText;
	var fnfText:FlxText;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		Mods.loadTopMod();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(
			"In the Menus",
			null
		);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = true;
		persistentDraw = true;

		bg = new FlxSprite().loadGraphic(
			Paths.image('menuBG')
		);

		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(
			Std.int(bg.width * 1.2)
		);

		bg.updateHitbox();
		bg.screenCenter();

		add(bg);

		checker = new FlxSprite().loadGraphic(
			Paths.image('checker')
		);

		checker.alpha = 0.05;
		checker.scale.set(1.5, 1.5);
		checker.updateHitbox();
		checker.screenCenter();

		add(checker);

		magenta = new FlxSprite().loadGraphic(
			Paths.image('menuDesat')
		);

		magenta.antialiasing =
			ClientPrefs.data.antialiasing;

		magenta.visible = false;
		magenta.color = 0xFFFF3C6E;

		magenta.setGraphicSize(
			Std.int(magenta.width * 1.2)
		);

		magenta.updateHitbox();
		magenta.screenCenter();

		add(magenta);

		camFollow = new FlxObject(0, 0, 1, 1);

		add(camFollow);

		menuItems = new FlxTypedGroup<FlxSprite>();

		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite =
				new FlxSprite(
					0,
					180 + (i * 150)
				);

			menuItem.frames = Paths.getSparrowAtlas(
				'mainmenu/menu_' + optionShit[i]
			);

			menuItem.animation.addByPrefix(
				'idle',
				optionShit[i] + " basic",
				24
			);

			menuItem.animation.addByPrefix(
				'selected',
				optionShit[i] + " white",
				24
			);

			menuItem.animation.play('idle');

			menuItem.antialiasing =
				ClientPrefs.data.antialiasing;

			menuItem.scrollFactor.set();

			menuItem.updateHitbox();
			menuItem.screenCenter(X);

			menuItems.add(menuItem);
		}

		versionText = new FlxText(
			12,
			FlxG.height - 48,
			0,
			"CoreX Engine v" + engineVersion,
			18
		);

		versionText.setFormat(
			"VCR OSD Mono",
			18,
			FlxColor.WHITE,
			LEFT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		versionText.scrollFactor.set();

		add(versionText);

		fnfText = new FlxText(
			12,
			FlxG.height - 24,
			0,
			"Friday Night Funkin' v" + Application.current.meta.get('version'),
			18
		);

		fnfText.setFormat(
			"VCR OSD Mono",
			18,
			FlxColor.WHITE,
			LEFT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		fnfText.scrollFactor.set();

		add(fnfText);

		changeItem();

		#if mobile
		addTouchPad("UP_DOWN", "A_B_E");
		#end

		super.create();

		FlxG.camera.follow(
			camFollow,
			null,
			8
		);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		checker.x -= 20 * elapsed;
		checker.y -= 20 * elapsed;

		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.volume < 0.8)
				FlxG.sound.music.volume += elapsed * 0.5;
		}

		if (selectedSomethin)
			return;

		if (controls.UI_UP_P)
			changeItem(-1);

		if (controls.UI_DOWN_P)
			changeItem(1);

		if (controls.BACK)
		{
			selectedSomethin = true;

			FlxG.sound.play(
				Paths.sound('cancelMenu')
			);

			MusicBeatState.switchState(
				new TitleState()
			);
		}

		if (controls.ACCEPT)
		{
			selectOption();
		}

		#if mobile
		if (touchPad.buttonE.justPressed)
		{
			selectedSomethin = true;

			MusicBeatState.switchState(
				new MasterEditorMenu()
			);
		}
		#else
		if (controls.justPressed('debug_1'))
		{
			selectedSomethin = true;

			MusicBeatState.switchState(
				new MasterEditorMenu()
			);
		}
		#end
	}

	function selectOption()
	{
		selectedSomethin = true;

		FlxG.sound.play(
			Paths.sound('confirmMenu')
		);

		if (ClientPrefs.data.flashing)
		{
			FlxFlicker.flicker(
				magenta,
				1,
				0.15,
				false
			);
		}

		FlxFlicker.flicker(
			menuItems.members[curSelected],
			1,
			0.06,
			false,
			false,
			function(flick:FlxFlicker)
			{
				switch (optionShit[curSelected])
				{
					case 'story_mode':
						MusicBeatState.switchState(
							new StoryMenuState()
						);

					case 'freeplay':
						MusicBeatState.switchState(
							new FreeplayState()
						);

					case 'credits':
						MusicBeatState.switchState(
							new CreditsState()
						);

					case 'options':
						OptionsState.onPlayState = false;

						if (PlayState.SONG != null)
						{
							PlayState.SONG.arrowSkin = null;
							PlayState.SONG.splashSkin = null;
							PlayState.stageUI = 'normal';
						}

						MusicBeatState.switchState(
							new OptionsState()
						);
				}
			}
		);

		for (i in 0...menuItems.length)
		{
			if (i == curSelected)
				continue;

			FlxTween.tween(
				menuItems.members[i],
				{
					alpha: 0,
					x: menuItems.members[i].x - 300
				},
				0.4,
				{
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween)
					{
						menuItems.members[i].kill();
					}
				}
			);
		}
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(
			Paths.sound('scrollMenu')
		);

		menuItems.members[curSelected]
			.animation.play('idle');

		menuItems.members[curSelected]
			.screenCenter(X);

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		var item = menuItems.members[curSelected];

		item.animation.play('selected');

		item.centerOffsets();
		item.screenCenter(X);

		camFollow.setPosition(
			item.getGraphicMidpoint().x,
			item.getGraphicMidpoint().y
		);

		for (i in 0...menuItems.length)
		{
			var spr = menuItems.members[i];

			if (i == curSelected)
			{
				spr.alpha = 1;
				spr.scale.set(1, 1);
			}
			else
			{
				spr.alpha = 0.65;
				spr.scale.set(0.9, 0.9);
			}

			spr.updateHitbox();
		}
	}
}