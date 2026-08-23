--!strict
local Test = require("@klur/test")
local Events = require("@klur/events")
local expect = Test.expect

Test.describe("Std: Events (EventEmitter)", function()
    Test.it("should register and emit sync events", function()
        local emitter = Events.new()
        local called = 0
        local receivedMsg = ""

        emitter:on("ping", function(msg)
            called += 1
            receivedMsg = msg
        end)

        local ok = emitter:emit("ping", "pong")
        expect(ok).toBe(true)
        expect(called).toBe(1)
        expect(receivedMsg).toBe("pong")
    end)

    Test.it("should unsubscribe via returned callback", function()
        local emitter = Events.new()
        local called = 0

        local unsub = emitter:on("data", function()
            called += 1
        end)

        emitter:emit("data")
        expect(called).toBe(1)

        unsub()
        emitter:emit("data")
        expect(called).toBe(1)
    end)

    Test.it("should handle once listeners only once", function()
        local emitter = Events.new()
        local count = 0

        emitter:once("connect", function()
            count += 1
        end)

        emitter:emit("connect")
        emitter:emit("connect")
        expect(count).toBe(1)
    end)

    Test.it("should support wildcard listeners", function()
        local emitter = Events.new()
        local seenEvents = {}

        emitter:on("*", function(eventName, val)
            table.insert(seenEvents, eventName .. ":" .. tostring(val))
        end)

        emitter:emit("foo", 123)
        emitter:emit("bar", 456)

        expect(#seenEvents).toBe(2)
        expect(seenEvents[1]).toBe("foo:123")
        expect(seenEvents[2]).toBe("bar:456")
    end)
end)
