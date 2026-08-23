--!strict
-- Asynchronous Programming, Promises, and Concurrency for KLUR

local Async = {}

export type PromiseStatus = "pending" | "fulfilled" | "rejected"

export type Promise<T> = {
    status: PromiseStatus,
    value: T?,
    error: any?,
    then_: (self: any, onFulfilled: ((T) -> any)?, onRejected: ((any) -> any)?) -> any,
    catch_: (self: any, onRejected: (any) -> any) -> any,
    finally_: (self: any, onFinally: () -> ()) -> any,
    await: (self: any) -> (boolean, any),
}

local PromiseObj = {}
PromiseObj.__index = PromiseObj

function Async.promise<T>(executor: (resolve: (T) -> (), reject: (any) -> ()) -> ()): Promise<T>
    local self = setmetatable({
        status = "pending" :: PromiseStatus,
        value = nil,
        error = nil,
        _fulfilledCallbacks = {},
        _rejectedCallbacks = {},
        _thread = nil,
    }, PromiseObj)

    local function resolve(val: any)
        if self.status ~= "pending" then return end
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

    local function reject(err: any)
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

    task.spawn(function()
        local ok, err = pcall(executor, resolve, reject)
        if not ok then
            reject(err)
        end
    end)

    return self :: any
end

function PromiseObj:then_(onFulfilled, onRejected)
    return Async.promise(function(resolve, reject)
        local function handleFulfilled(val)
            if onFulfilled then
                local ok, res = pcall(onFulfilled, val)
                if ok then resolve(res) else reject(res) end
            else
                resolve(val)
            end
        end

        local function handleRejected(err)
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

function PromiseObj:catch_(onRejected)
    return self:then_(nil, onRejected)
end

function PromiseObj:finally_(onFinally)
    return self:then_(
        function(val) onFinally(); return val end,
        function(err) onFinally(); error(err) end
    )
end

function PromiseObj:await_()
    if self.status == "fulfilled" then
        return true, self.value
    elseif self.status == "rejected" then
        return false, self.error
    end

    self._thread = coroutine.running()
    local ok, res = coroutine.yield()
    return ok, res
end

PromiseObj.await = PromiseObj.await_

function Async.resolve<T>(val: T): Promise<T>
    return Async.promise(function(resolve) resolve(val) end)
end

function Async.reject(err: any): Promise<any>
    return Async.promise(function(_, reject) reject(err) end)
end

function Async.all(promises: {Promise<any>}): Promise<{any}>
    return Async.promise(function(resolve, reject)
        if #promises == 0 then
            resolve({})
            return
        end
        local results = {}
        local pending = #promises
        for i, p in ipairs(promises) do
            p:then_(function(val)
                results[i] = val
                pending = pending - 1
                if pending == 0 then
                    resolve(results)
                end
            end, function(err)
                reject(err)
            end)
        end
    end)
end

function Async.sleep(seconds: number)
    if task and task.wait then
        task.wait(seconds)
    elseif task and task.sleep then
        task.sleep(seconds)
    else
        local start = os.clock()
        while os.clock() - start < seconds do end
    end
end

function Async.retry<T>(fn: () -> T, opts: {maxAttempts: number?, delay: number?, backoff: number?}?): T
    local maxAttempts = (opts and opts.maxAttempts) or 3
    local delay = (opts and opts.delay) or 0.5
    local backoff = (opts and opts.backoff) or 2.0

    local lastErr: any = nil
    for attempt = 1, maxAttempts do
        local ok, res = pcall(fn)
        if ok then
            return res
        end
        lastErr = res
        if attempt < maxAttempts then
            Async.sleep(delay)
            delay = delay * backoff
        end
    end
    error("Retry failed after " .. maxAttempts .. " attempts: " .. tostring(lastErr))
end

function Async.pLimit(concurrency: number)
    local queue = {}
    local active = 0

    local function next()
        if active < concurrency and #queue > 0 then
            active = active + 1
            local item = table.remove(queue, 1)
            task.spawn(function()
                local ok, res = pcall(item.fn)
                active = active - 1
                if ok then item.resolve(res) else item.reject(res) end
                next()
            end)
        end
    end

    return function<T>(fn: () -> T): Promise<T>
        return Async.promise(function(resolve, reject)
            table.insert(queue, { fn = fn, resolve = resolve, reject = reject })
            next()
        end)
    end
end

return Async
