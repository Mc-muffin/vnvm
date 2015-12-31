package com.vnvm.common.view

import com.vnvm.common.TimeSpan
import com.vnvm.common.async.EventLoop
import com.vnvm.common.async.Promise
import com.vnvm.common.async.Signal
import com.vnvm.common.clamp
import com.vnvm.common.clamp01
import com.vnvm.common.error.noImpl
import com.vnvm.common.image.BitmapData
import com.vnvm.graphics.*

interface Updatable {
	fun update(dt: Int): Unit
}

class Views(val graphics: GraphicsContext, val input: InputContext, val window: WindowContext) : Updatable {
	public val root = Sprite()
	val usedBitmapDatas = hashSetOf<BitmapData>()
	val lastFrameBitmapDatas = hashSetOf<BitmapData>()

	var frames = 0

	fun render(context: RenderContext) {
		if (frames++ == 0) {
			usedBitmapDatas.clear()
		}
		context.begin()
		root.render(this, context)
		context.end()
		lastFrameBitmapDatas.addAll(usedBitmapDatas)
		if (frames >= 60) {
			frames = 0
			val texturesToRemove = lastFrameBitmapDatas.subtract(usedBitmapDatas)
			if (texturesToRemove.isNotEmpty()) {
				println("textures to remove!")
				for (tex in texturesToRemove) {
					tex.texture?.texture?.dispose()
					tex.texture = null
				}
				lastFrameBitmapDatas.clear()
			}
		}
		input.onEvent.add { root.onEvent(it) }
	}

	private var lastTime: Long = System.currentTimeMillis()
	fun frame() {
		val currentTime = System.currentTimeMillis()
		val elapsed = (currentTime - lastTime).toInt()
		val elapsedNormalized = elapsed.clamp(0, 40)
		update(elapsedNormalized)
		EventLoop.frame()
		lastTime = currentTime
	}

	override fun update(dt: Int) {
		root.update(dt)
	}
}

class UpdatableGroup : Updatable {
	private val items = arrayListOf<Updatable>()

	fun add(updatable: Updatable) {
		items.add(updatable)
	}

	fun remove(updatable: Updatable) {
		items.remove(updatable)
	}

	override fun update(dt: Int) {
		for (n in 0 until items.size) items[n].update(dt)
	}
}


class Timers : Updatable {
	private val group = UpdatableGroup()


	override fun update(dt: Int) {
		group.update(dt)
	}

	fun waitAsync(time: TimeSpan): Promise<Unit> {
		val deferred = Promise.Deferred<Unit>()
		val totalTime = time.milliseconds
		var item: Updatable? = null
		item = object : Updatable {
			var elapsedTime = 0
			override fun update(dt: Int) {
				elapsedTime += dt
				if (elapsedTime >= totalTime) {
					group.remove(item!!)
					deferred.resolve(Unit)
				}
			}
		}
		group.add(item)
		return deferred.promise
	}
}

class Tweens : Updatable {
	private val group = UpdatableGroup()

	override fun update(dt: Int) {
		group.update(dt)
	}

	fun animateAsync(time: TimeSpan, step: (ratio: Double) -> Unit): Promise<Unit> {
		val deferred = Promise.Deferred<Unit>()
		val totalTime = time.milliseconds
		var item: Updatable? = null
		step(0.0)
		item = object : Updatable {
			var elapsedTime = 0
			override fun update(dt: Int) {
				elapsedTime += dt
				val ratio = (elapsedTime.toDouble() / totalTime.toDouble()).clamp01()
				step(ratio)
				if (ratio >= 1.0) {
					group.remove(item!!)
					deferred.resolve(Unit)
				}
			}
		}
		group.add(item)
		return deferred.promise
	}
}

class Mice {
	val onMouseClick = Signal<MouseClickEvent>()

	fun onEvent(event: MouseEvent) {
		when (event) {
			is MouseClickEvent -> onMouseClick.dispatch(event)
		}
	}
}

class KeyHandler {
	val onKeyDown = Signal<KeyDownEvent>()
	val onKeyPress = Signal<KeyPressEvent>()
	val onKeyUp = Signal<KeyUpEvent>()

	fun onEvent(event: KeyEvent) {
		when (event) {
			is KeyDownEvent -> onKeyDown.dispatch(event)
			is KeyPressEvent -> onKeyPress.dispatch(event)
			is KeyUpEvent -> onKeyUp.dispatch(event)
		}
	}
}

open class DisplayObject {
	var x: Double = 0.0
	var y: Double = 0.0
	var alpha: Double = 1.0
	var speed: Double = 1.0
	var scaleX: Double = 1.0
	var scaleY: Double = 1.0
	var rotation: Double = 0.0
	private var updatables = arrayListOf<Updatable>()
	val timers: Timers by lazy { addUpdatable(Timers()) }
	val tweens: Tweens by lazy { addUpdatable(Tweens()) }
	val mice: Mice by lazy { Mice() }
	val keys: KeyHandler by lazy { KeyHandler() }

	fun <T : Updatable> addUpdatable(updatable: T): T {
		updatables.add(updatable)
		return updatable
	}

	fun addUpdatable(updatable: (dt: Int) -> Unit) = addUpdatable(object : Updatable {
		override fun update(dt: Int) = updatable(dt)
	})

	fun update(dt: Int): Unit {
		val dt = (dt * speed).toInt()
		updateInternal(dt)
		for (n in 0 until updatables.size) updatables[n].update(dt)
	}

	fun render(views: Views, context: RenderContext): Unit {
		context.save()
		context.translate(x, y)
		context.scale(scaleX, scaleY)
		context.rotate(rotation)
		renderInternal(views, context)
		context.restore()
	}

	open fun renderInternal(views: Views, context: RenderContext): Unit {
	}

	open protected fun updateInternal(dt: Int) {
	}

	open fun onEvent(event: Event) {
		if (event is MouseEvent) mice.onEvent(event)
		if (event is KeyEvent) keys.onEvent(event)
	}
}

open class Sprite : DisplayObject() {
	private val children = arrayListOf<DisplayObject>()

	fun addChild(child: DisplayObject): Unit {
		children.add(child)
	}

	fun removeChildren(): Unit {
		children.clear()
	}

	override fun renderInternal(views: Views, context: RenderContext): Unit {
		for (n in 0 until children.size) children[n].render(views, context)
	}

	override protected fun updateInternal(dt: Int) {
		for (n in 0 until children.size) children[n].update(dt)
	}

	override fun onEvent(event: Event) {
		super.onEvent(event)
		for (n in 0 until children.size) children[n].onEvent(event)
	}
}

enum class PixelSnapping { AUTO }

class Bitmap(val data: BitmapData, val snapping: PixelSnapping = PixelSnapping.AUTO, val smooth: Boolean = true) : DisplayObject() {
	var width = data.width
	var height = data.height

	override fun renderInternal(views: Views, context: RenderContext) {
		views.usedBitmapDatas.add(data)
		if (data.texture == null) {
			data.texture = context.createTexture(data)
		}
		context.quad(data.texture!!, width.toDouble(), height.toDouble())
	}
}

class SolidColor(val color: Int) : DisplayObject() {
	var width: Int = 100
	var height: Int = 100
}

open class TextField : DisplayObject() {
	var defaultTextFormat: TextFormat = TextFormat("Arial", 10, -1)
	var width: Double = 100.0
	var height: Double = 100.0
	var text: String = ""
	var selectable: Boolean = false
	var textColor: Int = -1

	override fun renderInternal(views: Views, context: RenderContext) {
		context.text(text)
	}
}

enum class Keys(val value: Int) {
	Backspace(8), Tab(9), Enter(13), Shift(16), Control(17), CapsLock(20), Esc(27),
	Spacebar(32), PageUp(33), PageDown(34), End(35), Home(36),
	Left(37), Up(38), Right(39), Down(40),
	Insert(45), Delete(46), NumLock(144), ScrLk(145), Pause_Break(19),

	A(65), B(66), C(67), D(68), E(69), F(70), G(71), H(72), I(73), J(74),
	K(75), L(76), M(77), N(78), O(79), P(80), Q(81), R(82), S(83), T(84),
	U(85), V(86), W(87), X(88), Y(89), Z(90),

	_0(48), _1(49), _2(50), _3(51), _4(52), _5(53), _6(54), _7(55), _8(56), _9(57),

	F1(112), F2(113), F3(114), F4(115), F5(116), F6(117), F7(118),
	F8(119), F9(120), F10(121), F11(122), F12(123), F13(124), F14(125), F15(126),

	Numpad0(96), Numpad1(97), Numpad2(98), Numpad3(99), Numpad4(100),
	Numpad5(101), Numpad6(102), Numpad7(103), Numpad8(104), Numpad9(105),
	NumpadMultiply(106), NumpadAdd(107), NumpadEnter(13), NumpadSubtract(109), NumpadDecimal(110), NumpadDivide(111),

	SemicolonDoubleColon(186), EqualPlus(187), MinusUnderscore(189), SlashQuestionMark(191), Comma(188),
	Dot(190), Slash(191), OpenBrackets(219), VerticalBar(220), CloseBrackets(221), DquoteQuote(222), Capo(192)
}

object GameInput {
	val onClick: Signal<Unit> get() = noImpl
	val onKeyPress: Signal<Keys> get() = noImpl

	fun isPressing(key: Keys): Boolean = noImpl
}

data class TextFormat(val face: String, val size: Int, val color: Int) {

}

/*
class GameInput
{
	static var pressing:Map<Int,Void>;
	static var lastPressing:Map<Int,Void>;

	private function new()
	{
	}

	static public var onClick:Signal<MouseEvent>;
	static public var onMouseMoveEvent:Signal<MouseEvent>;
	static public var onKeyPress:Signal<KeyboardEvent>;
	static public var onKeyRelease:Signal<KeyboardEvent>;
	static public var onKeyPressing:Signal<KeyboardEvent>;

	static public function init() {
	pressing = new Map<Int,Void>();
	lastPressing = new Map<Int,Void>();
	StageReference.stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
		setKey(e.keyCode, true);
	});
	StageReference.stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent) {
		setKey(e.keyCode, false);
	});
	StageReference.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	StageReference.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	StageReference.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
	StageReference.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	StageReference.stage.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
		onClick.dispatch(e);
	});
	StageReference.stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
		//onClick.trigger(e);
	});

	mouseCurrent = new Point(-1, -1);
	mouseCurrentClick = new Point( -1, -1);
	mouseStart = new Point(-1, -1);
	onClick = new Signal<MouseEvent>();
	onMouseMoveEvent = new Signal<MouseEvent>();
	onKeyPress = new Signal<KeyboardEvent>();
	onKeyRelease = new Signal<KeyboardEvent>();
	onKeyPressing = new Signal<KeyboardEvent>();
}

	static public function onEnterFrame(e:Event):Void {
	for (key in lastPressing.keys()) {
		if (pressing.exists(key)) {
		} else {
			lastPressing.remove(key);
			onKeyRelease.dispatch(new KeyboardEvent("onRelease", true, false, 0, key));
		}
	}
	for (key in pressing.keys()) {
		if (lastPressing.exists(key)) {
			onKeyPressing.dispatch(new KeyboardEvent("onPressing", true, false, 0, key));
		} else {
			lastPressing.set(key, null);
			onKeyPress.dispatch(new KeyboardEvent("onPress", true, false, 0, key));
		}
	}
}

	static public function isPressing(keyCode:Int):Bool {
	return pressing.exists(keyCode);
}

	static private function setKey(key:Int, set:Bool):Void {
	if (set) {
		pressing.set(key, null);
	} else {
		pressing.remove(key);
	}
}

	static public var mouseCurrent:Point;
	static public var mouseCurrentClick:Point;
	static public var mouseStart:Point;

	static private function onMouseDown(e:MouseEvent):Void {
	if (e.buttonDown) {
		//Log.trace(Std.format("onMouseDown : ${e.stageX}, ${e.stageY}"));
		mouseStart = new Point(e.stageX, e.stageY);
		//e.stageX
	}
}

	static private function onMouseUp(e:MouseEvent):Void {
	//Log.trace(Std.format("onMouseUp : ${e.stageX}, ${e.stageY}"));
	setKey(Keys.Left, false);
	setKey(Keys.Right, false);
	setKey(Keys.Up, false);
	setKey(Keys.Down, false);
}

	static private inline var deltaThresold:Int = 40;

	static private function onMouseMove(e:MouseEvent):Void {
	mouseCurrent = new Point(e.stageX, e.stageY);
	if (e.buttonDown) {
		//Log.trace(Std.format("onMouseMove : ${e.stageX}, ${e.stageY}"));
		mouseCurrentClick = new Point(e.stageX, e.stageY);
		var offset:Point = mouseCurrentClick.subtract(mouseStart);

		//Log.trace(Std.format("--> ${offset.x}, ${offset.y}"));

		setKey(Keys.Left, (offset.x < -deltaThresold));
		setKey(Keys.Right, (offset.x > deltaThresold));
		setKey(Keys.Up, (offset.y < -deltaThresold));
		setKey(Keys.Down, (offset.y > deltaThresold));
	}

	onMouseMoveEvent.dispatch(e);
}
}
*/