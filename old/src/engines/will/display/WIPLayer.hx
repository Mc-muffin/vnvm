package engines.will.display;

import haxe.Log;
import reflash.display.DisplayObject2;
import reflash.gl.wgl.WGLTexture;
import reflash.display.Image2;
import engines.will.formats.wip.WIP;
import reflash.display.Sprite2;

class WIPLayer extends Sprite2
{
	private var wip:WIP;

	private var layers:Array<DisplayObject2>;
	private var layersEnabled:Array<Bool>;

	private function new(wip:WIP)
	{
		super();

		this.removeChildren();

		this.wip = wip;
		this.layers = [];
		this.layersEnabled = [];

		this.width = this.wip.width;
		this.height = this.wip.height;

		for (index in 0 ... wip.length)
		{
			var wipEntry = wip.get(index);
			var image = new Image2(WGLTexture.fromBitmapData(wipEntry.bitmapData));
			image.setPosition(wipEntry.x, wipEntry.y).setZIndex(index);
			image.setAnchorAdjustingPosition(0.5, 0.5);
			image.visible = (index == 0);
			//image.visible = true;
			this.addChild(image);
			this.layersEnabled.push(false);
			this.layers.push(image);
		}
	}

	public function getLayer(layerId:Int):DisplayObject2
	{
		if (!isValidLayerId(layerId)) throw('Invalid layer id');
		return this.layers[layerId];
	}

	private function isValidLayerId(layerId:Int):Bool
	{
		return (layerId >= 0) && (layerId < this.layersEnabled.length);
	}

	public function isLayerEnabled(layerId:Int):Bool
	{
		if (!isValidLayerId(layerId)) return false;
		return this.layersEnabled[layerId];
	}

	public function setLayerEnabled(layerId:Int, enabled:Bool)
	{
		if (!isValidLayerId(layerId)) return;
		this.layersEnabled[layerId] = enabled;
	}

	public function setLayerVisibility(layerId:Int, visible:Bool)
	{
		if (!isValidLayerId(layerId)) return;
		this.layers[layerId].visible = visible;
	}

	static public function fromWIP(wip:WIP):WIPLayer
	{
		return new WIPLayer(wip);
	}
}
