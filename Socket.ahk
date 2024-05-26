#Requires AutoHotkey v2.1-alpha.11+ 
#SingleInstance Force
import JSON_module as JSON
Class Socket {
	static msgNum := 0x6969
	static FD_READ := 0x01, FD_ACCEPT := 0x08, FD_CLOSE := 0x32
	__New(eventObj,socket := -1) {
		if (this.IPPROTO = -1)
			Throw Error("Start with SocketTCP or SocketUDP")
		this.eventObj := eventObj
		#DllLoad "ws2_32.dll"
		WSADATA := Buffer(394 + A_PtrSize, 0)
		if err := DllCall("ws2_32\WSAStartup","ushort", 0x202, "ptr", WSADATA,) ; 0x202 = Winsock version 2.2
			Throw OSError(err)
		if NumGet(WSADATA, 2, 'ushort') != 0x202
			Throw Error("Winsock version 2.2 not available")
		this.sock := socket
	}
	closeSocket(){
		if (DllCall("ws2_32\closesocket", "ptr", this.sock) = -1)
			Throw OSError(Socket.lastError)
	}
	__Delete() => DllCall("ws2_32\WSACleanup")
	static lastError => DllCall("ws2_32\WSAGetLastError")
	static htons(port) {
		if !o:=DllCall("ws2_32\htons", "ushort", port)
			Throw OSError(Socket.lastError)
		return o
	}
	Bind(host, port) {
		if this.sock != -1
			Throw Error("Socket already exists")
		this.sock := DllCall("ws2_32\socket", "int", this.IPPROTO, "int", 1, "int", 0)
		if (DllCall("ws2_32\inet_addr", "str", host) = -1) || !RegExMatch(host, "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$")
			Throw Error("Invalid IP address")
		addr := Buffer(16, 0)
		NumPut("ushort", 2, addr) ; AF_INET
		NumPut("ushort", Socket.htons(port), addr, 2)
		NumPut("uint", (host = "0.0.0.0" ? 0 : DllCall("ws2_32\inet_addr", "str", host)), addr, 4)
		if (DllCall("ws2_32\bind", "ptr", this.sock, "ptr", addr, "int", 16) = -1)
			Throw OSError(Socket.lastError)
	}
	listen(backlog := 5) {
		if (DllCall("ws2_32\listen", "ptr", this.sock, "int", backlog) = -1)
			Throw OSError(Socket.lastError)
		evFlags := 0
		if this.eventObj.HasProp('recv')
			evFlags |= Socket.FD_READ
		if this.eventObj.HasProp('accept')
			evFlags |= Socket.FD_ACCEPT
		if this.eventObj.HasProp('disconnect')
			evFlags |= Socket.FD_CLOSE
		this.asyncSelect(evFlags)
		OnMessage(Socket.msgNum, this.OnMessage.Bind(this))
	}
	OnMessage(wParam, lParam, msg, hwnd) {
		if msg != Socket.msgNum
			return
		if (lParam & Socket.FD_READ) && this.eventObj.HasProp('recv')
			this.eventObj.recv.call(this)
		if (lParam & Socket.FD_ACCEPT) && this.eventObj.HasProp('accept')
			this.eventObj.accept.call(this)
		if (lParam & Socket.FD_CLOSE) && this.eventObj.HasProp('disconnect')
			this.eventObj.disconnect.call(this)
	}
	asyncSelect(event) {
		if DllCall("ws2_32\WSAAsyncSelect", "ptr", this.sock
			, "ptr", A_ScriptHwnd
			, "uint", Socket.msgNum
			, "uint", event)
		Throw OSError(Socket.lastError)
	}
	accept() {
		if (sock := DllCall("ws2_32\accept", "ptr", this.sock, "ptr", 0, "ptr", 0))
			Throw OSError(Socket.lastError)
		return 
	}
} 
Class SocketTCP extends Socket {
	static IPPROTO := 6
}
Persistent
s:=SocketTCP({
	recv: (self){
		msgbox 'recv'
	},
	accept: (self){
		
	},
	disconnect: (self){
		msgbox 'disconnect'
	}
})
s.Bind('0.0.0.0', 6969)
s.listen()
msgbox 'listening...'
ExitApp