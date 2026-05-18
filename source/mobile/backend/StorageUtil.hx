package mobile.backend;

import haxe.Exception;
import haxe.io.Path;
import lime.app.Application;
import lime.system.System as LimeSystem;
import sys.FileSystem;
import sys.io.File;

#if android
import android.permissions.AndroidPermissions;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
#end

class StorageUtil
{
	#if sys

	public static final rootDir:String = LimeSystem.applicationStorageDirectory;

	public static inline var SAVE_FOLDER:String = "saves";
	public static inline var STORAGE_FILE:String = "storagetype.txt";

	public static function getStorageDirectory(?force:Bool = false):String
	{
		var path:String = "";

		#if android

		initializeStorageFile();

		var currentType:String = getStorageType();

		path = force
			? StorageType.fromStrForce(currentType)
			: StorageType.fromStr(currentType);

		path = normalize(path);

		#elseif ios

		path = normalize(LimeSystem.documentsDirectory);

		#else

		path = normalize(Sys.getCwd());

		#end

		createDirectory(path);

		return path;
	}

	public static function getStorageType():String
	{
		try
		{
			return StringTools.trim(
				File.getContent(rootDir + STORAGE_FILE)
			);
		}
		catch (e:Dynamic)
		{
			return "EXTERNAL";
		}
	}

	public static function setStorageType(type:String):Void
	{
		try
		{
			File.saveContent(rootDir + STORAGE_FILE, type);
		}
		catch (e:Dynamic) {}
	}

	static function initializeStorageFile():Void
	{
		try
		{
			if (!FileSystem.exists(rootDir))
				FileSystem.createDirectory(rootDir);

			if (!FileSystem.exists(rootDir + STORAGE_FILE))
				File.saveContent(rootDir + STORAGE_FILE, ClientPrefs.data.storageType);
		}
		catch (e:Dynamic) {}
	}

	public static function createDirectory(path:String):Void
	{
		try
		{
			if (!FileSystem.exists(path))
				FileSystem.createDirectory(path);
		}
		catch (e:Dynamic) {}
	}

	public static function normalize(path:String):String
	{
		if (path == null || path.length < 1)
			return "";

		return Path.addTrailingSlash(path);
	}

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Bool
	{
		try
		{
			createDirectory(SAVE_FOLDER);

			var fullPath:String = normalize(SAVE_FOLDER) + fileName;

			File.saveContent(fullPath, fileData);

			if (alert)
				CoolUtil.showPopUp(fileName + " saved successfully.", "CoreX Engine");

			return true;
		}
		catch (e:Exception)
		{
			if (alert)
				CoolUtil.showPopUp(fileName + " couldn't be saved.\n(" + e.message + ")", "Error");

			return false;
		}
	}

	public static function readContent(fileName:String):String
	{
		try
		{
			var fullPath:String = normalize(SAVE_FOLDER) + fileName;

			if (FileSystem.exists(fullPath))
				return File.getContent(fullPath);
		}
		catch (e:Dynamic) {}

		return "";
	}

	public static function deleteFile(fileName:String):Bool
	{
		try
		{
			var fullPath:String = normalize(SAVE_FOLDER) + fileName;

			if (FileSystem.exists(fullPath))
			{
				FileSystem.deleteFile(fullPath);
				return true;
			}
		}
		catch (e:Dynamic) {}

		return false;
	}

	#if android

	public static function requestPermissions():Void
	{
		try
		{
			if (VERSION.SDK_INT >= VERSION_CODES.TIRAMISU)
			{
				AndroidPermissions.requestPermissions([
					"READ_MEDIA_IMAGES",
					"READ_MEDIA_VIDEO",
					"READ_MEDIA_AUDIO"
				]);
			}
			else
			{
				AndroidPermissions.requestPermissions([
					"READ_EXTERNAL_STORAGE",
					"WRITE_EXTERNAL_STORAGE"
				]);
			}

			if (!AndroidEnvironment.isExternalStorageManager())
			{
				if (VERSION.SDK_INT >= VERSION_CODES.S)
					AndroidSettings.requestSetting("REQUEST_MANAGE_MEDIA");

				AndroidSettings.requestSetting(
					"MANAGE_APP_ALL_FILES_ACCESS_PERMISSION"
				);
			}

			verifyPermissions();
			verifyStorageAccess();
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(
				"Permission request failed.",
				"CoreX Engine"
			);
		}
	}

	static function verifyPermissions():Void
	{
		var granted:Array<String> = AndroidPermissions.getGrantedPermissions();

		var hasPermission:Bool =
			VERSION.SDK_INT >= VERSION_CODES.TIRAMISU
			? granted.contains("android.permission.READ_MEDIA_IMAGES")
			: granted.contains("android.permission.READ_EXTERNAL_STORAGE");

		if (!hasPermission)
		{
			CoolUtil.showPopUp(
				"Storage permission denied.\nGame may crash.",
				"Warning"
			);
		}
	}

	static function verifyStorageAccess():Void
	{
		try
		{
			var path:String = getStorageDirectory();

			if (!FileSystem.exists(path))
				FileSystem.createDirectory(path);
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(
				"Cannot access storage:\n" + getStorageDirectory(true),
				"Fatal Error"
			);

			LimeSystem.exit(1);
		}
	}

	public static function checkExternalPaths(?splitStorage:Bool = false):Array<String>
	{
		try
		{
			var process = new sys.io.Process(
				'grep -o "/storage/....-...." /proc/mounts | paste -sd \',\''
			);

			var paths:String = process.stdout.readAll().toString();

			if (splitStorage)
				paths = paths.replace("/storage/", "");

			return paths.split(",");
		}
		catch (e:Dynamic)
		{
			return [];
		}
	}

	public static function getExternalDirectory(externalDir:String):String
	{
		var finalPath:String = "";

		for (path in checkExternalPaths())
		{
			if (path.contains(externalDir))
				finalPath = path;
		}

		finalPath = finalPath.endsWith("\n")
			? finalPath.substr(0, finalPath.length - 1)
			: finalPath;

		return normalize(finalPath);
	}

	#end
	#end
}

#if android
@:runtimeValue
enum abstract StorageType(String) from String to String
{
	final forcedPath = "/storage/emulated/0/";
	final packageNameLocal = "me.funkin.corex";
	final fileLocal = "CoreXEngine";

	var EXTERNAL_DATA = "EXTERNAL_DATA";
	var EXTERNAL_OBB = "EXTERNAL_OBB";
	var EXTERNAL_MEDIA = "EXTERNAL_MEDIA";
	var EXTERNAL = "EXTERNAL";

	public static function fromStr(str:String):StorageType
	{
		final EXTERNAL_DATA =
			AndroidContext.getExternalFilesDir();

		final EXTERNAL_OBB =
			AndroidContext.getObbDir();

		final EXTERNAL_MEDIA =
			AndroidEnvironment.getExternalStorageDirectory()
			+ "/Android/media/"
			+ Application.current.meta.get("packageName");

		final EXTERNAL =
			AndroidEnvironment.getExternalStorageDirectory()
			+ "/."
			+ Application.current.meta.get("file");

		return switch (str)
		{
			case "EXTERNAL_DATA":
				EXTERNAL_DATA;

			case "EXTERNAL_OBB":
				EXTERNAL_OBB;

			case "EXTERNAL_MEDIA":
				EXTERNAL_MEDIA;

			case "EXTERNAL":
				EXTERNAL;

			default:
				StorageUtil.getExternalDirectory(str) + "." + fileLocal;
		}
	}

	public static function fromStrForce(str:String):StorageType
	{
		final EXTERNAL_DATA =
			forcedPath
			+ "Android/data/"
			+ packageNameLocal
			+ "/files";

		final EXTERNAL_OBB =
			forcedPath
			+ "Android/obb/"
			+ packageNameLocal;

		final EXTERNAL_MEDIA =
			forcedPath
			+ "Android/media/"
			+ packageNameLocal;

		final EXTERNAL =
			forcedPath
			+ "."
			+ fileLocal;

		return switch (str)
		{
			case "EXTERNAL_DATA":
				EXTERNAL_DATA;

			case "EXTERNAL_OBB":
				EXTERNAL_OBB;

			case "EXTERNAL_MEDIA":
				EXTERNAL_MEDIA;

			case "EXTERNAL":
				EXTERNAL;

			default:
				StorageUtil.getExternalDirectory(str) + "." + fileLocal;
		}
	}
}
#end