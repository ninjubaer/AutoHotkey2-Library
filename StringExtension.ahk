/************************************************************************
 * @description String extensions for AutoHotkey v2
 * @file StringExtension.ahk
 * @author ninju
 * @date 2024/05/25
 * @version 0.0.1
 ***********************************************************************/

Class __StringEx extends String {
	static __New() => (
		Super.Prototype.__Enum := ObjBindMethod(this, "__Enum"),
		Super.Prototype.slice := Super.Prototype.substring := ObjBindMethod(this, "slice"),
		Super.Prototype.upper := ObjBindMethod(this, "upper"),
		Super.Prototype.lower := ObjBindMethod(this, "lower"),
		Super.Prototype.first := ObjBindMethod(this, "first"),
		objDefineProps := Object.Prototype.DefineProp,
		objDefineProps(Super.Prototype,
			"__item", {
				get: (self, index) => SubStr(self, index, 1),
				set: (self, value, index) => unset
			}),
		Super.Prototype.len := ObjBindMethod(this, "len"),
		this
	)
	static __Enum(str, num) =>
		StrSplit(str).__Enum(num)
	static slice(p*) => SubStr(p*)
	static upper(str) => StrUpper(str)
	static lower(str) => StrLower(str)
	static first(str) => SubStr(str, 1, 1)
	static len(str) => StrLen(str)
}
