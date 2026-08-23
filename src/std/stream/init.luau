--!strict
-- Stream abstractions, chunk processing, and pipelines for KLUR

local Events = require("@klur/events")

-- ============================================================================
-- ReadableStream
-- ============================================================================
export type ReadableStream = {
    read: (self: ReadableStream, size: number?) -> string?,
    readAll: (self: ReadableStream) -> string,
    pipe: (self: ReadableStream, dest: WritableStream) -> WritableStream,
    push: (self: ReadableStream, chunk: string?) -> (),
    on: (self: ReadableStream, event: string, listener: (...any) -> ()) -> (() -> ()),
    once: (self: ReadableStream, event: string, listener: (...any) -> ()) -> (() -> ()),
    isEnded: (self: ReadableStream) -> boolean,
}

local ReadableImpl = {}
ReadableImpl.__index = ReadableImpl

function ReadableImpl.new(): ReadableStream
    local emitter = Events.new()
    local self = setmetatable({
        _emitter = emitter,
        _chunks = {} :: {string},
        _ended = false,
    }, ReadableImpl)
    return (self :: any) :: ReadableStream
end

function ReadableImpl.push(self: any, chunk: string?)
    if chunk == nil then
        self._ended = true
        self._emitter:emit("end")
        return
    end
    local ch: string = chunk :: string
    table.insert(self._chunks, ch)
    self._emitter:emit("data", ch)
end

function ReadableImpl.read(self: any, size: number?): string?
    local chunks = self._chunks :: {string}
    if #chunks == 0 then
        return nil
    end
    if not size then
        return table.remove(chunks, 1)
    end
    local first = chunks[1]
    if #first <= (size :: number) then
        return table.remove(chunks, 1)
    else
        local chunk = first:sub(1, size :: number)
        chunks[1] = first:sub((size :: number) + 1)
        return chunk
    end
end

function ReadableImpl.readAll(self: any): string
    local chunks = self._chunks :: {string}
    local result = table.concat(chunks)
    self._chunks = {}
    return result
end

function ReadableImpl.pipe(self: any, dest: WritableStream): WritableStream
    local chunks = self._chunks :: {string}
    while #chunks > 0 do
        local chunk = table.remove(chunks, 1)
        if chunk then
            dest:write(chunk)
        end
    end

    if self._ended then
        dest:end_()
        return dest
    end

    self:on("data", function(chunk)
        dest:write(chunk)
    end)
    self:on("end", function()
        dest:end_()
    end)
    return dest
end

function ReadableImpl.on(self: any, event: string, listener: (...any) -> ()): () -> ()
    return self._emitter:on(event, listener)
end

function ReadableImpl.once(self: any, event: string, listener: (...any) -> ()): () -> ()
    return self._emitter:once(event, listener)
end

function ReadableImpl.isEnded(self: any): boolean
    return self._ended == true
end

-- ============================================================================
-- WritableStream
-- ============================================================================
export type WritableStream = {
    write: (self: WritableStream, chunk: string) -> boolean,
    end_: (self: WritableStream, chunk: string?) -> (),
    on: (self: WritableStream, event: string, listener: (...any) -> ()) -> (() -> ()),
    once: (self: WritableStream, event: string, listener: (...any) -> ()) -> (() -> ()),
    getBuffer: (self: WritableStream) -> string,
    isFinished: (self: WritableStream) -> boolean,
}

local WritableImpl = {}
WritableImpl.__index = WritableImpl

function WritableImpl.new(sink: ((chunk: string) -> ())?): WritableStream
    local emitter = Events.new()
    local self = setmetatable({
        _emitter = emitter,
        _sink = sink,
        _buffer = {} :: {string},
        _finished = false,
    }, WritableImpl)
    return (self :: any) :: WritableStream
end

function WritableImpl.write(self: any, chunk: string): boolean
    if self._finished then
        error("Cannot write to stream after end() has been called")
    end
    table.insert(self._buffer, chunk)
    if self._sink then
        (self._sink :: any)(chunk)
    end
    self._emitter:emit("data", chunk)
    return true
end

function WritableImpl.end_(self: any, chunk: string?)
    if chunk then
        (self :: any):write(chunk)
    end
    self._finished = true
    self._emitter:emit("finish")
end

function WritableImpl.on(self: any, event: string, listener: (...any) -> ()): () -> ()
    return self._emitter:on(event, listener)
end

function WritableImpl.once(self: any, event: string, listener: (...any) -> ()): () -> ()
    return self._emitter:once(event, listener)
end

function WritableImpl.getBuffer(self: any): string
    return table.concat(self._buffer)
end

function WritableImpl.isFinished(self: any): boolean
    return self._finished == true
end

-- ============================================================================
-- Stream Helpers
-- ============================================================================
local function fromBuffer(data: string, chunkSize: number?): ReadableStream
    local stream = ReadableImpl.new()
    local size = chunkSize or 1024
    local pos = 1
    local len = #data

    while pos <= len do
        local chunk = data:sub(pos, pos + size - 1)
        stream:push(chunk)
        pos += size
    end
    stream:push(nil)
    return stream
end

local function pipeline(source: ReadableStream, destination: WritableStream)
    source:pipe(destination)
end

local Stream = {
    Readable = ReadableImpl,
    Writable = WritableImpl,
    fromBuffer = fromBuffer,
    pipeline = pipeline,
}

return Stream
