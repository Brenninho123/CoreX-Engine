package;

import debug.FPSCounter;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import haxe.io.Path;
import lime.app.Application;
import lime.system.System as LimeSystem;
import mobile.backend.MobileScaleMode;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageQuality;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.system.System;
import states.TitleState;

#if COPYSTATE_ALLOWED
import states.CopyState;
#end

#if DISCORD_ALLOWED
import backend.DiscordClient;
#end

#if linux
import lime.graphics.Image;

@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
#define GAMEMODE_AUTO
')
#end

class Main extends Sprite
{
	public static var instance:Main;
	public static var fpsVar:FPSCounter;

	public static inline var ENGINE_NAME:String = "CoreX Engine";
	public static inline var ENGINE_VERSION:String = "0.3.0";

	#if mobile
	public static final platform:String = "Mobile";
	#else
	public static final platform:String = "Desktop";
	#end

	public var gameSettings:Dynamic = {
		width: 1280,
		height: 720,
		initialState: TitleState,
		zoom: -1.0,
		framerate: 120,
		skipSplash: true,
		startFullscreen: false
	};

	public static function main():Void
	{
		Lib.current.addChild(new Main());

		#if cpp
		cpp.NativeGc.enable(true);
		cpp.NativeGc.run(true);
		cpp.vm.Gc.enable(true);
		#end
	}

	public function new()
	{
		super();

		instance = this;

		#if mobile
		#if android
		StorageUtil.requestPermissions();
		#end

		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end

		backend.CrashHandler.init();

		#if windows
		@:functionCode('
		SetProcessDPIAware();
		DisableProcessWindowsGhosting();
		timeBeginPeriod(1);
		')
		#end

		if (stage != null)
			initialize();
		else
			addEventListener(Event.ADDED_TO_STAGE, initialize);
	}

	function initialize(?event:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, initialize);

		setupStage();
		setupGame();
		setupSignals();
		setupPlatform();
	}

	function setupStage():Void
	{
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.quality = StageQuality.BEST;
		stage.frameRate = gameSettings.framerate;
	}

	function setupGame():Void
	{
		#if (openfl <= "9.2.0")
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (gameSettings.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / gameSettings.width;
			var ratioY:Float = stageHeight / gameSettings.height;

			gameSettings.zoom = Math.min(ratioX, ratioY);

			gameSettings.width = Math.ceil(stageWidth / gameSettings.zoom);
			gameSettings.height = Math.ceil(stageHeight / gameSettings.zoom);
		}
		#else
		if (gameSettings.zoom == -1.0)
			gameSettings.zoom = 1.0;
		#end

		#if LUA_ALLOWED
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call));
		#end

		Controls.instance = new Controls();

		ClientPrefs.loadDefaultKeys();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();
		#end

		addChild(new FlxGame(
			gameSettings.width,
			gameSettings.height,
			#if COPYSTATE_ALLOWED
			!CopyState.checkExistingFiles() ? CopyState :
			#end
			gameSettings.initialState,
			#if (flixel < "5.0.0")
			gameSettings.zoom,
			#end
			gameSettings.framerate,
			gameSettings.framerate,
			gameSettings.skipSplash,
			gameSettings.startFullscreen
		));

		setupFPS();
	}

	function setupFPS():Void
	{
		fpsVar = new FPSCounter(12, 6, 0xFFFFFFFF);
		addChild(fpsVar);

		if (fpsVar != null)
			fpsVar.visible = ClientPrefs.data.showFPS;
	}

	function setupPlatform():Void
	{
		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if desktop
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if mobile
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		FlxG.scaleMode = new MobileScaleMode();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end
	}

	function setupSignals():Void
	{
		FlxG.signals.gameResized.add(onResize);

		Application.current.window.onFocusIn.add(function()
		{
			FlxG.drawFramerate = gameSettings.framerate;
			FlxG.updateFramerate = gameSettings.framerate;
		});

		Application.current.window.onFocusOut.add(function()
		{
			FlxG.drawFramerate = 60;
			FlxG.updateFramerate = 60;
		});
	}

	function onResize(width:Int, height:Int):Void
	{
		if (fpsVar != null)
		{
			fpsVar.positionFPS(
				12,
				6,
				Math.min(
					Lib.current.stage.stageWidth / FlxG.width,
					Lib.current.stage.stageHeight / FlxG.height
				)
			);
		}

		if (FlxG.cameras != null)
		{
			for (camera in FlxG.cameras.list)
			{
				if (camera != null && camera.filters != null)
					resetSpriteCache(camera.flashSprite);
			}
		}

		if (FlxG.game != null)
			resetSpriteCache(FlxG.game);

		System.gc();
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	function onKeyUp(event:KeyboardEvent):Void
	{
		if (Controls.instance.justReleased('fullscreen'))
			FlxG.fullscreen = !FlxG.fullscreen;

		if (Controls.instance.justReleased('debug_1'))
			fpsVar.visible = !fpsVar.visible;
	}
}