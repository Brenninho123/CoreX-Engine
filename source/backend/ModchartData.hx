package backend;

import haxe.Json;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

typedef ModchartEvent =
{
	var step:Int;
	var type:String;
	@:optional var value:Dynamic;
	@:optional var value2:Dynamic;
	@:optional var duration:Float;
	@:optional var ease:String;
	@:optional var target:String;
}

typedef ModchartFile =
{
	var song:String;
	var bpm:Float;
	var events:Array<ModchartEvent>;
}

class ModchartData
{
	public static var loadedModcharts:Map<String, ModchartFile> = new Map();

	public static function createModchart(song:String):ModchartFile
	{
		return {
			song: song,
			bpm: 100,
			events: [
				{
					step: 0,
					type: "cameraZoom",
					value: 0.05
				},
				{
					step: 16,
					type: "hudAngle",
					value: 5,
					duration: 0.5,
					ease: "cubeOut"
				},
				{
					step: 32,
					type: "strumMoveX",
					target: "player",
					value: 120,
					duration: 1
				}
			]
		};
	}

	public static function getPath(song:String):String
	{
		return Mods.getModchartPath(song);
	}

	public static function exists(song:String):Bool
	{
		var path:String = getPath(song);

		#if sys
		return FileSystem.exists(path);
		#else
		return OpenFlAssets.exists(path);
		#end
	}

	public static function load(song:String):ModchartFile
	{
		var formattedSong:String = Paths.formatToSongPath(song);

		if(loadedModcharts.exists(formattedSong))
			return loadedModcharts.get(formattedSong);

		var path:String = getPath(formattedSong);

		var rawJson:String = null;

		#if sys
		if(FileSystem.exists(path))
			rawJson = File.getContent(path);
		#else
		if(OpenFlAssets.exists(path))
			rawJson = Assets.getText(path);
		#end

		if(rawJson == null || rawJson.length < 1)
			return null;

		try
		{
			var json:ModchartFile = cast tjson.TJSON.parse(rawJson);

			if(json.song == null)
				json.song = formattedSong;

			if(json.events == null)
				json.events = [];

			loadedModcharts.set(formattedSong, json);

			return json;
		}
		catch(e:Dynamic)
		{
			trace('Failed to load modchart: ' + formattedSong);
			trace(e);
		}

		return null;
	}

	public static function save(song:String, data:ModchartFile):Void
	{
		#if sys

		var path:String = getPath(song);
		var folder:String = haxe.io.Path.directory(path);

		if(!FileSystem.exists(folder))
			FileSystem.createDirectory(folder);

		File.saveContent(
			path,
			Json.stringify(data, "\t")
		);

		loadedModcharts.set(
			Paths.formatToSongPath(song),
			data
		);

		#end
	}

	public static function clearCache():Void
	{
		loadedModcharts.clear();
	}

	public static function reload(song:String):ModchartFile
	{
		var formattedSong:String = Paths.formatToSongPath(song);

		if(loadedModcharts.exists(formattedSong))
			loadedModcharts.remove(formattedSong);

		return load(formattedSong);
	}
}