Class Date {
	__New(timestring) {
		this.timestring := timestring
	}
	Call() {
		return this.timestring
	}
	AddTime(time) {
		switch {
			case RegExMatch(time, "^(\d+)$", &m), RegExMatch(time, "i)(\d+)(s|secs?|seconds?)",&m): return (this.timestring := DateAdd(this.timestring, m.1, 'Seconds'), this)
			case RegExMatch(time, "i)(\d+)(m|mins?|minutes?)", &m): return (this.timestring := DateAdd(this.timestring, m.1, 'Minutes'), this)
			case RegExMatch(time, "i)(\d+)(h|hours?)", &m): return (this.timestring := DateAdd(this.timestring, m.1, 'Hours'), this)
			case RegExMatch(time, "i)(\d+)(d|days?)", &m): return (this.timestring := DateAdd(this.timestring, m.1, 'Days'), this)
			case RegExMatch(time, "i)(\d+)(w|weeks?)", &m): return (this.timestring := DateAdd(this.timestring, m.1, 'Weeks'), this)
			case RegExMatch(time, "i)(\d+)(months?)", &m): return (this.timestring := DateAdd(this.timestring, m.1, 'Months'), this)
			case RegExMatch(time, "i)(\d+)(y|years?)", &m): return (this.timestring := DateAdd(this.timestring, m.1, 'Years'), this)
		}
	}
	SubTime(time) {
		switch {
			case RegExMatch(time, "^(\d+)$", &m), RegExMatch(time, "i)(\d+)(s|secs?|seconds?)",&m): return (this.timestring := DateAdd(this.timestring, -m.1, 'Seconds'), this)
			case RegExMatch(time, "i)(\d+)(m|mins?|minutes?)", &m): return (this.timestring := DateAdd(this.timestring, -m.1, 'Minutes'), this)
			case RegExMatch(time, "i)(\d+)(h|hours?)", &m): return (this.timestring := DateAdd(this.timestring, -m.1, 'Hours'), this)
			case RegExMatch(time, "i)(\d+)(d|days?)", &m): return (this.timestring := DateAdd(this.timestring, -m.1, 'Days'), this)
			case RegExMatch(time, "i)(\d+)(w|weeks?)", &m): return (this.timestring := DateAdd(this.timestring, -m.1, 'Weeks'), this)
			case RegExMatch(time, "i)(\d+)(months?)", &m): return (this.timestring := DateAdd(this.timestring, -m.1, 'Months'), this)
			case RegExMatch(time, "i)(\d+)(y|years?)", &m): return (this.timestring := DateAdd(this.timestring, -m.1, 'Years'), this)
		}
	}
	toUnix() {
		return DateDiff(this.timestring, 19700101000000, "Seconds")
	}
	static now() {
		return this(A_NowUTC)
	}
	Format(format?) {
		return FormatTime(this.timestring, format?)
	}
	toDiscord(option := "t") {
		return "<t:" this.toUnix() ":" option ">"
	}
	static fromUnix(unix) {
		return this(DateAdd(19700101000000, unix, "Seconds"))
	}
	static formatSeconds(seconds) {
		hours := Format("{:02}",Floor(seconds / 3600))
		minutes := Format("{:02}",Floor((seconds - hours * 3600) / 60))
		seconds := Format("{:02}",seconds - hours * 3600 - minutes * 60)
		return (hours ? hours ":" : "") . (minutes ? minutes ":" : hours ? "00:" : "") . seconds
	}
}