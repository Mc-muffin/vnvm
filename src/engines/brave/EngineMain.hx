package engines.brave;

import common.GraphicUtils;
import engines.brave.BraveAssets;
import engines.brave.formats.BraveImage;
import common.GameInput;
import engines.brave.GameState;
import engines.brave.map.Map;
import engines.brave.script.Script;
import engines.brave.script.ScriptReader;
import engines.brave.script.ScriptThread;
import engines.brave.sound.SoundPack;
import engines.brave.sprites.GameSprite;
import engines.brave.sprites.map.Character;
import engines.brave.sprites.map.MapSprite;
import haxe.Timer;
import nme.geom.Rectangle;
import nme.media.Sound;
import nme.media.SoundChannel;
import nme.media.SoundLoaderContext;
import haxe.Log;
import nme.Assets;
import nme.display.Stage;
import nme.display.Bitmap;
import nme.display.PixelSnapping;
import nme.display.Sprite;
import nme.events.Event;
import nme.Lib;
import nme.media.SoundTransform;

/**
 * ...
 * @author soywiz
 */

class EngineMain extends Sprite 
{
	
	public function new() 
	{
		super();
		
		Lib.current.stage.addEventListener(Event.RESIZE, resize);
		init0(null);
	}

	private function resize(e) 
	{
		var propX = stage.stageWidth / 640;
		var propY = stage.stageHeight / 480;
		var usedWidth, usedHeight;
		
		if (propX < propY) {
			gameSprite.scaleY = gameSprite.scaleX = propX;
		} else {
			gameSprite.scaleY = gameSprite.scaleX = propY;
		}
		
		usedWidth = 640 * gameSprite.scaleX;
		usedHeight = 480 * gameSprite.scaleY;

		gameSprite.x = Std.int((stage.stageWidth - usedWidth) / 2);
		gameSprite.y = Std.int((stage.stageHeight - usedHeight) / 2);
		
		gameSpriteRectangle = new Rectangle(gameSprite.x, gameSprite.y, usedWidth, usedHeight);
		
		{
			blackBorder.graphics.clear();
			GraphicUtils.drawSolidFilledRectWithBounds(blackBorder.graphics, 0, 0, gameSpriteRectangle.left, stage.stageHeight);
			GraphicUtils.drawSolidFilledRectWithBounds(blackBorder.graphics, gameSpriteRectangle.right, 0, stage.stageWidth, stage.stageHeight);

			GraphicUtils.drawSolidFilledRectWithBounds(blackBorder.graphics, 0, 0, stage.stageWidth, gameSpriteRectangle.top);
			GraphicUtils.drawSolidFilledRectWithBounds(blackBorder.graphics, 0, gameSpriteRectangle.bottom, stage.stageWidth, stage.stageHeight);

			//GraphicUtils.drawSolidFilledRect(blackBorder.graphics, 0, -this.y, 640, this.y / scaleY);
			//GraphicUtils.drawSolidFilledRect(blackBorder.graphics, 0, 480, 640, this.y / scaleY);
		}
	}
	
	var gameSpriteRectangle:Rectangle;
	var gameSprite:GameSprite;
	var blackBorder:Sprite;
	
	var initialized:Bool = false;
	
	private function init0(e) {
		if (!initialized) {
			gameSprite = new GameSprite();
			blackBorder = new Sprite();
			addChild(gameSprite);
			addChild(blackBorder);

		}
		resize(e);
		if (!initialized) {
			initialized = true;
			init(e);
		}
	}
	
	private function init(e) 
	{
		resize(e);

#if flash
		Log.setColor(0xFF0000);
#end
		
		/*
		var faceId = 57;
		BraveLog.trace(StringEx.sprintf("Z_%02d_%02d", [Std.int(faceId / 100), Std.int(faceId % 100)]));
		*/
		
		//new ScriptReader(Script.getScriptWithName("op")).readAllInstructions();
		
		if (false) {
			Map.loadFromNameAsync("a_wood0", function(woods:Map):Void {
				var mapSprite:MapSprite = new MapSprite();
				addChild(mapSprite);
				mapSprite.setMap(woods);
				var character:Character = new Character(mapSprite, 0, "C_RUDY", 20 * 40, 71 * 40);
				character.loadImageAsync(function() {
					mapSprite.addCharacter(character);
				});
			});
		} else {
			var startScriptName:String = "start";
			//var startScriptName:String = "op";
			//var startScriptName:String = "op_2";
			//var startScriptName:String = "a_bar";
			//var startScriptName:String = "end_3";
			//var startScriptName:String = "e_m20";
			//var startScriptName:String = "e_k99";
			//var startScriptName:String = "e_m99";
			var gameState:GameState = new GameState(gameSprite);
			Script.getScriptWithNameAsync(startScriptName, function(script:Script) {
				var scriptThread:ScriptThread = gameState.spawnThreadWithScript(script);
				scriptThread.execute();
			});
		}
	}

	/*
	static public function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
		stage.align = nme.display.StageAlign.TOP_LEFT;
		
		Lib.current.addChild(new Main());
	}
	*/
}
