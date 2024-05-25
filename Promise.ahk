;! not working yet
/************************************************************************
 * @description js like Promise implement in AutoHotkey
 * @file Promise.ahk
 * @author ninju
 * @date 2024/05/25
 * @version 0.0.1
 ***********************************************************************/
Class Promise {
	__New(executor) {
		this.state := 'pending', this.value := "", this.res := [], this.rej := []
		try (executor.MaxParams = 1 ? executor(resolve) : executor(resolve, reject))
		catch any as e
			reject(e)
		resolve(value) {
			if (this.state != 'pending')
				return
			this.state := 'fulfilled', this.value := value
			this.callHandlers()
		}
	}
	callHandlers() {
		if this.state = 'pending'
			return
		if this.state = 'fulfilled'
			for handler in this.res
				handler(this.value)
			else
				for handler in this.rej
					handler(this.value)
		this.res := [], this.rej := []
	}
	onResolve(cb) {
		this.res.push(cb)
		if this.state = 'fulfilled'
			this.callHandlers()
	}
	onReject(cb) {
		this.rej.push(cb)
		if this.state = 'rejected'
			this.callHandlers()
	}
	then(onFulfilled, onRejected := this.defaultReject) {
		np := Promise(executor)
		executor(resolve, reject) {
			switch this.state {
				case 'fulfilled':
					try (onFulfilled.MaxParams = 1 ? onFulfilled(this.value) : onFulfilled(this.value, resolve, reject))
					catch any as e
						reject(e)
				case 'rejected':
					try (onRejected.MaxParams = 1 ? onRejected(this.value) : onRejected(this.value, resolve, reject))
					catch any as e
						reject(e)
				default:


			}
		}
	}
	defaultReject() {
		throw this
	}
	catch(r) => this.then("", r)
}