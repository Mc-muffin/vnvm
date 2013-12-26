package common.imaging;
import common.ByteArrayUtils;
import haxe.Log;
import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.Memory;
import flash.utils.ByteArray;
import flash.utils.Endian;
//import sys.io.File;

/**
 * ...
 * @author soywiz
 */

class BMP
{
	static public function decode(bytes:ByteArray):BitmapData
	{
		bytes.endian = Endian.LITTLE_ENDIAN;

		//File.saveBytes("c:/temp/temp.bmp", bytes);

		// BITMAPFILEHEADER
		var magic:String = bytes.readUTFBytes(2);
		var bmpSize:Int = bytes.readUnsignedInt();
		var reserved1:Int = bytes.readUnsignedShort();
		var reserved2:Int = bytes.readUnsignedShort();
		var dataOffset:Int = bytes.readUnsignedInt();
		if (magic != "BM") throw(new Error('Not a BMP'));

		// BITMAPINFOHEADER
		var biSize:Int = bytes.readUnsignedInt();
		if (biSize != 40) throw(new Error('Invalid BITMAPINFOHEADER $biSize'));
		var biData:ByteArray = new ByteArray();
		bytes.readBytes(biData, 0, biSize - 4);
		biData.endian = Endian.LITTLE_ENDIAN;
		biData.position = 0;
		var width:Int = biData.readUnsignedInt();
		var height:Int = biData.readUnsignedInt();
		var planes:Int = biData.readUnsignedShort();
		var bitCount:Int = biData.readUnsignedShort();
		var compression:Int = biData.readUnsignedInt();
		if (compression != 0) throw(new Error('Not supported compression $compression'));
		var sizeImage:Int = biData.readUnsignedInt();
		var pixelsPerMeterX:Int = biData.readUnsignedInt();
		var pixelsPerMeterY:Int = biData.readUnsignedInt();
		var colorsUsed:Int = biData.readUnsignedInt();
		var colorImportant:Int = biData.readUnsignedInt();

		var palette:Array<BmpColor> = new Array<BmpColor>();

		if (bitCount == 8) {
			if (colorsUsed == 0) colorsUsed = 0x100;
			// RGBQUAD - Palette
			//for (n in 0 ... colorsUsed) {
			for (n in 0 ... colorsUsed) {
				var b:Int = bytes.readUnsignedByte();
				var g:Int = bytes.readUnsignedByte();
				var r:Int = bytes.readUnsignedByte();
				var reserved:Int = bytes.readUnsignedByte();
				palette.push(new BmpColor(r, g, b, 0xFF));
			}
		}

		// LINES
		var calculatedSizeImage:Int = width * height * planes * Std.int(bitCount / 8);
		//if (calculatedSizeImage != sizeImage) throw(new Error("Invalid sizeImage"));
		//var pixelData:ByteArray = bytes.readBytes(pixelSize);

		bytes.position = dataOffset;
		var bitmapData:BitmapData = new BitmapData(width, height);

		switch (bitCount) {
			case 8: decodeRows8(bytes, bitmapData, palette);
			case 24: decodeRows24(bytes, bitmapData);
			default: throw(new Error('Not implemented bitCount=$bitCount'));
		}

		return bitmapData;
	}

	@:noStack static private function decodeRows8(bytes:ByteArray, bitmapData:BitmapData, palette:Array<BmpColor>):Void {
		var width:Int = bitmapData.width, height:Int = bitmapData.height;

		var bmpData:ByteArray = ByteArrayUtils.newByteArrayWithLength(width * height * 4, Endian.LITTLE_ENDIAN);
		var paletteInt:Array<Int> = [];
		var stride:Int = width * 4;

		for (n in 0 ... palette.length) paletteInt.push(palette[n].getPixel32());

		Memory.select(bmpData);
		for (y in 0 ... height) {
			var n:Int = (height - y - 1) * stride;
			for (x in 0 ... width) {
				var index:Int = bytes.readUnsignedByte();
				//Log.trace(Std.format("INDEX: $index, ${palette.length}"));
				Memory.setI32(n, paletteInt[index]);
				n += 4;
			}
		}
		bitmapData.setPixels(new Rectangle(0, 0, width, height), bmpData);
		Memory.select(null);

		// Free memory
		ByteArrayUtils.freeByteArray(bmpData);
	}

	@:noStack static private function decodeRows24(bytes:ByteArray, bitmapData:BitmapData):Void {
		var width:Int = bitmapData.width, height:Int = bitmapData.height;

		var bmpData:ByteArray = new ByteArray();
		for (y in 0 ... height) {
			bmpData.position = 0;
			for (x in 0 ... width) {
				var r:Int = bytes.readUnsignedByte();
				var g:Int = bytes.readUnsignedByte();
				var b:Int = bytes.readUnsignedByte();
				var a:Int = 0xFF;
				bmpData.writeByte(a);
				bmpData.writeByte(b);
				bmpData.writeByte(g);
				bmpData.writeByte(r);
			}
			bmpData.position = 0;
			bitmapData.setPixels(new Rectangle(0, height - y - 1, width, 1), bmpData);
		}
	}
}