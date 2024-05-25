/************************************************************************
 * @description extension for Array object
 * @file ArrayExtension.ahk
 * @author ninju
 * @date 2024/05/23
 * @version 0.0.1
 ***********************************************************************/


Class __ArrEx extends Array {
	static __new() => (
		super.Prototype.includes := ObjBindMethod(this, '__includes'),
		super.Prototype.forEach := ObjBindMethod(this, 'forEach')
	)
	static __includes(obj, val, sensitivity?) {
		for i, j in obj
			if sensitivity ?? false {
				if j == val
					return i
			}
			else if j = val
				return i
		return false
	}
	static forEach(obj, func) {
		for i,j in obj
			(func.MinParams > 1 ? (func)(i,j) : (func)(j))
		return true
	}
}
