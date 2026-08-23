--!strict
local Test = require("@klur/test")
local Collections = require("@klur/collections")
local expect = Test.expect

Test.describe("Std: Collections", function()
    Test.it("should perform Queue FIFO operations correctly", function()
        local q = Collections.Queue.new()
        expect(q:isEmpty()).toBe(true)
        expect(q:size()).toBe(0)

        q:push("a")
        q:push("b")
        q:push("c")

        expect(q:size()).toBe(3)
        expect(q:peek()).toBe("a")

        expect(q:pop()).toBe("a")
        expect(q:pop()).toBe("b")
        expect(q:pop()).toBe("c")
        expect(q:pop()).toBeNil()
        expect(q:isEmpty()).toBe(true)
    end)

    Test.it("should perform Stack LIFO operations correctly", function()
        local s = Collections.Stack.new()
        expect(s:isEmpty()).toBe(true)

        s:push(10)
        s:push(20)
        s:push(30)

        expect(s:size()).toBe(3)
        expect(s:peek()).toBe(30)

        expect(s:pop()).toBe(30)
        expect(s:pop()).toBe(20)
        expect(s:pop()).toBe(10)
        expect(s:pop()).toBeNil()
    end)

    Test.it("should perform Set uniqueness operations", function()
        local set = Collections.Set.new({"apple", "banana"})
        expect(set:size()).toBe(2)
        expect(set:has("apple")).toBe(true)
        expect(set:has("orange")).toBe(false)

        local added = set:add("orange")
        expect(added).toBe(true)
        expect(set:size()).toBe(3)

        local readded = set:add("apple")
        expect(readded).toBe(false)
        expect(set:size()).toBe(3)

        set:delete("banana")
        expect(set:has("banana")).toBe(false)
        expect(set:size()).toBe(2)
    end)

    Test.it("should evict least recently used entries in LRUCache", function()
        local cache = Collections.LRUCache.new(3)
        cache:set("a", 1)
        cache:set("b", 2)
        cache:set("c", 3)

        expect(cache:size()).toBe(3)
        expect(cache:get("a")).toBe(1) -- Access "a", making "b" the LRU

        cache:set("d", 4) -- Evicts "b"

        expect(cache:has("b")).toBe(false)
        expect(cache:has("a")).toBe(true)
        expect(cache:has("c")).toBe(true)
        expect(cache:has("d")).toBe(true)
        expect(cache:size()).toBe(3)
    end)
end)
