package engines.brave.sprites;
import common.Animation;
import common.SpriteUtils;
import common.StringEx;
import engines.brave.BraveAssets;
import haxe.Log;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;

/**
 * ...
 * @author 
 */

class TextSprite extends Sprite
{
	var picture:Sprite;
	var textContainer:Sprite;
	var textBackground:Sprite;
	var titleTextField:TextField;
	var textTextField:TextField;
	var padding:Int = 16;
	var boxWidth:Int = 600;
	var boxHeight:Int = 100;
	var animateText:Bool = false;

	public function new() 
	{
		super();
		
		textContainer = new Sprite();
		textBackground = new Sprite();
		textTextField = new TextField();
		picture = new Sprite();
		picture.x = -30;
		picture.y = 480;
		
		textTextField.defaultTextFormat = new TextFormat("Lucida Console", 16, 0xFFFFFF);
		textTextField.selectable = false;
		textTextField.multiline = true;
		textTextField.text = "";
		
		setTextSize(false);
		
		//textField.textColor = 0xFFFFFF;
		
		this.alpha = 0;

		textContainer.addChild(textBackground);
		textContainer.addChild(textTextField);

		addChild(picture);
		addChild(textContainer);
	}
	
	private function setTextSize(withFace:Bool):Void {
		var faceWidth:Int = withFace ? 155 : 0;
		
		SpriteUtils.extractSpriteChilds(textBackground);
		textBackground.addChild(SpriteUtils.createSolidRect(0x000000, 0.5, boxWidth - faceWidth, boxHeight));
		
		textContainer.x = 640 / 2 - boxWidth / 2 + faceWidth;
		textContainer.y = 480 - boxHeight - 20;

		textTextField.width = boxWidth - padding * 2 - faceWidth;
		textTextField.height = boxHeight - padding * 2;
		textTextField.x = padding;
		textTextField.y = padding;
	}
	
	private function _setText(text:String):Void
	{
		textTextField.text = text;
	}
	
	private function setText(faceId:Int, title:String, text:String, done:Void -> Void):Void {
		if (animateText) 
		{
			var obj:Dynamic = { showChars : 0 };
			var time:Float = text.length * 0.01;
			Animation.animate(done, time, obj, { showChars : text.length } , Animation.Linear, function(step:Float) {
				_setText(text.substr(0, Std.int(obj.showChars)));
			} );
		}
		else
		{
			_setText(textTextField.text);
			done();
		}
	}

	public function _setTextAndEnable(faceId:Int, title:String, text:String, done:Void -> Void):Void {
		enable(function() {
			setText(faceId, title, text, done);
		});
	}

	public function setTextAndEnable(faceId:Int, title:String, text:String, done:Void -> Void):Void {
		SpriteUtils.extractSpriteChilds(picture);
		setTextSize(faceId >= -1);
		if (faceId >= 0) {
			BraveAssets.getBitmapDataWithAlphaCombinedAsync(StringEx.sprintf("Z_%02d_%02d", [Std.int(faceId / 100), Std.int(faceId % 100)])).then(function(bitmapData:BitmapData) {
				var bmp:Bitmap = SpriteUtils.center(new Bitmap(bitmapData, PixelSnapping.AUTO, true), 0, 1);
				picture.addChild(bmp);
				_setTextAndEnable(faceId, title, text, done);
			});
		} else {
			_setTextAndEnable(faceId, title, text, done);
		}
	}

	public function enable(done:Void -> Void):Void {
		if (alpha != 1) {
			Animation.animate(done, 0.3, this, { alpha : 1 } );
		} else {
			done();
		}
	}
	
	public function endText():Void {
		textTextField.text = "";
	}

	public function disable(done:Void -> Void):Void {
		var done2 = function() {
			endText();
			done();
		};
		if (alpha != 0) {
			Animation.animate(done2, 0.1, this, { alpha : 0 } );
		} else {
			done2();
		}
	}
}