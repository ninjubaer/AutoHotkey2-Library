/************************************************************************
 * @description Thread class for AutoHotkey
 * @file Thread.ahk
 * @author ninju
 * @date 2024/05/25
 * @version 0.0.1
 ***********************************************************************/

Class Thread {
	__New(cb, args*) {
		this.state := 0
		this.callback := CallbackCreate(this.threadProc.Bind(this, cb, args))
		if !(this.threadptr := DllCall("CreateThread", "ptr",0, "ptr",0,"ptr",this.callback, "ptr",ObjPtrAddRef(args), "uint",0, "ptrP", &tid:=0))
			throw Error("Failed to create thread")
		this.threadID := tid
	}
	join() {
		if this.threadptr {
			DllCall("WaitForSingleObject", "ptr", this.threadptr, "uint", 0xFFFFFFFF)
			DllCall("CloseHandle", "ptr", this.threadptr)
			this.threadptr := this.state := 0
		}
		return this
	}

	threadProc(cb, args) {
		this.state := 1
		(cb)(args*)
		try ObjRelease(ObjPtr(args))
		this.state := 0
	}
	attach() => (OnExit((*) => this.join(), -1), this)
	detach() => (OnExit((*) => this.ForceDelete(), -1), this)
	setTimeout(ms) => (SetTimer(this.ForceDelete.Bind(this), ms), this)
	__Delete() {
		this.Join()
	}
	pause() {
		static ThreadSuspended := 0
		if this.threadptr && ThreadSuspended ^= 1 {
			this.state := 2
			DllCall("SuspendThread", "ptr", this.threadptr)
		}
		else if this.threadptr {
			this.state := 1
			DllCall("ResumeThread", "ptr", this.threadptr)
		}
		return this
	}
	ForceDelete() {
		if this.threadptr {
			DllCall("TerminateThread", "ptr", this.threadptr, "uint", 0)
			DllCall("CloseHandle", "ptr", this.threadptr)
			this.threadptr := this.state := 0
		}
		return this
	}
	status {
		get => this.state
		set => (!value ? this.ForceDelete() : value = 1 && this.state = 2 ? this.pause() : value = 2 && this.state = 1 ? this.pause() : 0, this.state)
	}
	priority {
		get => this.threadptr ? DllCall("GetThreadPriority", "ptr", this.threadptr) : -1001
		set => (this.threadptr ? DllCall("SetThreadPriority", "ptr", this.threadptr, "int", value) : 0, Value)
	}
	description {
		set => (this.threadptr ? DllCall("SetThreadDescription", "ptr", this.threadptr, "str", value) : 0, Value)
		get => (this.threadptr ? DllCall("GetThreadDescription", "ptr", this.threadptr, "strp", &desc:="") : "", desc)
	}
}
/* Class ThreadPool extends Thread {
	__New(minAmount:=1, maxAmount?) {
		this.minAmount := minAmount, this.maxAmount := maxAmount ?? minAmount
		if this.minAmount > this.maxAmount
			throw Error("minAmount must be less than or equal to maxAmount")
		this.threads:=[], this.queue:=[]
		loop this.minAmount
			this.threads.push(Thread(this.threadPoolProc.Bind(this)))
	}
	threadPoolProc() {
		While !(this.threads.Length > this.minAmount) {
			While this.queue.Length {
				func := this.queue.RemoveAt(1)
				func.cb.call(func.args*)
			}
		}
	}
	append(cb, args*) {
		this.queue.push({cb:cb, args:args})
		sleep 50
		if this.threads.Length < this.maxAmount && this.queue.Length
			this.threads.push(Thread(this.threadPoolProc.Bind(this)))
	}
} */