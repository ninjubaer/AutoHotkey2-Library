/************************************************************************
 * @description extensions for map object
 * @file MapExtension.ahk
 * @author ninju
 * @date 2024/05/25
 * @version 0.0.1
 ***********************************************************************/

Class __MapEx extends Map {
	static __New() => (
		Super.Prototype.keys := ObjBindMethod(this, "keys"),
		Super.Prototype.forEach := ObjBindMethod(this, "forEach")
	)
	static keys(obj) {
		keys := []
		for key in obj
			keys.Push(key)
		return keys
	}
	static forEach(obj, func) {
		for key, val in obj
			(func.MinParams > 1 ? (func)(key, val) : (func)(val))
		return true
	}
}
