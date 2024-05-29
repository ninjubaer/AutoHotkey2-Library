#Requires AutoHotkey v2.1-alpha.11+
import AHK
import JSON_module as JSON
export MsgBox(text?, title?, options?) {
	ahk.msgbox(!IsSet(text) ? unset : IsObject(text) ? JSON.stringify(text) : text, title?, options?)
}
