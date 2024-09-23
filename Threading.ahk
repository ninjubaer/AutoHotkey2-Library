/************************************************************************
 * @description Thread class for AutoHotkey
 * @file Thread.ahk
 * @author ninju
 * @date 2024/09/23
 * @version 0.0.2
 ***********************************************************************/
; Use #MaxThreads directive to increase the number of threads allowed
Class Thread {
	__New(cb, args*) {
		this.completed := false, this.OnComplete := unset
		this.callback := CallbackCreate(Callback.Bind(this, cb, args*))
		if !(this.threadptr := DllCall("CreateThread", "ptr", 0, "uint", 0, "ptr", this.callback, "ptr", ObjPtrAddRef(args), "uint", 0, "ptrP", &tid := 0))
			throw Error("Failed to create thread")
		this.DefineProp("__Delete", {Call: this.ForceDelete})
		this.threadID := tid
		Callback(self, cb, args*) {
			cb.Call(args*)
			self.completed := true
			try self.OnComplete?.Call()
		}
	}
	join() {
		if this.threadptr {
			DllCall("WaitForSingleObject", "ptr", this.threadptr, "uint", 0xFFFFFFFF)
			DllCall("CloseHandle", "ptr", this.threadptr)
			this.threadptr := 0
		}
		return this
	}
	attach() => (OnExit((*) => this.join(), -1), this)
	detach() => (OnExit((*) => this.ForceDelete(), -1), this)
	setTimeout(ms) => (SetTimer(this.ForceDelete.Bind(this), ms), this)
	pause() {
		static ThreadSuspended := 0
		if this.threadptr && ThreadSuspended ^= 1 {
			DllCall("SuspendThread", "ptr", this.threadptr)
		}
		else if this.threadptr {
			DllCall("ResumeThread", "ptr", this.threadptr)
		}
		return this
	}
	ForceDelete() {
		CallbackFree(this.callback)
		if this.threadptr {
			DllCall("TerminateThread", "ptr", this.threadptr, "uint", 1)
			DllCall("CloseHandle", "ptr", this.threadptr)
			this.threadptr := 0
		}
		return this
	}
	priority {
		get => this.threadptr ? DllCall("GetThreadPriority", "ptr", this.threadptr) : -1001
		set => (this.threadptr ? DllCall("SetThreadPriority", "ptr", this.threadptr, "int", value) : 0, Value)
	}
	description {
		set => (this.threadptr ? DllCall("SetThreadDescription", "ptr", this.threadptr, "str", value) : 0, Value)
		get => (this.threadptr ? DllCall("GetThreadDescription", "ptr", this.threadptr, "strp", &desc := "") : "", desc)
	}
}
