/************************************************************************
 * @description SHFILEOP
 * @file SHFILEOP.ahk
 * @author ninju
 * @date 2024/05/27
 * @version 0.0.1
 ***********************************************************************/
Class SHFILEOP {
	static operations := { move: 0x1, copy: 0x2, delete: 0x3, rename: 0x4 }
	static fFlags := {
		FOF_MULTIDESTFILES: 0x1,
		FOF_CONFIRMMOUSE: 0x2,
		FOF_SILENT: 0x4,
		FOF_RENAMEONCOLLISION: 0x8,
		FOF_NOCONFIRMATION: 0x10,
		FOF_WANTMAPPINGHANDLE: 0x20,
		FOF_ALLOWUNDO: 0x40,
		FOF_FILESONLY: 0x80,
		FOF_SIMPLEPROGRESS: 0x100,
		FOF_NOCONFIRMMKDIR: 0x200,
		FOF_NOERRORUI: 0x400,
		FOF_NOCOPYSECURITYATTRIBS: 0x800,
		FOF_NORECURSION: 0x1000,
		FOF_NO_CONNECTED_ELEMENTS: 0x2000,
		FOF_WANTNUKEWARNING: 0x4000,
		FOF_NORECURSEREPARSE: 0x8000
	}
	static return := {
		2: "File not found",
		3: "Path not found",
		5: "Access denied",
		10: "Invalid handle",
		11: "Invalid parameter",
		12: "Disk full",
		15: "Invalid drive",
		16: "Sharing violation",
		17: "File exists",
		18: "Cannot create file",
		32: "Sharing buffer overflow",
		53: "Network path not found",
		67: "Network name not found",
		80: "File already exists",
		87: "Invalid parameter",
		1026: "Directory not empty",
		1392: "File or directory already exists",
		161: "Bad path name",
		206: "Path too long",
		995: "Operation cancelled"
	}
	Class _SHFILEOPSTRUCT {
		hwnd: uptr
		wFunc: u32
		pFrom: iptr
		pTo: iptr
		fFlags: u32
		fAnyOperationsAborted: i8
		hNameMappings: uptr
		lpszProgressTitle: iptr
	}
	static move(sourceDir, destDir, flags := this.fFlags.FOF_SILENT | this.fFlags.FOF_NOCONFIRMATION | this.fFlags.FOF_NOERRORUI, &errormsg:=false) {
		SHFILEOPSTRUCT := this._SHFILEOPSTRUCT()
		SHFILEOPSTRUCT.wFunc := this.operations.move
		SHFILEOPSTRUCT.pFrom := StrPtr(sourceDir)
		SHFILEOPSTRUCT.pTo := StrPtr(destDir)
		SHFILEOPSTRUCT.fFlags := flags
		r:= DllCall("shell32\SHFileOperationW", "Ptr", SHFILEOPSTRUCT)
		if this.return.HasProp(r)
			errormsg := this.return.%r%
		return r
	}
	static copy(sourceDir, destDir, flags := this.fFlags.FOF_SILENT | this.fFlags.FOF_NOCONFIRMATION | this.fFlags.FOF_NOERRORUI, &errormsg:=false) {
		SHFILEOPSTRUCT := this._SHFILEOPSTRUCT()
		SHFILEOPSTRUCT.wFunc := this.operations.copy
		SHFILEOPSTRUCT.pFrom := StrPtr(sourceDir)
		SHFILEOPSTRUCT.pTo := StrPtr(destDir)
		SHFILEOPSTRUCT.fFlags := flags
		r:= DllCall("shell32\SHFileOperationW", "Ptr", SHFILEOPSTRUCT)
		if this.return.HasProp(r)
			errormsg := this.return.%r%
		return r
	}
	static delete(sourceDir, flags := this.fFlags.FOF_SILENT | this.fFlags.FOF_NOCONFIRMATION | this.fFlags.FOF_NOERRORUI, &errormsg:=false) {
		SHFILEOPSTRUCT := this._SHFILEOPSTRUCT()
		SHFILEOPSTRUCT.wFunc := this.operations.delete
		SHFILEOPSTRUCT.pFrom := StrPtr(sourceDir)
		SHFILEOPSTRUCT.fFlags := flags
		r:= DllCall("shell32\SHFileOperationW", "Ptr", SHFILEOPSTRUCT)
		if this.return.HasProp(r)
			errormsg := this.return.%r%
		return r
	}
	static rename(sourceDir, destDir, flags := this.fFlags.FOF_SILENT | this.fFlags.FOF_NOCONFIRMATION | this.fFlags.FOF_NOERRORUI, &errormsg:=false) {
		SHFILEOPSTRUCT := this._SHFILEOPSTRUCT()
		SHFILEOPSTRUCT.wFunc := this.operations.rename
		SHFILEOPSTRUCT.pFrom := StrPtr(sourceDir)
		SHFILEOPSTRUCT.pTo := StrPtr(destDir)
		SHFILEOPSTRUCT.fFlags := flags
		r:= DllCall("shell32\SHFileOperationW", "Ptr", SHFILEOPSTRUCT)
		if this.return.HasProp(r)
			errormsg := this.return.%r%
		return r
	}

}
