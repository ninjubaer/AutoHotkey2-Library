import AHK
HyperSleep(ms) {
	static freq := (DllCall("QueryPerformanceFrequency", "int64p", &freq := 0), freq)
	DllCall("QueryPerformanceCounter", "int64p", &start := 0), end := start + ms * freq / 1000, now := start
	while (now < end) {
		if (end - now > 200000)
			Sleep((end - now) / freq * 1000 - 15)
		else if (end - now > 20000)
			DllCall("timeBeginPeriod", "uint", 1), DllCall("Sleep", "uint", 1), DllCall("timeEndPeriod", "uint", 1)
		DllCall("QueryPerformanceCounter", "int64p", &now := 0)
	}
}