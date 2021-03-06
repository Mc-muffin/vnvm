// Based on the SoundFont reader of NAudio 
//      C# Code: (C) Mark Heath 2006 (mark@wordandspirit.co.uk)
//      Haxe Code: (C) Daniel Kuschny 2012 (danielku15@coderline.net)
// You are free to use this code for your own projects.
// Please consider giving credit somewhere in your app to this code if you use it
// Please do not redistribute this code without my permission
// Please get in touch and let me know of any bugs you find, enhancements you would like,
// and apps you have written
package midi.sf2;

import midi.Sequencer;

class Preset 
{
    public var name:String;
    public var patch_number:Int;
    public var bank:Int;
    public var start_preset_zoneindex:Int;
    public var end_preset_zoneindex:Int;
    public var library:Int;
    public var genre:Int;
    public var morphology:Int;
    public var zones:Array<Zone>;

    public function new() 
    {        
    }
}