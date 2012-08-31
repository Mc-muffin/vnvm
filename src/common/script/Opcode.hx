package common.script;

/**
 * ...
 * @author 
 */

class Opcode {
	public var opcodeId:Int;
	public var methodName:String;
	public var format:String;
	public var description:String;
	public var unimplemented:Bool;
	
	public function new(methodName:String, opcodeId:Int, format:String, description:String, unimplemented:Bool) {
		this.methodName = methodName;
		this.opcodeId = opcodeId;
		this.format = format;
		this.description = description;
		this.unimplemented = unimplemented;
	}
	
	public function toString():String {
		return Std.format("Opcode(id=$opcodeId, name='$methodName', format='$format', description='$description', unimplemented=$unimplemented)");
	}
}