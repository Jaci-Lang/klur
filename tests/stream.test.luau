--!strict
local Test = require("@klur/test")
local Stream = require("@klur/stream")
local expect = Test.expect

Test.describe("Std: Streams & Pipelines", function()
    Test.it("should buffer and read chunks from ReadableStream", function()
        local r = Stream.Readable.new()
        r:push("Hello, ")
        r:push("World!")
        r:push(nil)

        expect(r:isEnded()).toBe(true)
        local all = r:readAll()
        expect(all).toBe("Hello, World!")
    end)

    Test.it("should sink chunks and format buffer in WritableStream", function()
        local w = Stream.Writable.new()
        w:write("chunk 1")
        w:write("chunk 2")
        w:end_()

        expect(w:isFinished()).toBe(true)
        expect(w:getBuffer()).toBe("chunk 1chunk 2")
    end)

    Test.it("should pipe from Readable to Writable stream", function()
        local r = Stream.fromBuffer("streaming data pipeline", 8)
        local w = Stream.Writable.new()

        r:pipe(w)

        expect(w:getBuffer()).toBe("streaming data pipeline")
        expect(w:isFinished()).toBe(true)
    end)
end)
