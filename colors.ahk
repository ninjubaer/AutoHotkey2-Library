/************************************************************************
 * @description color functions
 * @file colors.ahk
 * @author ninju
 * @date 2024/05/27
 * @version 0.0.1
 ***********************************************************************/
/**
 * rgbToHex
 * @param r, g, b, a? or [r, g, b, a?]
 * @returns {String} hex color as String
 */
rgbToHex(args*) {
	if args[1] is Array
		args := args[1]
	if args.length = 4
		return Format("0x{:02X}{:02X}{:02X}{:02X}", args[4], args[1], args[2], args[3])
	return Format("0x{:02X}{:02X}{:02X}", args[1], args[2], args[3])
}
/**
 * hexToRgb
 * @param {String | Integer} hex 
 * @returns {Array} [r, g, b, a?]
 */
hexToRgb(hex) {
	hex := InStr(hex, "0x") ? SubStr(hex, 3) : InStr(hex, "#") ? SubStr(hex, 2) : hex
	if hex > 0xffffff
		return [(hex >> 16) & 0xff, (hex >> 8) & 0xff, hex & 0xff, hex >> 24]
	return [(hex >> 16) & 0xff, (hex >> 8) & 0xff, hex & 0xff]
}
rgbToBgr(rgb) => (rgb & 0xff000000) | (rgb & 0xff) << 16 | (rgb & 0xff00) | (rgb & 0xff0000) >> 16
bgrToRgb(bgr) => (bgr & 0xff000000) | (bgr & 0xff) << 16 | (bgr & 0xff00) | (bgr & 0xff0000) >> 16
/**
 * rgbToHSL
 * @param {Integer} rgb
 * @returns {String} HSL(h, s%, l%)
 */
rgbToHSL(rgb) {
    r := (rgb >> 16 & 0xFF) / 255, g := (rgb >> 8 & 0xFF) / 255, b := (rgb & 0xFF) / 255
    cmax := Max(r, g, b), cmin := Min(r, g, b), d := cmax - cmin
    h := (d = 0 ? 0
        : cmax = r ? Mod(((g - b) / d), 6)
            : cmax = g ? ((b - r) / d) + 2
                : ((r - g) / d) + 4) * 60
    l := (cmax + cmin) / 2, s := d = 0 ? 0 : d / (1 - Abs(2 * l - 1))
    return "HSL(" Round(h) "," Round(s * 100) "%," Round(l * 100) "%)"
}
