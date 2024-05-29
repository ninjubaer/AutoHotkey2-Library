import { msgbox } from msgbox
Class Gdip {
	static __New() {
		#DllLoad GdiPlus.dll
		input := Buffer(8 + 2 * A_PtrSize, 0)
		NumPut("uint", 1, input)
		this.pToken := (DllCall("GdiPlus\GdiplusStartup", "uintp", &_ := 0, "ptr", input, "uptr", 0), _)
		OnExit(this.__Delete.Bind(this))
	}
	static __Delete(*) {
		DllCall("GdiPlus\GdiplusShutdown", "uint", this.pToken)
	}
	static deleteObject(handle) => DllCall("gdi32\DeleteObject", "uptr", handle)
	/**
	 * 
	 * @param x 
	 * @param y 
	 * @param w 
	 * @param h 
	 * @returns {Bitmap | Number}
	 * Bitmap: success
	 * -1: invalid coordinates
	 */
	static BitmapFromScreen(x?, y?, w?, h?) {
		if !IsSet(x) || !IsSet(y) || !IsSet(w) || !IsSet(h)
			x := y := 0, w := A_ScreenWidth, h := A_ScreenHeight
		if !( x ~= "^\d+$") || !( y ~= "^\d+$") || !( w ~= "^\d+$") || !( h ~= "^\d+$") || (w = 0) || (h = 0)
			return -1
		CDC := this.CreateCompatibleDC()
		bm := this.CreateDIBSection(w, h, CDC.handle)
		obm := CDC.selectObject(bm.handle)
		this.BitBlt(CDC.handle, 0, 0, w, h, (ScreenDC := this.DC()).handle, x, y)
		ScreenDC.release()
		(bm.ptr)
		CDC.selectObject(obm)
		CDC.__Delete()
		return bm
	}
	static BitBlt(hdcDest, x, y, w, h, hdcSrc, x1, y1, raster?) =>
		DllCall("gdi32\BitBlt"
		, "UPtr", hdcDest
		, "Int", x
		, "Int", y
		, "Int", w
		, "Int", h
		, "UPtr", hdcSrc
		, "Int", x1
		, "Int", y1
		, "UInt", Raster ?? 0x00CC0020)
	static CreateBitmap(w, h, f:=0x26200A) {
		bm := this.Bitmap()
		DllCall("GdiPlus\GdipCreateBitmapFromScan0", "uint", w, "uint", h, "int", 0, "uint", f, "ptr", 0, "uptrp", &_ := 0), bm.ptr := _
		return bm
	}
	static CreateDIBSection(w, h, hdc := 0, bpp:=32, &_?) {
		_hdc := hdc || this.GetDC()
		BIH := this.BITMAPINFOHEADER()
		BIH.biWidth := w, BIH.biHeight := h, BIH.biBitCount := bpp
		bm := this.Bitmap()
		bm._handle := DllCall("gdi32\CreateDIBSection", "uptr", _hdc, "ptr", BIH, "uint", 0, "uptrp", &_ := 0, "uptr", 0, "uint", 0)
		if !hdc
			_hdc.release()
		return bm
	}
	static CreateCompatibleBitmap(hdc, w, h) {
		bm := this.Bitmap()
		bm._handle := DllCall("gdi32\CreateCompatibleBitmap", "uptr", hdc, "int", w, "int", h, "uptr", 0)
		return bm
	}
	class BITMAPINFOHEADER {
		biSize: u32 := ObjGetDataSize(this)
		biWidth: i32
		biHeight: i32
		biPlanes: u16 := 1
		biBitCount: u16
		biCompression: u32
		biSizeImage: u32
		biXPelsPerMeter: i32
		biYPelsPerMeter: i32
		biClrUsed: u32
		biClrImportant: u32
	}
	Class Bitmap {
		_handle := 0, _ptr := 0
		__Delete() {
			DllCall("gdiplus\GdipDisposeImage", "ptr", this)
			if this._handle ?? 0
				Gdip.DeleteObject(this._handle)
		}
		ptr {
			get {
				if !this._handle && !this._ptr
					return 0
				if !this._ptr
					this._ptr := (DllCall("GdiPlus\GdipCreateBitmapFromHBITMAP", "uptr", this._handle, "uptr", 0, "uptrp", &_ := 0), _)
				return this._ptr
			}
		}
		handle => (this._handle ?? 0) || this._handle := (DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", this, "uptrp", &_ := 0, "int", 0), _)
		w => (DllCall("gdiplus\GdipGetImageWidth", "ptr", this, "uintp", &_ := 0), _)
		h => (DllCall("gdiplus\GdipGetImageHeight", "ptr", this, "uintp", &_ := 0), _)
		/**
		 * Gdip.Bitmap.save
		 * @param {String} output output path of the saved bitmap
		 * @param {Integer} quality quality of the saved bitmap, default is 95 only for jpeg images
		 * @returns {Number} 
		 * 0: success
		 * -1: invalid file extension
		 * -2: failed to get image encoders
		 * -3: failed to get encoder for the specified extension
		 * -4: failed to save the image
		 */
		save(output, quality := 95) {
			SplitPath output, , , &ext
			if !ext ~= '(?i:(png|jpe?g|bpm|gif|tiff?|dib|jfif|rle))'
				return -1
			DllCall("GdiPlus\GdipGetImageEncodersSize", "uintp", &num := 0, "uintp", &size := 0)
			if !(num && size)
				return -2
			encoders := Buffer(size, 0)
			DllCall("GdiPlus\GdipGetImageEncoders", "uint", num, "uint", size, "ptr", encoders)
			loop num {
				address := NumGet(encoders, (idx := (48 + 7 * A_PtrSize) * (A_Index - 1)) + 32 + 3 * A_PtrSize, "UPtr")
				if !InStr(StrGet(address), "*." ext)
					continue
				pCodec := encoders.ptr + idx
				break
			}
			if !pCodec
				return -3
			; from @iseahound ImagePut.select_codec
			if (quality ~= "^-?\d{1,2}$") and ("image/jpeg" = StrGet(NumGet(encoders, idx + 32 + 4 * A_PtrSize, "ptr"), "UTF-16")) {
				v := Buffer(4), NumPut("uint", quality, v)
				; struct EncoderParameter - http://www.jose.it-berater.org/gdiplus/reference/structures/encoderparameter.htm
				; enum ValueType - https://docs.microsoft.com/en-us/dotnet/api/system.drawing.imaging.encoderparametervaluetype
				; clsid Image Encoder Constants - http://www.jose.it-berater.org/gdiplus/reference/constants/gdipimageencoderconstants.htm
				ep := Buffer(24 + 2 * A_PtrSize)
				NumPut("uptr", 1, ep, 0)  ; Count
				DllCall("ole32\CLSIDFromString", "wstr", "{1D5BE4B5-FA4A-452D-9CDD-5DB35105E7EB}", "ptr", ep.ptr + A_PtrSize, "hresult")
				NumPut("uint", 1, ep, 16 + A_PtrSize)
				NumPut("uint", 4, ep, 20 + A_PtrSize)
				NumPut("ptr", v.ptr, ep, 24 + A_PtrSize)
			}
			return (DllCall("GdiPlus\GdipSaveImageToFile", "ptr", this, "wstr", output, "ptr", pCodec, "ptr", ep ?? 0, "uint", 0) ? -4 : 0)
		}
	}
	Class DC {
		h := 0, hwnd := 0, _ptr := 0
		handle {
			get {
				if !this.h
					this.h := DllCall("GetDC", "uptr", 0)
				return this.h
			}
			set {
				if this.h ?? 0
					this.release()
				this.h := value
				return Value
			}
		}
		ptr {
			get {
				if !this._ptr
					this._ptr := (DllCall("GdiPlus\GdipCreateFromHDC", "uptr", this.h, "uptrp", &_ := 0), _)
				return this._ptr
			}
		}
		release() {
			if this.h
				DllCall("ReleaseDC", "uptr", this.hwnd, "uptr", this.h)
		}
		selectObject(obj) {
			if !this.h
				return 0
			return DllCall("SelectObject", "uptr", this.handle, "uptr", obj)
		}
		__Delete() {
			this.release()
			this.Delete()
		}
		Delete() => DllCall("DeleteDC", "uptr", this.h)
	}
	static CreateCompatibleDC(dc := 0) => (ndc := this.DC(), ndc.h:= DllCall("CreateCompatibleDC", "uptr", dc is Gdip.DC ? dc.handle : dc), ndc)
	static GetDC(hwnd?) => (dc := this.DC(), dc.h := DllCall("GetDC", "uptr", dc.hwnd := hwnd ?? 0), dc)
}
#Include %A_MyDocuments%\AutoHotkey\NatroMacroDev\lib\Gdip_All.ahk
Bitmap := Gdip.BitmapFromScreen()
Bitmap.save("test.png")