package common.script;
import haxe.rtti.Meta;
import nme.errors.Error;

/**
 * ...
 * @author 
 */

class ScriptOpcodes 
{
	private var opcodesById:IntHash<Opcode>;
	
	public function new():Void
	{
		opcodesById = new IntHash<Opcode>();
	}
	
	static public function createWithClass(opcodesClass:Class<Dynamic>):ScriptOpcodes {
		var scriptOpcodes:ScriptOpcodes = new ScriptOpcodes();
		scriptOpcodes.initializeOpcodesById(opcodesClass);
		return scriptOpcodes;
	}
	
	private function initializeOpcodesById(opcodesClass:Class<Dynamic>) {
		var metas = Meta.getFields(opcodesClass);
		//BraveLog.trace(metas.JUMP_IF);
		
		for (key in Reflect.fields(metas)) {
			var metas:Dynamic = Reflect.getProperty(metas, key);
			var opcodeAttribute:Dynamic = metas.Opcode;
			var unimplemented:Bool = Reflect.hasField(metas, "Unimplemented");
			
			//Log.trace(unimplemented);
			if (opcodeAttribute != null) {
				var id:Int = -1;
				var format:String = "";
				var description:String = "";
				
				// Format with object
				if (Reflect.getProperty(opcodeAttribute, "id")) {
					id = opcodeAttribute.id;
					format = opcodeAttribute.format;
					description = opcodeAttribute.description;
				}
				// Format with array
				else {
					id = opcodeAttribute[0];
					format = opcodeAttribute[Std.int(opcodeAttribute.length - 1)];
				}

				opcodesById.set(id, new Opcode(key, id, format, description, unimplemented));
			}
		}
	}

	public function getOpcodeWithId(id:Int) 
	{
		var opcode = opcodesById.get(id);
		if (opcode == null) throw(new Error(Std.format("Unknown opcode ${id}")));
		return opcode;
	}
	
}