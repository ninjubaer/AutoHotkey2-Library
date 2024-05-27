/************************************************************************
 * @description Thread class for AutoHotkey
 * @file Thread.ahk
 * @author ninju
 * @date 2024/05/25
 * @version 0.0.1
 ***********************************************************************/
#include <Console>
export Class Thread {
	__New(cb, args*) {
		this.callback := CallbackCreate(cb)
		if !(this.threadptr := DllCall("CreateThread", "ptr", 0, "uint", 0, "ptr", this.callback, "ptr", ObjPtrAddRef(args), "uint", 0, "ptrP", &tid := 0))
			throw Error("Failed to create thread")
		this.threadID := tid
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
	__Delete() => (this.ForceDelete(), this)
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
export Class ThreadPool {
	__New(min, max) {
		this.min:=min,this.max := max, this.queue := []
		this.ptr := DllCall("CreateThreadpool", "ptr", 0, "ptr")
		this.cleanupgroup := DllCall("CreateThreadpoolCleanupGroup", "ptr")
		DllCall("SetThreadpoolThreadMinimum", "ptr", this, "uint", min)
		DllCall("SetThreadpoolThreadMaximum", "ptr", this, "uint", max)
		TP_CALLBACK_ENVIRON := ThreadPool.TP_CALLBACK_ENVIRON()
		TP_CALLBACK_ENVIRON.Version := 3
		TP_CALLBACK_ENVIRON.Pool := this.ptr
		TP_CALLBACK_ENVIRON.CleanupGroup := this.cleanupgroup
		this.work := CallbackCreate(this.worker.Bind(this))
		this.workObj := DllCall("CreateThreadpoolWork", "ptr", this.work, "ptr", 0, "ptr", TP_CALLBACK_ENVIRON)
	}
	Class TP_CALLBACK_ENVIRON {
		Version: u32
		Pool: iptr
		CleanupGroup: iptr
		CleanupGroupCancelCallback: iptr
		RaceDll: iptr
		ActivationContext: iptr
		FinalizationCallback: iptr
		Flags: u32
		CallbackPriority: i32
		Size: u32 := ObjGetDataSize(this)
		__Enum(num) {
			static arr := ["Version", "Pool", "CleanupGroup", "CleanupGroupCancelCallback", "RaceDll", "ActivationContext", "FinalizationCallback", "Flags", "CallbackPriority", "Size"]
			i := 0
			return ((&x,&y?) {
				if ++i <= arr.Length
					return (num = 2 ? (x := arr[i], y := this.%arr[i]%) : (x := this.%arr[i]%), true)
				return false
			})
		}
	}
	worker() {
		Critical
		while (this.queue.length) {
			task := this.queue.RemoveAt(1)
			try task[1](task[2]*)
		}
	}
	enqueue(cb, args*) {
		this.queue.Push([cb, args])
		DllCall("SubmitThreadpoolWork", "ptr", this.workObj)
	}
	__Delete() {
		DllCall("CloseThreadpoolCleanupGroup", "ptr", this.cleanupgroup)
		DllCall("CloseThreadpool", "ptr", this.ptr)
		CallbackFree(this.work)
	}
	static lastError => DllCall("GetLastError", "uint")
}
export Sleep(ms) => DllCall("Sleep", "uint", ms)