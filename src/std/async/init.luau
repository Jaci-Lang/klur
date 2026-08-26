--!strict
-- Asynchronous Programming, Promises, and Concurrency for KLUR

local Async = {}

export type PromiseStatus = "pending" | "fulfilled" | "rejected"

export type Promise<T> = {
    status: PromiseStatus,
    value: T?,
    error: any?,
    andThen: (self: any, onFulfilled: ((T) -> any)?, onRejected: ((any) -> any)?) -> any,
    then_: (self: any, onFulfilled: ((T) -> any)?, onRejected: ((any) -> any)?) -> any,
    catch_: (self: any, onRejected: (any) -> any) -> any,
    finally_: (self: any, onFinally: () -> ()) -> any,
    await: (self: any) -> (boolean, any),
}

local PromiseObj = {}
PromiseObj.__index = PromiseObj

local function adopt(value: any, resolve: (any) -> (), reject: (any) -> ()): boolean
    if type(value) ~= "table" then
        return false
    end

    local foreignThen = value["then"]
    if type(foreignThen) == "function" then
        local ok, err = pcall(foreignThen, value, resolve, reject)
        if not ok then reject(err) end
        return true
    end

    local andThen = value.andThen
    if type(andThen) == "function" then
        local ok, err = pcall(andThen, value, resolve, reject)
        if not ok then reject(err) end
        return true
    end

    return false
end

function Async.promise<T>(executor: (resolve: (T) -> (), reject: (any) -> ()) -> ()): Promise<T>
    local self = setmetatable({
        status = "pending" :: PromiseStatus,
        value = nil,
        error = nil,
        _fulfilledCallbacks = {} :: { (any) -> () },
        _rejectedCallbacks = {} :: { (any) -> () },
        _thread = nil :: thread?,
    }, PromiseObj)

    local resolve: (any) -> ()
    local reject: (any) -> ()

    reject = function(err: any)
        if self.status ~= "pending" then return end
        self.status = "rejected"
        self.error = err
        for _, cb in ipairs(self._rejectedCallbacks) do
            cb(err)
        end
        if self._thread then
            task.spawn(self._thread, false, err)
            self._thread = nil
        end
    end

    resolve = function(val: any)
        if self.status ~= "pending" then return end
        if val == self then
            reject("Promise cannot resolve itself")
            return
        end
        if adopt(val, resolve, reject) then return end
        self.status = "fulfilled"
        self.value = val
        for _, cb in ipairs(self._fulfilledCallbacks) do
            cb(val)
        end
        if self._thread then
            task.spawn(self._thread, true, val)
            self._thread = nil
        end
    end

    local ok, err = pcall(executor, resolve, reject)
    if not ok then
        reject(err)
    end

    return (self :: any) :: Promise<T>
end

function PromiseObj.andThen(self: any, onFulfilled: any?, onRejected: any?): any
    return Async.promise(function(resolve, reject)
        local function handleFulfilled(val: any)
            if onFulfilled then
                local ok, res = pcall(onFulfilled, val)
                if ok then resolve(res) else reject(res) end
            else
                resolve(val)
            end
        end

        local function handleRejected(err: any)
            if onRejected then
                local ok, res = pcall(onRejected, err)
                if ok then resolve(res) else reject(res) end
            else
                reject(err)
            end
        end

        if self.status == "fulfilled" then
            task.defer(handleFulfilled, self.value)
        elseif self.status == "rejected" then
            task.defer(handleRejected, self.error)
        else
            table.insert(self._fulfilledCallbacks, handleFulfilled)
            table.insert(self._rejectedCallbacks, handleRejected)
        end
    end)
end

PromiseObj.then_ = PromiseObj.andThen

function PromiseObj.catch_(self: any, onRejected: any): any
    return (self :: any):andThen(nil, onRejected)
end

function PromiseObj.finally_(self: any, onFinally: any): any
    return (self :: any):andThen(
        function(val: any)
            onFinally()
            return val
        end,
        function(err: any)
            onFinally()
            error(err)
        end
    )
end

PromiseObj["await"] = function(self: any): (boolean, any)
    if self.status == "fulfilled" then
        return true, self.value
    elseif self.status == "rejected" then
        return false, self.error
    end

    local currentThread = coroutine.running()
    self._thread = currentThread
    return coroutine.yield()
end

function Async.resolve<T>(val: T): Promise<T>
    return Async.promise(function(resolve)
        resolve(val)
    end)
end

function Async.reject<T>(err: any): Promise<T>
    return Async.promise(function(_, reject)
        reject(err)
    end)
end

function Async.all(promises: {any}): any
    return Async.promise(function(resolve, reject)
        if #promises == 0 then
            resolve({})
            return
        end

        local results = table.create(#promises)
        local remaining = #promises

        for i, p in ipairs(promises) do
            local function fulfilled(val: any)
                results[i] = val
                remaining -= 1
                if remaining == 0 then
                    resolve(results)
                end
            end
            if not adopt(p, fulfilled, reject) then
                fulfilled(p)
            end
        end
    end)
end

function Async.race(promises: {any}): any
    return Async.promise(function(resolve, reject)
        for _, p in ipairs(promises) do
            if not adopt(p, resolve, reject) then
                resolve(p)
            end
        end
    end)
end

function Async.sleep(seconds: number): number
    return task.wait(seconds)
end

export type RetryOptions = {
    maxAttempts: number?,
    delay: number?,
    delayMs: number?,
    backoff: number?,
    backoffFactor: number?,
}

function Async.retry(fn: () -> any, optionsOrMaxAttempts: (RetryOptions | number)?, delayMs: number?, backoffFactor: number?): any
    local max = 3
    local delay = 0.1
    local backoff = 2

    if type(optionsOrMaxAttempts) == "table" then
        local opts = optionsOrMaxAttempts :: RetryOptions
        max = opts.maxAttempts or max
        if opts.delay then
            delay = opts.delay
        elseif opts.delayMs then
            delay = opts.delayMs / 1000
        end
        backoff = opts.backoff or opts.backoffFactor or backoff
    elseif type(optionsOrMaxAttempts) == "number" then
        max = optionsOrMaxAttempts
        if delayMs then delay = delayMs / 1000 end
        if backoffFactor then backoff = backoffFactor end
    end

    local lastErr = nil
    for attempt = 1, max do
        local ok, res = pcall(fn)
        if ok then
            return res
        end
        lastErr = res
        if attempt < max then
            Async.sleep(delay)
            delay = delay * backoff
        end
    end
    error("Retry failed after " .. max .. " attempts: " .. tostring(lastErr))
end

Async.Promise = {
    new = Async.promise,
    resolve = Async.resolve,
    reject = Async.reject,
    all = Async.all,
    race = Async.race,
}

return Async
