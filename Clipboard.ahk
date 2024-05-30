Class Clipboard {
	static clipboardTypes := { 1: "CF_TEXT", 2: "CF_BITMAP", 8: "CF_DIB", 13: "CF_UNICODETEXT", 15: "CF_HDROP" }
	static type => this.getClipboardType()
	static text {
		Get {
			if !DllCall("IsClipboardFormatAvailable", "uint", 13)
				return ""
			return A_Clipboard
		}
		set {
			return A_Clipboard := value
		}
	}
	static CopyFile(path) {
		Loop Files path
			path := A_LoopFileFullPath
		DropFiles := Buffer(20 + StrPut(path) + 2, 0)
		NumPut "uint", 20, DropFiles
		NumPut "uint", 1, DropFiles, 16
		StrPut(path, DropFiles.ptr + 20)
		DllCall("OpenClipboard", "UPtr", 0)
		DllCall("EmptyClipboard")
		DllCall("SetClipboardData", "uint", 0xF, "ptr", DropFiles)
		DllCall("CloseClipboard")
	}
	static getClipboardType() {
		DllCall("OpenClipboard", "UPtr", 0)
		for i, j in this.clipboardTypes.OwnProps()
			if DllCall("IsClipboardFormatAvailable", "uint", i)
				if i = 1 && DllCall("IsClipboardFormatAvailable", "uint", 13)
					return 13
				else return i
		return unset
	}
	static getClipBoardData(type?) => DllCall("GetClipboardData", "uint", type ?? this.getClipboardType())
	static FileFromClipboard(destination) {
		DllCall("OpenClipboard", "uint", 0)
		msgbox 'open clipboard'
		if !hData := DllCall("GetClipboardData", "uint", 0xF)
			return MsgBox("No file in clipboard", , 0x1010)
		msgbox 'hData'
		numFiles := DllCall("shell32\DragQueryFileW", "uint", hData, "uint", 0xFFFFFFFF, "uint", 0, "uint", 0)
		msgbox numFiles
		Loop numFiles {
			len := DllCall("shell32\DragQueryFileW", "uint", hData, "uint", A_Index - 1, "uint", 0, "uint", 0)
			VarSetStrCapacity(&filePath, len * 2 + 2)
			DllCall("shell32\DragQueryFileW", "uint", hData, "uint", A_Index - 1, "str", filePath, "uint", len + 1)
			SplitPath(filePath, &filename)
			if !FileExist(filePath)
				continue
			FileCopy(filePath, destination '\' filename)
		}
		DllCall("CloseClipboard")
	}
	static hBitmapFromClipboard() {
		DllCall("OpenClipboard", "UPtr", 0)
		if IsSet(Gdip) && IsObject(Gdip) && Gdip.HasMethod("HBITMAP")
			hBitmap := Gdip.HBITMAP(DllCall("GetClipboardData", "uint", 2)) ; CF_BITMAP
		else hBitmap := DllCall("GetClipboardData", "uint", 2) ; CF_BITMAP
		DllCall("CloseClipboard")
		return hBitmap
	}
	static DibFromClipboard() {
		DllCall("OpenClipboard", "UPtr", 0)
		hDib := DllCall("GetClipboardData", "uint", 8) ; CF_DIB
		DllCall("CloseClipboard")
		return hDib
	}
	static CopyDib(hDib) {
		DllCall("OpenClipboard", "UPtr", 0)
		DllCall("EmptyClipboard")
		DllCall("SetClipboardData", "uint", 8, "uptr", hDib)
		DllCall("CloseClipboard")
	}
	static CopyBitmap(hBitmap) {
		if !hBitmap
			return unset
		static off1 := A_PtrSize = 8 ? 52 : 44, off2 := A_PtrSize = 8 ? 32 : 24
		bi := Buffer(64 + 5 * A_PtrSize, 0)
		DllCall("GetObjectW", "uptr", hBitmap, "int", bi.Size, "ptr", bi)
		hdib := DllCall("GlobalAlloc", "UInt", 2, "UPtr", 40+NumGet(bi, off1, "UInt"), "UPtr")
		pdib := DllCall("GlobalLock", "UPtr", hdib, "UPtr")
		DllCall("RtlMoveMemory", "UPtr", pdib, "UPtr", bi.Ptr+off2, "UPtr", 40)
		DllCall("RtlMoveMemory", "UPtr", pdib+40, "UPtr", NumGet(bi, off2 - (A_PtrSize ? A_PtrSize : 4), "UPtr"), "UPtr", NumGet(bi, off1, "UInt"))
		DllCall("GlobalUnlock", "UPtr", hdib)
		DllCall("user32\OpenClipboard", "uptr", 0)
		DllCall("user32\EmptyClipboard")
		DllCall("user32\SetClipboardData", "uint", 8, "ptr", hdib) ; CF_DIB
		DllCall("user32\CloseClipboard")
		return hBitmap
	}
}