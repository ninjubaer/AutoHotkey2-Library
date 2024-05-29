class Timer {
	static __New() {
		this.freq := (DllCall("QueryPerformanceFrequency", "int64p", &freq := 0), freq)
		this.count := 1
	}
	static __Call(function, args*) {
		DllCall("QueryPerformanceCounter", "int64p", &s:=0)
		loop this.count
			function.Call(args*)
		DllCall("QueryPerformanceCounter", "int64p", &e:=0)
		return (e-s) * 1000000 / this.freq
	}
	static compare(args*) {
		for i,j in args {
			this.t%i% := this.__Call( j* )
			out .= j[1].name " ➔ " this.t%i%/this.count " µs per iteration (" this.t%i%/this.count / 1000 "ms)`n"
		}
		MsgBox out
	}
}