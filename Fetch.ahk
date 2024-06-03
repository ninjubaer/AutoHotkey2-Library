#Include Promise.ahk
#Include JSON.ahk
Fetch(url, options) {
	Critical
	whr := ComObject("WinHttp.WinHttpRequest.5.1")
	whr.Open(options.method ?? "GET", url, options.async ?? true)
	For i in options.headers ?? []
		whr.SetRequestHeader(i[1], i[2])
	whr.Send(options.HasProp("body") ? IsObject(options.body) ? JSON.Stringify(options.body) : options.body : "")
	return Promise((resolve, reject) {
		whr.WaitForResponse()
		if (whr.Status == 200)
			resolve(whr.ResponseText)
		else if (whr.Status == 204)
			resolve(whr.Status)
		else
			reject(whr.Status)
		})
}
whurl:="https://discord.com/api/webhooks/1207367089334124596/jZKg5gDnjdvHXQ4V0UZBYjzdlPL1MBOFSoJKarYOPp0pslJXSypvAU-UTrrZ3kwkapuK"
Fetch(whurl, {method: "POST", headers: [["Content-Type", "application/json"]], body:{content: "Hello, World!"}})
	.then(Resp => MsgBox(Resp))
	.catch(Err => MsgBox(Err))