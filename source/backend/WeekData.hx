package backend;

import haxe.Json;
import haxe.io.Path;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

typedef WeekSong =
{
	var name:String;
	var icon:String;
	var color:Array<Int>;
}

typedef WeekFile =
{
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;

	@:optional var weekBanner:String;
	@:optional var weekLogo:String;
	@:optional var weekDescription:String;
	@:optional var disableFreeplayIcon:Bool;
	@:optional var weekMusic:String;
	@:optional var menuStyle:String;
	@:optional var weekColor:String;
	@:optional var version:String;
	@:optional var mod:String;
}

class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = [];
	public static var weeksList:Array<String> = [];

	public static var invalidWeeks:Array<String> = [];

	public var folder:String = "";
	public var fileName:String = "";

	public var songs:Array<Dynamic> = [];
	public var weekCharacters:Array<String> = [];
	public var weekBackground:String = "stage";
	public var weekBefore:String = "";
	public var storyName:String = "Story";
	public var weekName:String = "Custom Week";
	public var freeplayColor:Array<Int> = [146, 113, 253];
	public var startUnlocked:Bool = true;
	public var hiddenUntilUnlocked:Bool = false;
	public var hideStoryMode:Bool = false;
	public var hideFreeplay:Bool = false;
	public var difficulties:String = "";

	public var weekBanner:String = "";
	public var weekLogo:String = "";
	public var weekDescription:String = "";
	public var disableFreeplayIcon:Bool = false;
	public var weekMusic:String = "";
	public var menuStyle:String = "default";
	public var weekColor:String = "#FFFFFF";
	public var version:String = "1.0";
	public var mod:String = "";

	public function new(data:WeekFile, file:String)
	{
		loadData(data);

		fileName = file;
	}

	function loadData(data:WeekFile):Void
	{
		for (field in Reflect.fields(data))
		{
			if (Reflect.hasField(this, field))
			{
				Reflect.setProperty(
					this,
					field,
					Reflect.getProperty(data, field)
				);
			}
		}
	}

	public static function createWeekFile():WeekFile
	{
		return {
			songs: [
				["Bopeebo", "dad", [146, 113, 253]],
				["Fresh", "dad", [146, 113, 253]],
				["Dad Battle", "dad", [146, 113, 253]]
			],

			weekCharacters: ["dad", "bf", "gf"],

			weekBackground: "stage",
			weekBefore: "tutorial",

			storyName: "Your New Week",
			weekName: "Custom Week",

			freeplayColor: [146, 113, 253],

			startUnlocked: true,
			hiddenUntilUnlocked: false,

			hideStoryMode: false,
			hideFreeplay: false,

			difficulties: "",

			weekBanner: "",
			weekLogo: "",
			weekDescription: "A custom week.",
			disableFreeplayIcon: false,
			weekMusic: "",
			menuStyle: "default",
			weekColor: "#FFFFFF",
			version: "1.0",
			mod: ""
		};
	}

	public static function reloadWeekFiles(?isStoryMode:Null<Bool> = false):Void
	{
		weeksLoaded.clear();
		weeksList = [];
		invalidWeeks = [];

		var directories:Array<String> = [];
		var originalLength:Int = 0;

		#if MODS_ALLOWED

		directories = [
			Paths.mods(),
			Paths.getSharedPath()
		];

		originalLength = directories.length;

		for (mod in Mods.parseList().enabled)
			directories.push(Paths.mods(mod + "/"));

		#else

		directories = [Paths.getSharedPath()];
		originalLength = directories.length;

		#end

		for (directory in directories)
		{
			loadWeeksFromDirectory(
				directory,
				isStoryMode,
				originalLength
			);
		}

		sortWeeks();
	}

	static function loadWeeksFromDirectory(
		directory:String,
		isStoryMode:Null<Bool>,
		originalLength:Int
	):Void
	{
		var weeksPath:String = directory + "weeks/";

		#if MODS_ALLOWED
		if (!FileSystem.exists(weeksPath))
			return;
		#end

		var weekList:Array<String> = [];

		var listPath:String = weeksPath + "weekList.txt";

		if (exists(listPath))
			weekList = CoolUtil.coolTextFile(listPath);

		#if MODS_ALLOWED
		for (file in Paths.readDirectory(weeksPath))
		{
			if (file.endsWith(".json"))
			{
				var weekName:String =
					file.substr(0, file.length - 5);

				if (!weekList.contains(weekName))
					weekList.push(weekName);
			}
		}
		#end

		for (weekName in weekList)
		{
			var path:String = weeksPath + weekName + ".json";

			if (!exists(path))
				continue;

			loadWeek(
				weekName,
				path,
				directory,
				isStoryMode,
				originalLength
			);
		}
	}

	static function loadWeek(
		name:String,
		path:String,
		directory:String,
		isStoryMode:Null<Bool>,
		originalLength:Int
	):Void
	{
		if (weeksLoaded.exists(name))
			return;

		var file:WeekFile = getWeekFile(path);

		if (file == null)
		{
			invalidWeeks.push(name);
			return;
		}

		var data:WeekData = new WeekData(file, name);

		#if MODS_ALLOWED
		if (directory != Paths.getSharedPath())
		{
			data.folder = directory.substring(
				Paths.mods().length,
				directory.length - 1
			);
		}
		#end

		if (!canLoadWeek(data, isStoryMode))
			return;

		weeksLoaded.set(name, data);
		weeksList.push(name);
	}

	static function canLoadWeek(
		data:WeekData,
		isStoryMode:Null<Bool>
	):Bool
	{
		if (isStoryMode == null)
			return true;

		if (isStoryMode)
			return !data.hideStoryMode;

		return !data.hideFreeplay;
	}

	static function sortWeeks():Void
	{
		weeksList.sort(function(a, b)
		{
			return Reflect.compare(a.toLowerCase(), b.toLowerCase());
		});
	}

	public static function getWeekFile(path:String):WeekFile
	{
		var rawJson:String = null;

		#if MODS_ALLOWED
		if (FileSystem.exists(path))
			rawJson = File.getContent(path);
		#else
		if (OpenFlAssets.exists(path))
			rawJson = Assets.getText(path);
		#end

		if (rawJson == null || rawJson.trim().length < 1)
			return null;

		try
		{
			return cast tjson.TJSON.parse(rawJson);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	public static function exists(path:String):Bool
	{
		#if MODS_ALLOWED
		return FileSystem.exists(path);
		#else
		return OpenFlAssets.exists(path);
		#end
	}

	public static function getWeekFileName():String
	{
		return weeksList[PlayState.storyWeek];
	}

	public static function getCurrentWeek():WeekData
	{
		return weeksLoaded.get(
			weeksList[PlayState.storyWeek]
		);
	}

	public static function getWeek(name:String):WeekData
	{
		return weeksLoaded.get(name);
	}

	public static function weekExists(name:String):Bool
	{
		return weeksLoaded.exists(name);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null):Void
	{
		Mods.currentModDirectory = "";

		if (data != null
			&& data.folder != null
			&& data.folder.length > 0)
		{
			Mods.currentModDirectory = data.folder;
		}
	}

	public static function getWeekColor(data:WeekData):Int
	{
		if (data == null)
			return 0xFFFFFFFF;

		if (data.freeplayColor == null
			|| data.freeplayColor.length < 3)
		{
			return 0xFFFFFFFF;
		}

		return flixel.util.FlxColor.fromRGB(
			data.freeplayColor[0],
			data.freeplayColor[1],
			data.freeplayColor[2]
		);
	}

	public function getSongs():Array<String>
	{
		var list:Array<String> = [];

		for (song in songs)
		{
			if (song != null && song.length > 0)
				list.push(song[0]);
		}

		return list;
	}

	public function getCharacters():Array<String>
	{
		return weekCharacters.copy();
	}
}