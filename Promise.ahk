#include Threading.ahk
#Include Console.ahk
class Promise {
    status := 'pending', value := '', reason := '', hasCatch := false, onFulfilled := '', onRejected := '', onFinally := '', hasNext := false
    __New(executor) {
        ;? testing only
        this.DefineProp('__Delete', {Call: Console.log('Promise deleted'), type: 'method'})
        
        try this.thread := Thread((executor.MaxParams = 1) ? executor.Bind(this, resolve) : executor.Bind(this, resolve, reject))
        catch any as e {
            reject e
        }
        this.thread.OnComplete := OnThreadComplete
        OnThreadComplete() {
            if this.hasNext
                this.onFulfilled(this.value)
        }
        resolve(value := '') {
            if value is Promise
                return value.then(resolve, reject)
            this.status := 'fulfilled'
            this.value := value
        }
        reject(reason:='') {
            if (this.status != 'pending') 
                return
            this.status := 'rejected'
            this.reason := reason
            SetTimer(() {
                if (this.hasCatch)
                    this.onRejected(this.reason)
                else
                    throw this.reason
            }, -1)
        }
    }
    then(onFulfilled, onRejected?) {
        this.hasNext := true
        p2 := NewPromise(this, executor)
        return p2
        executor(resolve, reject) {
            if (this.status == 'fulfilled')
                onFulfilled(this.value)
            else if (this.status == 'rejected' && IsSet(onRejected))
                onRejected(this.reason)
            else if (this.status == 'pending') {
                this.callbacks.Push(onFulfilled)
                if (IsSet(onRejected))
                    this.onRejected := onRejected
            }
        }
        static NewPromise(OP, executor) {
            np := { base: Promise.Prototype, status: 'pending', value: '', reason: '', hasCatch: false, onFulfilled: (*)=>"", onRejected: (*)=>"", onFinally: (*)=>""}
            return np
        }
    }
    catch(onRejected) {
        if (this.status == 'rejected')
            onRejected(this.reason)
        else if (this.status == 'pending')
            this.onRejected := onRejected
    }
    finally(onFinally) {
        return this.then(() {
            onFinally(this.value)
            return this.value
        },
        () {
            onFinally(this.reason)
            throw this.reason
        })
    }
}


myPromise := Promise((resolve, reject) {
    resolve('Hello World')
}).then((value) {
    Console.log(value)
})