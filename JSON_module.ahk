#Requires AutoHotkey v2.1-alpha.11+ 
_null := ComValue(1, 0), _true := ComValue(0xB, 1), _false := ComValue(0xB, 0)
export stringify(obj, indent := 1) {
	static CRLF := "`r`n"
	return d(obj)
	d(o, level := false) {
		Switch t := Type(o), 0 {
			case "string": return '"' StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(o, '\', '\\'), '"', '\"'), "`n", "\n"), "`r", "\r"), "`t", "\t"), "`b", "\b"), "`f", "\f"), "`v", "\v") '"'
			case "Integer", "Float": return o
			case "ComValue": return (o = _null ? "null" : o = _true ? "true" : o = _false ? "false" : "unknown")
			case "Array":
				out := "[" (indent !== false ? CRLF : "")
				for i, j in o
					out .= GetIndent(level + 1) d(j, level + 1) . "," . (indent !== false ? CRLF : "")
				return StrLen(out) > (indent !== false ? 3 : 1) ? SubStr(out, 1, indent !== false ? -3 : -1) . (indent !== false ? CRLF . GetIndent(level) : "") . "]" : "[]"
			default:
				out := "{" . (indent !== false ? CRLF : "")
				for i, j in t = "Map" || t = "Gui" ? o : o.OwnProps()
					out .= GetIndent(level + 1) . d(i, level + 1) . ":" . (indent !== false ? " " : "") . d(j, level + 1) . "," . (indent !== false ? CRLF : "")
				return StrLen(out) > (indent !== false ? 3 : 1) ? SubStr(out, 1, indent !== false ? -3 : -1) . (indent !== false ? CRLF . GetIndent(level) : "") . "}" : "{}"
		}
	}
	GetIndent(lvl) {
		if indent is Integer
			loop indent
				ind .= " "
		loop lvl
			indentOut .= ind ?? indent
		return IsSet(indentOut) && indent !== false ? indentOut : ""
	}
}
export parse(str, asMap := true, bool?) {
	static types := [
		["Number", "^\d+(\.\d*)?([eE][+-]?\d+)?"],
		["String", '^"(\\.|[^"\\])*"'],
		["true", "^(?i:true)"],
		["false", "^(?i:false)"],
		["null", "^(?i:null)"],
		["lBrace", "^\{"],
		["rBrace", "^\}"],
		["lBracket", "^\["],
		["rBracket", "^\]"],
		["comma", "^,"],
		["colon", "^:"],
		["whitespace", "^\s+"]
	]
	pos := 1, tokens := []
	While (pos < StrLen(str)) {
		for type in types {
			if (RegExMatch(SubStr(str, pos), type[2], &match)) {
				if type[1] != "whitespace"
					tokens.Push([type[1], match.0])
				pos += StrLen(match.0)
				continue 2
			}
		}
	}
	return pv(nextToken())
	nextToken() {
		static index := 1
		if index > tokens.Length
			return [false, false]
		return tokens[index++]
	}
	pv(token) {
		switch token[1], 0 {
			case "Number": return token[2] + 0
			case "String": return StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(SubStr(token[2], 2, -1), '\v', "`v"), '\f', "`f"), '\b', "`b"), '\t', "`t"), '\r', "`r"), '\n', "`n"), '\"', '"'), '\\', '\')
			case "true": return !(bool ?? false) ? true : _true
			case "false": return !(bool ?? false) ? false : _false
			case "null": return !(bool ?? false) ? "" : _null
			case "lBrace":
				obj := asMap ? Map() : {}
				if asMap
					obj.CaseSense := false
				loop {
					token := nextToken()
					if (token[1] == false)
						break
					if (token[1] != "String")
						throw TypeError("Expected string")
					key := pv(token)
					if (nextToken()[1] != "colon")
						throw TypeError("Expected colon")
					if asMap
						obj[key] := pv(nextToken())
					else
						obj.%key% := pv(nextToken())
					if (nextToken()[1] != "comma")
						break
				}
				return obj
			case "lBracket":
				arr := []
				loop {
					token := nextToken()
					if (token[1] == false)
						break
					arr.Push(pv(token))
					if (nextToken()[1] != "comma")
						break
				}
				return arr
		}
	}
}