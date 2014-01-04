package engines.dividead;

import common.tween.Tween;
import common.PromiseUtils;
import common.IteratorUtilities;
import common.script.Instruction2;
import engines.dividead.script.AB_OP;
import promhx.Promise;
import common.ByteArrayUtils;
import common.GraphicUtils;
import common.MathEx;
import common.script.Opcode;
import haxe.Timer;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

class AB
{
	public var scriptName:String;
	public var abOp:AB_OP;
	public var game:Game;
	private var script:ByteArray = null;
	private var running:Bool;
	public var throttle:Bool;
	
	public function new(game:Game)
	{
		this.game = game;
		this.script = null;
		this.abOp = new AB_OP(this);
		this.running = true;
	}
	
	public function loadScriptAsync(scriptName:String, scriptPos:Int = 0):Promise<Bool>
	{
		return game.sg.openAndReadAllAsync('${scriptName}.ab').then(function(script:ByteArray):Bool {
			this.scriptName = scriptName;
			this.script = script;
			this.script.position = scriptPos;
			return true;
		});
	}
	
	private function parseParam(type:String):Dynamic {
		switch (type) {
			case 'F': return Std.int(MathEx.clamp(script.readShort(), 0, 999));
			case '2': return script.readShort();
			case 'T', 'S', 's': return ByteArrayUtils.readStringz(script);
			case 'P': return script.readUnsignedInt();
			case 'c': return script.readUnsignedByte();
			default: throw('Invalid format type \'$type\'');
		}
	}
		
	private function parseParams(format:String):Array<Dynamic>
	{
		var params:Array<Dynamic> = [];
		for (n in 0 ... format.length) {
			var type:String = format.charAt(n);
			params.push(parseParam(type));
		}
		//Log.trace("Params: " + params);
		return params;
	}
	
	private function executeSingleAsync():Promise<Dynamic>
	{
		var opcodePosition = this.script.position;
		var opcodeId = this.script.readUnsignedShort();
		var opcode = game.scriptOpcodes.getOpcodeWithId(opcodeId);
		
		var params:Array<Dynamic> = parseParams(opcode.format);
		var instruction = new Instruction2(scriptName, opcode, params, opcodePosition, this.script.position - opcodePosition);
		var result = instruction.call(this.abOp);

		return PromiseUtils.returnPromiseOrResolvedPromise(result);
	}
	
	private function hasMore():Bool {
		return this.script.position < this.script.length;
	}

	/*
	public function execute():Void
	{
		while (running && hasMore())
		{
			if (executeSingleAsync(execute)) return;
		}
	}
	*/

	public function executeAsync(?e):Promise<Dynamic>
	{
		var promise = new Promise<Dynamic>();
		function executeStep() {
			executeSingleAsync().then(function(?e) {
				executeStep();
			});
		}
		executeStep();
		return promise;
	}
	
	/*
	function getNameExt(name, ext) {
		return (split(name, ".")[0] + "." + ext).toupper();
	}
	*/
	
	public function jump(offset:Int)
	{
		this.script.position = offset;
	}
	
	public function end()
	{
		this.running = false;
	}
	
	public function paintToColorAsync(color:Array<Int>, time:Float):Promise<Dynamic>
	{
		var sprite:Sprite = new Sprite();
		GraphicUtils.drawSolidFilledRectWithBounds(sprite.graphics, 0, 0, 640, 480, 0x000000, 1.0);

		return Tween.forTime(time).onStep(function(step:Float) {
			game.front.copyPixels(game.back, game.back.rect, new Point(0, 0));
			game.front.draw(sprite, null, new ColorTransform(1, 1, 1, step, 0, 0, 0, 0));
		}).animateAsync();
	}
	
	public function paintAsync(pos:Int, type:Int):Promise<Dynamic>
	{
		var allRects:Array<Array<Rectangle>> = [];
		var promise = new Promise<Dynamic>();
		
		if ((type == 0) || game.isSkipping()) {
			game.front.copyPixels(game.back, new Rectangle(0, 0, 640, 480), new Point(0, 0));
			Timer.delay(function() {
				promise.resolve(null);
			}, 4);
			return promise;
		}

		function addFlipSet(action:Array<Rectangle> -> Void):Void {
			var rects:Array<Rectangle> = [];
			action(rects);
			allRects.push(rects);
		}
		
		switch (type) {
			case 4: // Rows
			{
				var block_size:Int = 16;
				for (n in 0 ... block_size) {
					addFlipSet(function(rects:Array<Rectangle>) { 
						for (x in IteratorUtilities.xrange(0, 640, block_size)) {
							rects.push(new Rectangle(x + n, 0, 1, 480));
						}
					});
				}
			}
			case 2: { // Columns
				var block_size:Int = 16;
				for (n in 0 ... block_size) {
					addFlipSet(function(rects:Array<Rectangle>) { 
						for (y in IteratorUtilities.xrange(0, 480, block_size)) {
							rects.push(new Rectangle(0, y + n, 640, 1));
						}
					});
				}
			}
			case 3: { // Courtine
				for (y in IteratorUtilities.xrange(0, 480, 4)) {
					addFlipSet(function(rects:Array<Rectangle>) { 
						rects.push(new Rectangle(0, y, 640, 2));
						rects.push(new Rectangle(0, 480 - 2 - y, 640, 2));
					});
				}
			}
			default:
				addFlipSet(function(rects:Array<Rectangle>) { rects.push(new Rectangle(0, 0, 640, 480)); } );
		}
		
		var step = null;
		
		var frameTime:Int = MathEx.int_div(300, allRects.length);
		
		step = function() {
			if (allRects.length > 0) {
				var rectangles:Array<Rectangle> = allRects.shift();
				
				game.front.lock();
				for (rectangle in rectangles) {
					/*
					var pixels:ByteArray = game.back.getPixels(rectangle);
					pixels.position = 0;
					game.front.setPixels(rectangle, pixels);
					*/
					//Log.trace(Std.format("(${rectangle.x},${rectangle.y})-(${rectangle.width},${rectangle.height})"));
					game.front.copyPixels(game.back, rectangle, rectangle.topLeft);
				}
				game.front.unlock();
				
				Timer.delay(step, frameTime);
			} else {
				promise.resolve(null);
			}
		};
		
		step();

		return promise;
	}
}
