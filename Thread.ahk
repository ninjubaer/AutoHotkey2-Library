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
		ObjRelease(ObjPtr(args))
		this.state := 0
	}
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
