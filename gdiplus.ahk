;import { msgbox } from msgbox
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
		if !(x ~= "^\d+$") || !(y ~= "^\d+$") || !(w ~= "^\d+$") || !(h ~= "^\d+$") || (w = 0) || (h = 0)
			return unset
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
	static CreateBitmap(w, h, f := 0x26200A) => Gdip.Bitmap(w,h,f)
	static CreateDIBSection(w, h, hdc := 0, bpp := 32, &_?) {
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
		 * @returns {this} 
		 * this: success
		 * unset: failed
		 */
		save(output, quality := 95) {
			SplitPath output, , , &ext
			if !ext ~= '(?i:(png|jpe?g|bpm|gif|tiff?|dib|jfif|rle))'
				return unset
			DllCall("GdiPlus\GdipGetImageEncodersSize", "uintp", &num := 0, "uintp", &size := 0)
			if !(num && size)
				return unset
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
				return unset
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
			return (DllCall("GdiPlus\GdipSaveImageToFile", "ptr", this, "wstr", output, "ptr", pCodec, "ptr", ep ?? 0, "uint", 0) ? unset : this)
		}
		dispose() => (DllCall("GdiPlus\GdipDisposeImage", "ptr", this), this)
		__New(w?, h?, format?) {
			if !IsSet(w) || !IsSet(h)
				return this
			this._ptr := (DllCall("GdiPlus\GdipCreateBitmapFromScan0", "uint", w, "uint", h, "int", 0, "uint", f ?? 0x26200A, "ptr", 0, "uptrp", &_ := 0), _)
			return this
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
			return this
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
	static CreateCompatibleDC(dc := 0) => (ndc := this.DC(), ndc.h := DllCall("CreateCompatibleDC", "uptr", dc is Gdip.DC ? dc.handle : dc), ndc)
	static GetDC(hwnd?) => (dc := this.DC(), dc.h := DllCall("GetDC", "uptr", dc.hwnd := hwnd ?? 0), dc)
	Class Graphics {
		ptr := 0
		FillRectangle(brush, x, y, w, h) {
			if !this.ptr
				return unset
			return (DllCall(
				"GdiPlus\GdipFillRectangle",
				"ptr", this.ptr,
				"ptr", brush,
				"float", x,
				"float", y,
				"float", w,
				"float", h
			) ? unset : this)
		}
		FillRoundedRectangle(brush, x, y, w, h, r) {
			if !this.ptr
				return unset
			region := this.GetClipRegion()
			this.SetClipRect(x-r, y-r, r*2, r*2, 4)
			this.SetClipRect(x + w - r, y-r, r*2, r*2, 4)
			this.SetClipRect(x-r, y + h - r, r*2, r*2, 4)
			this.SetClipRect(x + w - r, y + h - r, r*2, r*2, 4)
			this.FillRectangle(brush, x, y, w, h)
			this.SetClipRegion(region)
			this.FillEllipse(brush, x, y, r*2, r*2)
			this.FillEllipse(brush, x + w - r*2, y, r*2, r*2)
			this.FillEllipse(brush, x, y + h - r*2, r*2, r*2)
			this.FillEllipse(brush, x + w - r*2, y + h - r*2, r*2, r*2)
			region.Delete()
			return this
		}
		SetClipRect(x, y, w, h, mode := 0) {
			if !this.ptr
				return unset
			return (DllCall("GdiPlus\GdipSetClipRect", "ptr", this.ptr, "float", x, "float", y, "float", w, "float", h, "int", mode) ? unset : this)
		}
		FillEllipse(brush, x, y, w, h) {
			if !this.ptr
				return unset
			return (DllCall(
				"GdiPlus\GdipFillEllipse",
				"ptr", this.ptr,
				"ptr", brush,
				"float", x,
				"float", y,
				"float", w,
				"float", h
			) ? unset : this)
		}
		FillPolygon(brush, points*) {
			if !this.ptr or !points.length
				return unset
			pts := Buffer(8 * points.length, 0)
			if points[1] is Array {
				for i, point in points
					NumPut("float", point[1], "float", point[2], pts, 8 * (i-1))
			}
			else 
				for i, point in points
					NumPut("float", point.x, "float", point.y, pts, 8 * (i-1))
			return (DllCall(
				"GdiPlus\GdipFillPolygon",
				"ptr", this,
				"ptr", brush,
				"ptr", pts,
				"uint", points.length,
				"int", 0
			) ? unset : this)
		}
		FillPie(brush, x, y, w, h, start, sweep) {
			if !this.ptr
				return unset
			return (DllCall(
				"GdiPlus\GdipFillPie",
				"ptr", this.ptr,
				"ptr", brush,
				"float", x,
				"float", y,
				"float", w,
				"float", h,
				"float", start,
				"float", sweep
			) ? unset : this)
		}
		FillRegion(brush, region) {
			if !this.ptr || !region is Gdip.Region
				return unset
			return (DllCall(
				"GdiPlus\GdipFillRegion",
				"ptr", this.ptr,
				"ptr", brush,
				"ptr", region
			) ? unset : this)
		}
		Delete() => DllCall("GdiPlus\GdipDeleteGraphics", "ptr", this.ptr)
		__Delete() {
			if this.ptr
				this.Delete()
		}
		GetClipRegion() {
			if !this.ptr
				return unset
			r := Gdip.CreateRegion()
			DllCall("GdiPlus\GdipGetClip", "ptr", this.ptr, "ptr", r)
			return r
		}
		SetClipRegion(region, mode := 0) {
			if !this.ptr || !region is Gdip.Region
				return unset
			return (DllCall("GdiPlus\GdipSetClipRegion", "ptr", this.ptr, "ptr", region, "int", mode) ? unset : this)
		}
		String(str, hFont, hFormat, rectF, brush) {
			if !this.ptr or !rectF is Gdip.RectF
				return unset
			return (DllCall(
				"GdiPlus\GdipDrawString",
				"ptr", this.ptr,
				"wstr", str,
				"int", str.length,
				"ptr", hFont,
				"ptr", rectF,
				"ptr", hFormat,
				"ptr", brush
			) ? unset : this)
		}
	}
	static GraphicsFromBitmap(bm) {
		g := this.Graphics()
		g.ptr := (DllCall("GdiPlus\GdipGetImageGraphicsContext", "ptr", bm, "uptrp", &_ := 0), _)
		return g
	}
	static GraphicsFromDC(dc := 0) {
		g := this.Graphics()
		g.ptr := (DllCall("GdiPlus\GdipCreateFromHDC", "uptr", IsInteger(dc) ? dc : dc.handle, "uptrp", &_ := 0), _)
		return g
	}
	static GraphicsFromHWND(hwnd) {
		g := this.Graphics()
		g.ptr := (DllCall("GdiPlus\GdipCreateFromHWND", "uptr", hwnd, "uptrp", &_ := 0), _)
		return g
	}
	Class Brush {
		ptr := 0
		Delete() => DllCall("GdiPlus\GdipDeleteBrush", "ptr", this.ptr)
		__Delete() {
			if this.ptr
				this.Delete()
		}
		Class Solid extends Gdip.Brush {
			__New(color) =>
				this.ptr := (DllCall("GdiPlus\GdipCreateSolidFill", "uint", color + 0, "uptrp", &_ := 0), _)
			Call(*) => this
		}
		Class Hatch extends Gdip.Brush {
			__New(front, back, hatch := 0) =>
				this.ptr := (DllCall("GdiPlus\GdipCreateHatchBrush", "uint", hatch, "uint", front + 0, "uint", back + 0, "uptrp", &_ := 0), _)
			Call(*) => this
		}
		Class Line extends Gdip.Brush {
			__New(x1, y1, x2, y2, color1, color2, wrap := 0) => this.ptr := (DllCall("GdiPlus\GdipCreateLineBrush", "ptr", Gdip.Point(x1, y1), "ptr", Gdip.Point(x2, y2), "uint", color1 + 0, "uint", color2 + 0, "uint", wrap, "uptrp", &_ := 0), _)
			Call(*) => this
		}
		Class Texture extends Gdip.Brush {
			__New(bm, wrap := 0, x?, y?, w?, h?) {
				if !IsSet(w) || !IsSet(h) || !IsSet(x) || !IsSet(y)
					return this.ptr := (DllCall("GdiPlus\GdipCreateTexture", "ptr", bm, "uint", wrap, "uptrp", &_ := 0), _)
				this.ptr := (DllCall("GdiPlus\GdipCreateTexture2", "ptr", bm, "uint", wrap, "float", x ?? 0, "float", y ?? 0, "float", w ?? bm.w, "float", h ?? bm.h, "uptrp", &_ := 0), _)
			}
			Call(*) => this
		}
		Clone() => (b := this(), b.ptr := (DllCall("GdiPlus\GdipCloneBrush", "ptr", this, "uptrp", &_ := 0), _), b)
	}
	Class Pen {
		ptr := 0
		Delete() => DllCall("GdiPlus\GdipDeletePen", "ptr", this.ptr)
		__Delete() {
			if this.ptr
				this.Delete()
		}
		__New(colorOrBrush, width := 1) {
			if colorOrBrush is Gdip.Brush
				this.ptr := (DllCall("GdiPlus\GdipCreatePen2", "ptr", colorOrBrush, "float", width, "int", 0, "uptrp", &_ := 0), _)
			else
				this.ptr := (DllCall("GdiPlus\GdipCreatePen1", "uint", colorOrBrush + 0, "float", width, "int", 0, "uptrp", &_ := 0), _)			
		}
	}
	Class Region {
		ptr := 0
		__Delete() => DllCall("GdiPlus\GdipDeleteRegion", "ptr", this)
		Combine(region, mode) => (DllCall("GdiPlus\GdipCombineRegionRegion", "ptr", this, "ptr", region, "int", mode), this)
		CombineRect(x, y, w, h, mode) => (DllCall("GdiPlus\GdipCombineRegionRect", "ptr", this, "float", x, "float", y, "float", w, "float", h, "int", mode), this)
		Delete() => (DllCall("GdiPlus\GdipDeleteRegion", "ptr", this), this)
	}
	static CreateRegion() => (r := this.Region(), r.ptr := (DllCall("GdiPlus\GdipCreateRegion", "uptrp", &_ := 0), _), r)
	static CreateRegionRect(x, y, w, h) => (r := this.Region(), r.ptr := (DllCall("GdiPlus\GdipCreateRegionRect", "float", x, "float", y, "float", w, "float", h, "uptrp", &_ := 0), _), r)
	static CreateRegionPath(path) => (r := this.Region(), r.ptr := (DllCall("GdiPlus\GdipCreateRegionPath", "ptr", path, "uptrp", &_ := 0), _), r)
	Class Rect {
		x: u32
		y: u32
		w: u32
		h: u32
		__New(x := 0, y := 0, w := 0, h := 0) => (this.x := x, this.y := y, this.w := w, this.h := h)
	}
	Class RectF {
		x: f32
		y: f32
		w: f32
		h: f32
		__New(x := 0, y := 0, w := 0, h := 0) => (this.x := x, this.y := y, this.w := w, this.h := h)
	}
	Class Point {
		x: i32, y: i32
		__New(x := 0, y := 0) => (this.x := x, this.y := y)
	}
}
