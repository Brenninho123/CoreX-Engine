package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

class SkinsSelectorSubState extends MusicBeatSubstate
{
	var skins:Array<String> = [];
	var grpSkins:FlxTypedGroup<Alphabet>;

	var curSelected:Int = 0;

	var preview:Character;
	var descText:FlxText;

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(
			Std.int(FlxG.width),
			Std.int(FlxG.height),
			0xFF000000
		);

		bg.alpha = 0.6;

		add(bg);

		loadCharacters();

		grpSkins = new FlxTypedGroup<Alphabet>();
		add(grpSkins);

		for (i in 0...skins.length)
		{
			var item:Alphabet = new Alphabet(0, 0, skins[i], true);

			item.screenCenter(X);
			item.y = 120 + (i * 70);

			grpSkins.add(item);
		}

		preview = new Character(900, 300, skins[0], true);
		preview.scale.set(0.8, 0.8);
		preview.updateHitbox();

		add(preview);

		descText = new FlxText(
			0,
			FlxG.height - 60,
			FlxG.width,
			"",
			24
		);

		descText.setFormat(
			"VCR OSD Mono",
			24,
			FlxColor.WHITE,
			CENTER
		);

		add(descText);

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);

		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();

		#if mobile
		addTouchPad("UP_DOWN", "A_B");
		#end
	}

	function loadCharacters():Void
	{
		var folders:Array<String> = [
			'assets/shared/images/characters/',
			'mods/characters/'
		];

		for (folder in folders)
		{
			if (!FileSystem.exists(folder))
				continue;

			for (file in FileSystem.readDirectory(folder))
			{
				if (!file.endsWith('.json'))
					continue;

				var charName:String = file.substr(0, file.length - 5);

				if (!skins.contains(charName))
					skins.push(charName);
			}
		}

		if (skins.length < 1)
			skins.push("bf");
	}

	function updateCharacter():Void
	{
		if (preview != null)
		{
			remove(preview);
			preview.destroy();
		}

		preview = new Character(900, 300, skins[curSelected], true);

		preview.scale.set(0.8, 0.8);
		preview.updateHitbox();

		add(preview);

		loadCharacterInfo();
	}

	function loadCharacterInfo():Void
	{
		var char:String = skins[curSelected];

		var paths:Array<String> = [
			'assets/shared/images/characters/$char.json',
			'mods/characters/$char.json'
		];

		for (path in paths)
		{
			if (!FileSystem.exists(path))
				continue;

			try
			{
				var raw:String = File.getContent(path);

				var json:Dynamic = Json.parse(raw);

				var image:String = json.image != null
					? json.image
					: "unknown";

				var healthicon:String = json.healthicon != null
					? json.healthicon
					: "unknown";

				descText.text =
					'Character: $char\n' +
					'Image: $image\n' +
					'Icon: $healthicon';

				return;
			}
			catch(e:Dynamic)
			{
				descText.text = 'Invalid JSON';
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = skins.length - 1;

		if (curSelected >= skins.length)
			curSelected = 0;

		var num:Int = 0;

		for (item in grpSkins.members)
		{
			item.targetY = num - curSelected;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;

				selectorLeft.x = item.x - 60;
				selectorLeft.y = item.y;

				selectorRight.x = item.x + item.width + 20;
				selectorRight.y = item.y;
			}

			num++;
		}

		updateCharacter();

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);

		if (controls.UI_DOWN_P)
			changeSelection(1);

		#if mobile
		if (touchPad.buttonUp.justPressed)
			changeSelection(-1);

		if (touchPad.buttonDown.justPressed)
			changeSelection(1);
		#end

		if (controls.ACCEPT
			#if mobile
			|| touchPad.buttonA.justPressed
			#end
		)
		{
			ClientPrefs.data.boyfriendSkin = skins[curSelected];
			ClientPrefs.saveSettings();

			FlxG.sound.play(Paths.sound('confirmMenu'));
		}

		if (controls.BACK
			#if mobile
			|| touchPad.buttonB.justPressed
			#end
		)
		{
			#if mobile
			removeTouchPad();
			#end

			close();

			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}
}