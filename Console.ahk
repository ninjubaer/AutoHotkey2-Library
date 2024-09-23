/************************************************************************
 * @description Console class for AHK
 * @file Console.ahk
 * @author ninju
 * @date 2024/05/25
 * @version 0.0.1
 ***********************************************************************/
#Include JSON.ahk
class Console {
	static colors := {
		black: 0,
		blue: 1,
		green: 2,
		cyan: 3,
		red: 4,
		magenta: 5,
		yellow: 6,
		white: 7,
		gray: 8,
		lightblue: 9,
		lightgreen: 10,
		lightcyan: 11,
		lightred: 12,
		lightmagenta: 13,
		lightyellow: 14,
		brightwhite: 15
	}
	static __New() => !this.hConsole ? DllCall("AllocConsole") : ""
	static log(text, color := "white", handle?) {
		if IsObject(text)
			text := JSON.stringify(text)
		if !this.colors.HasProp(color)
			color := "white"
		DllCall("SetConsoleTextAttribute", "Ptr", this.hConsole, "UShort", this.colors.%color%)
		FileAppend(text . "`n", handle ?? "*")
		DllCall("SetConsoleTextAttribute", "Ptr", this.hConsole, "UShort", this.colors.white)
	}
	static hConsole => DllCall("GetStdHandle", "UInt", -11, "Ptr")
	static error(text) => this.log(text, "red", "**")
	static warn(text) => this.log(text, "yellow")
	static info(text) => this.log(text, "cyan")
	static success(text) => this.log(text, "green")
	static __Delete() {
		DllCall("FreeConsole")
		this.hConsole := ""
	}
	static clear() {
		DllCall("SetConsoleTextAttribute", "Ptr", this.hConsole, "UShort", this.colors.white)
		DllCall("FillConsoleOutputCharacter", "Ptr", this.hConsole, "UChar", 32, "UInt", 9999, "UInt", 0, "UIntP", 0)
		DllCall("FillConsoleOutputAttribute", "Ptr", this.hConsole, "UShort", 15, "UInt", 9999, "UInt", 0, "UIntP", 0)
		DllCall("SetConsoleCursorPosition", "Ptr", this.hConsole, "UInt", 0)
	}
}
