package
{
	import com.bit101.components.PushButton;
	import com.bit101.components.Style;
	import com.bit101.components.VBox;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.getTimer;
	
	import parser.Script;
	
	import sample.lua.CModule;
	import sample.lua.__lua_objrefs;
	
	public class LuaAndAScriptTest extends Sprite
	{
		public function LuaAndAScriptTest()
		{
			super();
			
			// 支持 autoOrient
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			addEventListener(Event.ADDED_TO_STAGE,onAddToStage);
		}
		
		private var file:File = new File();
		private var fileStream:FileStream = new FileStream();
		
		private var luaCode:String;
		private var luastate:int;
		
		private var ascriptCode:String;
		private var ascriptInstance:*;
		public function onAddToStage(event:Event):void
		{
			initUI();
			initAScript();
			initLua();
		}
		
		private function initUI():void
		{
			Style.embedFonts = false;
			Style.fontName = "Arial";
			Style.fontSize = 19;
			var v:VBox = new VBox(this,20,20);v.spacing = 10;
			new PushButton(v,0,0,"内部空函数调用测试",internalEmptyCall);
			new PushButton(v,0,0,"AS3调用脚本内空函数",emptyCallFromAs3ToScript);
			new PushButton(v,0,0,"脚本调用AS3内空函数",emptyCallFromScriptToAs3);
			new PushButton(v,0,0,"累加测试",cumsum);
		}
		
		private function initAScript():void{
			file.nativePath = File.applicationDirectory.nativePath+"/script/ascript.ascript";
			fileStream.open(file,FileMode.READ);
			ascriptCode = fileStream.readUTFBytes(fileStream.bytesAvailable);
			fileStream.close();
			
			Script.init(this);
			Script.LoadFromString(ascriptCode);
			
			ascriptInstance=Script.New("AScriptClass");
			ascriptInstance.main = this;
		}
		
		private function initLua():void{
			file.nativePath = File.applicationDirectory.nativePath+"/script/lua.lua";
			fileStream.open(file,FileMode.READ);
			luaCode = fileStream.readUTFBytes(fileStream.bytesAvailable);
			fileStream.close();
			
			CModule.rootSprite = this;
			//				CModule.vfs.console = this;
			CModule.startAsync(this);
			var err:int = 0;
			luastate = Lua.luaL_newstate();
			Lua.lua_atpanic(luastate, atPanic);
			Lua.luaL_openlibs(luastate);
			err = Lua.luaL_loadstring(luastate, luaCode);
			if(err) {
				trace("Error " + err + ": " + Lua.luaL_checklstring(luastate, 1, 0));
				Lua.lua_close(luastate);
				return
			}
			err = Lua.lua_pcallk(luastate, 0, Lua.LUA_MULTRET, 0, 0, null);
			
			Lua.lua_getglobal(luastate, "setMain");
			push_objref(this);
			Lua.lua_callk(luastate, 1, 0, 0, null);
		}
		
		private function push_objref(o:*):void
		{
			var udptr:int = Lua.push_flashref(luastate)
			sample.lua.__lua_objrefs[udptr] = o
		}
		
		private function atPanic(e:*):void{
			trace("Lua Panic: " + Lua.luaL_checklstring(luastate, -1, 0));
		}
		//内部调用空函数测试
		public function internalEmptyCall(event:MouseEvent):void{
			var count:int=100000,i:int,runtime:int;
			
			runtime = getTimer();
			for (i = 0; i <count; i++) {
				emptyFunction();
			}
			trace("AS3内部"+count+"次空函数的调用：",getTimer() - runtime);
			
			runtime = getTimer();
			Lua.lua_getglobal(luastate, "internalEmptyCall");
			Lua.lua_pushinteger(luastate,count);//这里传递数据怎么没有效果呢？？？改变了count之后还要改变LUA脚本中的循环次数
			Lua.lua_callk(luastate, 1, 0, 0, null);
			trace("Lua内部"+count+"次空函数的调用：",getTimer() - runtime);
			
			runtime = getTimer();
			ascriptInstance.internalEmptyCall(count);
			trace("ascript内部"+count+"次空函数的调用：",getTimer() - runtime);
		}
		
		//as3调用脚本内空函数
		public function emptyCallFromAs3ToScript(event:MouseEvent):void{
			var count:int=100000,i:int,runtime:int;
			
			runtime = getTimer();
			for (i = 0; i <count; i++) {
				Lua.lua_getglobal(luastate, "emptyFunction");
				Lua.lua_callk(luastate, 0, 0, 0, null);
			}
			trace("AS3调用Lua"+count+"次空函数总时间：",getTimer() - runtime);
			
			runtime = getTimer();
			for (i = 0; i <count; i++) {
				ascriptInstance.emptyFunction();
			}
			trace("AS3调用AScript"+count+"次空函数总时间：",getTimer() - runtime);
		}
		
		//脚本调用as3内空函数
		public function emptyCallFromScriptToAs3(event:MouseEvent):void{
			var count:int=100000,runtime:int;
			
			runtime = getTimer();
			Lua.lua_getglobal(luastate, "emptyCallFromScriptToAs3");
			Lua.lua_pushinteger(luastate,count);//这里传递数据怎么没有效果呢？？？改变了count之后还要改变LUA脚本中的循环次数
			Lua.lua_callk(luastate, 1, 0, 0, null);
			trace("Lua调用AS3"+count+"次空函数总时间：",getTimer() - runtime);
			
			runtime = getTimer();
			ascriptInstance.emptyCallFromScriptToAs3(count);
			trace("AScript调用AS3"+count+"次空函数总时间：",getTimer() - runtime);
		}
		
		//累加
		public function cumsum(event:MouseEvent):void{
			var count:int=100000,i:int,runtime:int;
			var sum:uint;
			
			runtime = getTimer();
			for (i = 0; i < count; i++) {
				sum+=i;
			}
			trace("AS3"+count+"次累加总时间：",getTimer() - runtime);
			
			runtime = getTimer();
			Lua.lua_getglobal(luastate, "cumsum");
			Lua.lua_pushinteger(luastate,count);//这里传递数据怎么没有效果呢？？？改变了count之后还要改变LUA脚本中的循环次数
			Lua.lua_callk(luastate, 1, 0, 0, null);
			trace("Lua"+count+"次累加总时间：",getTimer() - runtime);
			
			runtime = getTimer();
			ascriptInstance.cumsum(count);
			trace("AScript"+count+"次累加总时间：",getTimer() - runtime);
		}
		
		public function emptyFunction():void{
		}
		
		public function write(fd:int, buf:int, nbyte:int, errno_ptr:int):int{
			var str:String = CModule.readString(buf, nbyte);
			trace(str);
			return nbyte;
		}
		
		public function read(fd:int, bufPtr:int, nbyte:int, errnoPtr:int):int{
			return 0;
		}
		
		public function ioctl(fd:int, com:int, data:int, errnoPtr:int):int
		{
			return 0;
		}
		
		public function fcntl(fd:int, com:int, data:int, errnoPtr:int):int{
			return 0;
		}
	}
}