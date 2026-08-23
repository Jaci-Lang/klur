--!strict
-- High performance Event Emitter and Observer pattern for KLUR

local Async = require("@klur/async")

export type Listener = (...any) -> ...any

export type EventEmitter = {
    on: (self: EventEmitter, event: string, listener: Listener) -> (() -> ()),
    once: (self: EventEmitter, event: string, listener: Listener) -> (() -> ()),
    off: (self: EventEmitter, event: string, listener: Listener) -> EventEmitter,
    emit: (self: EventEmitter, event: string, ...any) -> boolean,
    emitAsync: (self: EventEmitter, event: string, ...any) -> any,
    removeAllListeners: (self: EventEmitter, event: string?) -> EventEmitter,
    listeners: (self: EventEmitter, event: string) -> {Listener},
    listenerCount: (self: EventEmitter, event: string) -> number,
    eventNames: (self: EventEmitter) -> {string},
}

local EventEmitterImpl = {}
EventEmitterImpl.__index = EventEmitterImpl

function EventEmitterImpl.new(): EventEmitter
    local self = setmetatable({
        _events = {} :: {[string]: {Listener}},
    }, EventEmitterImpl)
    return (self :: any) :: EventEmitter
end

function EventEmitterImpl.on(self: any, event: string, listener: Listener): () -> ()
    if not self._events[event] then
        self._events[event] = {}
    end
    table.insert(self._events[event], listener)

    -- Return unsubscribe function for convenience
    return function()
        (self :: any):off(event, listener)
    end
end

function EventEmitterImpl.once(self: any, event: string, listener: Listener): () -> ()
    local unsub: any = nil
    local wrapper = function(...)
        if unsub then
            (unsub :: any)()
        end
        return (listener :: any)(...)
    end
    unsub = (self :: any):on(event, wrapper)
    return unsub
end

function EventEmitterImpl.off(self: any, event: string, listener: Listener): EventEmitter
    local list = self._events[event]
    if not list then return self end

    for i = #list, 1, -1 do
        if list[i] == listener then
            table.remove(list, i)
            break
        end
    end

    if #list == 0 then
        self._events[event] = nil
    end

    return self
end

function EventEmitterImpl.emit(self: any, event: string, ...: any): boolean
    local list = self._events[event]
    local wildcard = self._events["*"]

    if not list and not wildcard then
        return false
    end

    if list then
        local copy = table.clone(list)
        for _, fn in ipairs(copy) do
            (fn :: any)(...)
        end
    end

    if wildcard then
        local copyW = table.clone(wildcard)
        for _, fn in ipairs(copyW) do
            (fn :: any)(event, ...)
        end
    end

    return true
end

function EventEmitterImpl.emitAsync(self: any, event: string, ...: any): any
    local list = self._events[event]
    local wildcard = self._events["*"]

    if not list and not wildcard then
        return Async.resolve(false)
    end

    local args = {...}
    return Async.Promise.new(function(resolve: any, reject: any)
        local promises = {}

        if list then
            local copy = table.clone(list)
            for _, fn in ipairs(copy) do
                local p = Async.Promise.new(function(res: any, rej: any)
                    local ok, err = pcall(fn :: any, table.unpack(args))
                    if ok then res(nil) else rej(err) end
                end)
                table.insert(promises, p)
            end
        end

        if wildcard then
            local copyW = table.clone(wildcard)
            for _, fn in ipairs(copyW) do
                local p = Async.Promise.new(function(res: any, rej: any)
                    local ok, err = pcall(fn :: any, event, table.unpack(args))
                    if ok then res(nil) else rej(err) end
                end)
                table.insert(promises, p)
            end
        end

        Async.Promise.all(promises):then_(function()
            resolve(true)
        end):catch_(function(err: any)
            reject(err)
        end)
    end)
end

function EventEmitterImpl.removeAllListeners(self: any, event: string?): EventEmitter
    if event then
        self._events[event] = nil
    else
        self._events = {}
    end
    return self
end

function EventEmitterImpl.listeners(self: any, event: string): {Listener}
    return self._events[event] and table.clone(self._events[event]) or {}
end

function EventEmitterImpl.listenerCount(self: any, event: string): number
    return self._events[event] and #self._events[event] or 0
end

function EventEmitterImpl.eventNames(self: any): {string}
    local names = {}
    for k in pairs(self._events) do
        table.insert(names, k)
    end
    return names
end

local Events = {
    EventEmitter = EventEmitterImpl,
    new = EventEmitterImpl.new,
}

return Events
