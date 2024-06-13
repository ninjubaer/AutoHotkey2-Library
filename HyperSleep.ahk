HyperSleep(ms) {
	static freq := (DllCall("QueryPerformanceFrequency", "int64p", &freq:=0), freq)
	DllCall("QueryPerformanceCounter", "int64p", &start:=0)
	while ((DllCall("QueryPerformanceCounter", "int64p", &end:=0), end) - start) < ms * freq / 1000 {
		switch {
			case (start + ms * freq / 1000 - end) > 320000: DllCall("Sleep", "uint", (start + ms * freq / 1000 - end) / 10000 - 17)
			case (start + ms * freq / 1000 - end) > 80000: DllCall("winmm.dll\timeBeginPeriod", "uint", 5), DllCall("Sleep", "uint", 1), DllCall("winmm.dll\timeEndPeriod", "uint", 5)
			case (start + ms * freq / 1000 - end) > 30000: DllCall("winmm.dll\timeBeginPeriod", "uint", 1), DllCall("Sleep", "uint", 1), DllCall("winmm.dll\timeEndPeriod", "uint", 1)
		}
	}
}
