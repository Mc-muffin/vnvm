package engines.brave.sprites;
import reflash.display2.View;
import common.display.SpriteUtils;
import engines.brave.sprites.map.MapSprite;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;

/**
 * ...
 * @author 
 */

class GameSprite extends View
{
	public var mapSprite:MapSprite;
	public var background:Sprite;
	public var backgroundBack:Sprite;
	public var backgroundFront:Sprite;
	public var ui:UISprite;

	public function new() 
	{
		super();
		
		//BraveAssets.getBitmapData("PG_MAIN");
		
		addChild(mapSprite = new MapSprite(this));
		addChild(background = new Sprite());
		background.addChild(backgroundBack = new Sprite());
		background.addChild(backgroundFront = new Sprite());
		addChild(ui = new UISprite());
		
		backgroundBack.addChild(SpriteUtils.createSolidRect(0x000000));
		backgroundFront.addChild(SpriteUtils.createSolidRect(0x000000));
	}
}