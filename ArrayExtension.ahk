/************************************************************************
 * @description extension for Array object
 * @file ArrayExtension.ahk
 * @author ninju
 * @date 2024/05/23
 * @version 0.0.1
 ***********************************************************************/


Class __ArrEx extends Array {
	static __new() => (
		super.Prototype.includes := ObjBindMethod(this, 'includes'),
		super.Prototype.forEach := ObjBindMethod(this, 'forEach'),
		super.Prototype.find := ObjBindMethod(this, 'find'),
		super.Prototype.filter := ObjBindMethod(this, 'filter')
	)
	static includes(obj, val, sensitivity?) {
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
	static filter(obj, func) {
		newArr := []
		for i,j in obj
			if (func.MinParams > 1 ? (func)(i,j) : (func)(j))
				newArr.push(j)
		return newArr
	}
	static find(obj, func) {
		for i,j in obj
			if (func.MinParams > 1 ? (func)(i,j) : (func)(j))
				return j
		return false
	}
}
