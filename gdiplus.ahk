/************************************************************************
 * @description Object Oriented GDI+ Library for AutoHotkey
 * @file gdiplus.ahk
 * @author ninju
 * @date 2024/05/29
 * @version 0.0.1
 ***********************************************************************/

;import { msgbox } from msgbox
Class Gdip {
	;?=======================
	;?========Start Up=======
	;?=======================
	static __New() {
		#DllLoad GdiPlus.dll
		input := Buffer(8 + 2 * A_PtrSize, 0)
		NumPut("uint", 1, input)
		this.pToken := (DllCall("GdiPlus\GdiplusStartup", "uintp", &_ := 0, "ptr", input, "uptr", 0), _)
		OnExit(this.__Delete.Bind(this))
	}
	;?=======================
	;?=======Shut Down=======
	;?=======================
	static __Delete(*) {
		DllCall("GdiPlus\GdiplusShutdown", "uint", this.pToken)
	}
	;?=======================
	static deleteObject(handle) => DllCall("gdi32\DeleteObject", "uptr", handle)
	static UpdateLayeredWindow(hwnd, hdc, x?, y?, w?, h?, a:=255) {
		if IsSet(x) && IsSet(y) && x is Number && y is Number
			point := this.Point(x, y)
		if !IsSet(w) || !IsSet(h) || not (w is Number) || not (h is Number)
			rect := this.WinGetRect(hwnd), w := rect.w, h := rect.h
		return DllCall(
			"user32\UpdateLayeredWindow",
			"uptr", hwnd,
			"uptr", 0,
			"ptr", point ?? 0,
			"int64p", w | (h << 32),
			"uptr", hdc,
			"int64p", 0,
			"uint", 0,
			"uintp", (Alpha??0)<<16|1<<24,
			"uint", 2
		)
	}
	static WinGetRect(hwnd) {
		rect := this.Rect()
		DllCall("GetWindowRect", "uptr", hwnd, "ptr", rect)
		return rect
	}
	;?=======================
	;?=======================
	;?========Bitmaps========
	;?=======================
	/**
	 * @param x 
	 * @param y 
	 * @param w 
	 * @param h 
	 * @returns {Bitmap | unset}
	 * *Bitmap: success
	 * *unset: failed
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
	static CreateBitmap(w, h, f := 0x26200A) => Gdip.Bitmap(w, h, f)
	static CreateDIBSection(w, h, hdc := 0, bpp := 32, &_?) {
		_hdc := hdc || this.GetDC()
		BIH := this.BITMAPINFOHEADER(w,h,bpp)
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
	;?=======================
	;?==========hDC==========
	;?=======================
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
			static CreateCompatibleDC(dc := 0) => (ndc := this.DC(), ndc.h := DllCall("CreateCompatibleDC", "uptr", dc is Gdip.DC ? dc.handle : dc), ndc)
	static GetDC(hwnd?) => (dc := this.DC(), dc.h := DllCall("GetDC", "uptr", dc.hwnd := hwnd ?? 0), dc)
	static GetDCEx(hwnd, region, flags) => (dc := this.DC(), dc.h := DllCall("GetDCEx", "uptr", hwnd, "ptr", region, "uint", flags), dc)
	;?=======================
	;?========Graphics=======
	;?=======================
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
	;?=======================
	;?========Region=========
	;?=======================
	static CreateRegion() => (r := this.Region(), r.ptr := (DllCall("GdiPlus\GdipCreateRegion", "uptrp", &_ := 0), _), r)
	static CreateRegionRect(x, y, w, h) => (r := this.Region(), r.ptr := (DllCall("GdiPlus\GdipCreateRegionRect", "float", x, "float", y, "float", w, "float", h, "uptrp", &_ := 0), _), r)
	static CreateRegionPath(path) => (r := this.Region(), r.ptr := (DllCall("GdiPlus\GdipCreateRegionPath", "ptr", path, "uptrp", &_ := 0), _), r)
	;?=======================
	;?========Classes========
	;?=======================
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
		 * @param {String} output output path of the saved bitmap
		 * @param {Integer} quality quality of the saved bitmap, only works for jpeg
		 * @returns {this}
		 * *this: success
		 * *unset: failed
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
	Class Path {
		ptr := 0
		__New() {
			this.ptr := (DllCall("GdiPlus\GdipCreatePath", "uint", 0, "uptrp", &_ := 0), _)
		}
		addPathArc(x, y, w, h, start, sweep) {
			if !this.ptr
				return unset
			return (DllCall(
				"GdiPlus\GdipAddPathArc",
				"ptr", this,
				"float", x,
				"float", y,
				"float", w,
				"float", h,
				"float", start,
				"float", sweep
			) ? unset : this)
		}
		addPathEllipse(x, y, w, h) {
			if !this.ptr
				return unset
			return (DllCall(
				"GdiPlus\GdipAddPathEllipse",
				"ptr", this,
				"float", x,
				"float", y,
				"float", w,
				"float", h
			) ? unset : this)
		}
		addPathPolygon(points*) {
			if !this.ptr or !points.length
				return unset
			pts := Buffer(8 * points.length, 0)
			if points[1] is Array {
				for i, point in points
					NumPut("float", point[1], "float", point[2], pts, 8 * (i - 1))
			}
			else
				for i, point in points
					NumPut("float", point.x, "float", point.y, pts, 8 * (i - 1))
			return (DllCall(
				"GdiPlus\GdipAddPathPolygon",
				"ptr", this,
				"ptr", pts,
				"uint", points.length
			) ? unset : this)
		}
		closePathFigure() {
			if !this.ptr
				return unset
			return (DllCall("GdiPlus\GdipClosePathFigure", "ptr", this) ? unset : this)
		}
	}
	Class DC {
		h := 0, hwnd := 0
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
	Class Graphics {
		ptr := 0
		FillRectangle(brush, x, y, w, h) {
			if !this.ptr
				return unset
			return (DllCall(
				"GdiPlus\GdipFillRectangle",
				"ptr", this,
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
			this.SetClipRect(x - r, y - r, r * 2, r * 2, 4)
			this.SetClipRect(x + w - r, y - r, r * 2, r * 2, 4)
			this.SetClipRect(x - r, y + h - r, r * 2, r * 2, 4)
			this.SetClipRect(x + w - r, y + h - r, r * 2, r * 2, 4)
			this.FillRectangle(brush, x, y, w, h)
			this.SetClipRegion(region)
			this.FillEllipse(brush, x, y, r * 2, r * 2)
			this.FillEllipse(brush, x + w - r * 2, y, r * 2, r * 2)
			this.FillEllipse(brush, x, y + h - r * 2, r * 2, r * 2)
			this.FillEllipse(brush, x + w - r * 2, y + h - r * 2, r * 2, r * 2)
			region.Delete()
			return this
		}
		FillRoundedRectanglePath(brush, x, y, w, h, r) {
			if !this.ptr
				return unset
			path := Gdip.Path()
			d := r*2, w-= d, h-= d
			path.addPathArc(x, y, d, d, 180, 90)
			path.addPathArc(x + w, y, d, d, 270, 90)
			path.addPathArc(x + w, y + h, d, d, 0, 90)
			path.addPathArc(x, y + h, d, d, 90, 90)
			path.closePathFigure()
			return this.FillPath(brush, path)
		}
		FillPath(brush, path) {
			if !this.ptr || !path || !brush
				return unset
			return (DllCall("GdiPlus\GdipFillPath", "ptr", this, "ptr", brush, "ptr", path, "uptr", 0) ? unset : this)
		}
		SetClipRect(x, y, w, h, mode := 0) {
			if !this.ptr
				return unset
			return (DllCall("GdiPlus\GdipSetClipRect", "ptr", this, "float", x, "float", y, "float", w, "float", h, "int", mode) ? unset : this)
		}
		FillEllipse(brush, x, y, w, h) {
			if !this.ptr
				return unset
			return (DllCall(
				"GdiPlus\GdipFillEllipse",
				"ptr", this,
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
					NumPut("float", point[1], "float", point[2], pts, 8 * (i - 1))
			}
			else
				for i, point in points
					NumPut("float", point.x, "float", point.y, pts, 8 * (i - 1))
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
				"ptr", this,
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
				"ptr", this,
				"ptr", brush,
				"ptr", region
			) ? unset : this)
		}
		Delete() => DllCall("GdiPlus\GdipDeleteGraphics", "ptr", this)
		__Delete() {
			if this.ptr
				this.Delete()
		}
		GetClipRegion() {
			if !this.ptr
				return unset
			r := Gdip.CreateRegion()
			DllCall("GdiPlus\GdipGetClip", "ptr", this, "ptr", r)
			return r
		}
		SetClipRegion(region, mode := 0) {
			if !this.ptr || !region is Gdip.Region
				return unset
			return (DllCall("GdiPlus\GdipSetClipRegion", "ptr", this, "ptr", region, "int", mode) ? unset : this)
		}
		/**
		 * @param {String} text
		 * @param {String} options
		 * * s{size} : default 12
		 * * x{x} : default 0
		 * * y{y} : default 0
		 * * w{width} : default 100
		 * * h{height} : default 100
		 * * align: {center|left/near|right/far} : default near
		 * * vertical align: {vcenter|top/vnear|bottom/vfar} : default vnear
		 * * NoWrap : default false
		 * @param {Gdip.Brush} brush 
		 * @param {String} font 
		 * @param {Integer} flags
		 * *StringFormatFlagsDirectionRightToLeft = 0x00000001
		 * *StringFormatFlagsDirectionVertical = 0x00000002
		 * *StringFormatFlagsNoFitBlackBox = 0x00000004
		 * *StringFormatFlagsDisplayFormatControl = 0x00000020
		 * *StringFormatFlagsNoFontFallback = 0x00000400
		 * *StringFormatFlagsMeasureTrailingSpaces = 0x00000800
		 * *StringFormatFlagsNoWrap = 0x00001000
		 * *StringFormatFlagsLineLimit = 0x00002000
		 * *StringFormatFlagsNoClip = 0x00004000
		 * @returns {unset | Gdip.Graphics} 
		 */
		text(text, options, brush?, font:='Arial', flags?) {
			static regex := {
				size: "s\K[\-\d\.]+",
				x: "x\K[\-\d\.]+",
				y: "y\K[\-\d\.]+",
				w: "w\K[\-\d\.]+",
				h: "h\K[\-\d\.]+",
				align: "(Near|Center|Far|Left|Right)",
				valign: "(vNear|vCenter|vFar|Top|Bottom)",
				NoWrap: "NoWrap"
			}
			if !this.ptr
				return unset
			_options := {size: 12, x: 0, y: 0, w: width ?? 100, h: height ?? 100, align: 0, valign: 0, NoWrap: 0}
			for i, j in regex.OwnProps()
				if (m:=(RegExMatch(options, 'i)' j, &match), match?match.0:""))
					_options.%i% := StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(m, "v", ""), "Near", 0), "Center", 1), "Far", 2), "Left", 0), "Right", 2), "Top", 0), "Bottom", 2), "NoWrap", 0x1000)
			_font := Gdip.Font(font, _options.size)
			_format := Gdip.StringFormat()
			_format.setAlignment(_options.align), _format.setLineAlignment(_options.valign), _format.setFormatFlags(_options.NoWrap | 0x4000 | (flags ?? 0))
			_brush := brush ?? Gdip.Brush.Solid(0xFF000000)
			rectF := Gdip.RectF(_options.x, _options.y, _options.w, _options.h)
			return this.String(text, _font, _format, rectF, _brush)
		}
		String(str, hFont, hFormat, rectF, brush) {
			if !this.ptr or !rectF is Gdip.RectF
				return unset
			return (DllCall(
				"GdiPlus\GdipDrawString",
				"ptr", this,
				"wstr", str "",
				"int", StrLen(str),
				"ptr", hFont,
				"ptr", rectF,
				"ptr", hFormat,
				"ptr", brush
			) ? unset : this)
		}
	}
	Class Brush {
		ptr := 0
		Delete() => DllCall("GdiPlus\GdipDeleteBrush", "ptr", this)
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
		Delete() => DllCall("GdiPlus\GdipDeletePen", "ptr", this)
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
	Class Font {
		/**
		 * @param {String} family 
		 * @param {Integer} size 
		 * @param {Integer} style
		 * *0: Regular
		 * *1: Bold
		 * *2: Italic
		 * *4: Underline
		 * *8: Strikeout
		 */
		__New(family, size:=1, style := 0) {
			DllCall("GdiPlus\GdipCreateFontFamilyFromName", "wstr", family, "ptr", 0, "uptrp", &hFont := 0)
			this.ptr := this.handle := (DllCall("GdiPlus\GdipCreateFont", "ptr", hFont, "float", size, "int", style is Integer ? style : 0, "int", 0, "uptrp", &_ := 0), _)
		}
		Delete() => DllCall("GdiPlus\GdipDeleteFont", "ptr", this)
		__Delete() {
			if this.ptr
				this.Delete()
		}
	}
	Class StringFormat {
		ptr := 0
		__New() => this.ptr := (DllCall("GdiPlus\GdipCreateStringFormat", "int", 0, "int", 0, "uptrp", &_ := 0), _)
		/**
		 * @param align
		 * *0: Near
		 * *1: Center
		 * *2: Far
		 * @returns {unset | Gdip.StringFormat}
		 */
		setAlignment(align) {
			if !this.ptr
				return unset
			return (DllCall("GdiPlus\GdipSetStringFormatAlign", "ptr", this, "int", align) ? unset : this)
		}
		/**
		 * @param align
		 * *0: Near
		 * *1: Center
		 * *2: Far
		 * @returns {unset | Gdip.StringFormat} 
		 */
		setLineAlignment(align) {
			if !this.ptr
				return unset
			return (DllCall("GdiPlus\GdipSetStringFormatLineAlign", "ptr", this, "int", align) ? unset : this)
		}
		/**
		 * @param flags 
		 * *StringFormatFlagsDirectionRightToLeft = 0x00000001
		 * *StringFormatFlagsDirectionVertical = 0x00000002
		 * *StringFormatFlagsNoFitBlackBox = 0x00000004
		 * *StringFormatFlagsDisplayFormatControl = 0x00000020
		 * *StringFormatFlagsNoFontFallback = 0x00000400
		 * *StringFormatFlagsMeasureTrailingSpaces = 0x00000800
		 * *StringFormatFlagsNoWrap = 0x00001000
		 * *StringFormatFlagsLineLimit = 0x00002000
		 * *StringFormatFlagsNoClip = 0x00004000
		 * @returns {unset | Gdip.StringFormat}
		 * *unset: failed
		 * *Gdip.StringFormat: success
		 */
		setFormatFlags(flags) {
			if !this.ptr
				return unset
			return (DllCall("GdiPlus\GdipSetStringFormatFlags", "ptr", this, "int", flags) ? unset : this)
		}
		/**
		 * @param trimming 
		 * *0: None
		 * *1: Character
		 * *2: Word
		 * *3: EllipsisCharacter
		 * *4: EllipsisWord
		 * *5: EllipsisPath
		 * @returns {unset | Gdip.StringFormat}
		 * *unset: failed
		 * *Gdip.StringFormat: success
		 */
		setTrimming(trimming) {
			if !this.ptr || trimming < 0 || trimming > 5
				return unset
			return (DllCall("GdiPlus\GdipSetStringFormatTrimming", "ptr", this, "int", trimming) ? unset : this)
		}
	}
	;?=======================
	;?======Structures=======
	;?=======================
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
	Class PointF {
		x: f32, y: f32
		__New(x := 0, y := 0) => (this.x := x, this.y := y)
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
		__New(biWidth?, biHeight?, biBitCount?) {
			if IsSet(biWidth)
				this.biWidth := biWidth
			if IsSet(biHeight)
				this.biHeight := biHeight
			if IsSet(biBitCount)
				this.biBitCount := biBitCount
			return this
		}
	}
}
;?=======================