package;

import flixel.FlxG;
#if sys
import Main;
import hscript.Expr.Error;
import openfl.Assets;
import hscript.*;
#end

using StringTools;

// This is used for well, softcoded scripting.
// The reason it looks so similar to Yoshman's HScript class is because I used it as an example for hscript.
// BUT YOSHMAN I SWEAR ON MY LIFE I DID NOT COPY PASTE YOUR HSCRIPT CLASS I SWEAR
class HScript
{
	#if sys
	public static final allowedExtensions:Array<String> = ["hx", "hscript", "hxs", "script"];
	public static var parser:Parser;
	public static var staticVars:Map<String, Dynamic> = new Map();

	public var interp:Interp;
	public var expr:Expr;

	var initialLine:Int = 0;
	#end

	public var isBlank:Bool;

	var blankVars:Map<String, Null<Dynamic>>;
	var path:String;

	#if sys
	public function new(scriptPath:String)
	{
		path = scriptPath;
		if (!scriptPath.startsWith("assets/"))
			scriptPath = "assets/" + scriptPath;
		var boolArray:Array<Bool> = [for (ext in allowedExtensions) Assets.exists('$scriptPath.$ext')];
		isBlank = (!boolArray.contains(true));
		if (boolArray.contains(true))
		{
			interp = new Interp();
			interp.staticVariables = staticVars;
			interp.allowStaticVariables = true;
			interp.allowPublicVariables = true;
			interp.errorHandler = traceError;
			try
			{
				var path = scriptPath + "." + allowedExtensions[boolArray.indexOf(true)];
				parser.line = 1; // Reset the parser position.
				expr = parser.parseString(Assets.getText(path));
				interp.variables.set("trace", hscriptTrace);
			}
			catch (e)
			{
				traceError(e);

				isBlank = true;
			}
		}
		if (isBlank)
		{
			blankVars = new Map();
		}
		else
		{
			var defaultVars:Map<String, Dynamic> = [
				"Math" => Math,
				"Std" => Std,

				"FlxG" => flixel.FlxG,
				"Http" => haxe.Http,
				"FlxSprite" => flixel.FlxSprite,
				"FlxText" => flixel.text.FlxText,
				// Flixel Addons because hscript says "FUCK YOU! I AINT IMPORTING ADDONS!"
				"FlxTrail" => flixel.addons.effects.FlxTrail,
				"FlxBackdrop" => flixel.addons.display.FlxBackdrop,
				"Assets" => Assets,

				"PlayState" => PlayState,
				"Paths" => Paths,
				"Conductor" => Conductor,
				"CoolUtil" => CoolUtil,
				"Character" => Character,
				"CustomOption" => Options.DefaultOption,
			];
			for (va in defaultVars.keys())
				setValue(va, defaultVars[va]);
		}
	}

	function hscriptTrace(v:Dynamic)
		trace(path + ":" + interp.posInfos().lineNumber + ": " + Std.string(v));

	function traceError(e:Dynamic)
	{
		var errorString:String = e.toString();

		FlxG.stage.window.alert(errorString.substr(7, errorString.length), path);
	}

	public function callFunction(name:String, ?params:Array<Dynamic>)
	{
		if (interp == null || parser == null)
			return null;

		var functionVar = (isBlank) ? blankVars.get(name) : interp.variables.get(name);
		var hasParams = (params != null && params.length > 0);
		if (functionVar == null || !Reflect.isFunction(functionVar))
			return null;
		return hasParams ? Reflect.callMethod(null, functionVar, params) : functionVar();
	}

	inline public function getValue(name:String):Dynamic
		return (isBlank) ? blankVars.get(name) : (interp != null) ? interp.variables.get(name) : null;

	inline public function setValue(name:String, value:Dynamic)
		(isBlank) ? blankVars.set(name, value) : (interp != null) ? interp.variables.set(name, value) : null;
	#else
	public var interp:Null<Dynamic> = null;
	public var expr:Null<Dynamic> = null;

	public function new(scriptPath:String)
	{
		blankVars = new Map();
		isBlank = true;
	}

	inline public function getValue(name:String)
		return blankVars.get(name);

	public function setValue(name:String, value:Dynamic)
		blankVars.set(name, value);
	#end
}
