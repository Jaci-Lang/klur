local Test = require("@klur/test")
local Async = require("@klur/async")
local expect = Test.expect

Test.describe("Std: Async & Promises", function()
    Test.it("should create and resolve promises", function()
        local p = Async.promise(function(resolve)
            resolve("resolved value")
        end)
        local ok, val = p:await()
        expect(ok).toBe(true)
        expect(val).toBe("resolved value")
    end)

    Test.it("should create and reject promises", function()
        local p = Async.promise(function(_, reject)
            reject("rejected error")
        end)
        local ok, err = p:await()
        expect(ok).toBe(false)
        expect(err).toBe("rejected error")
    end)

    Test.it("should chain then handlers", function()
        local p = Async.resolve(10):andThen(function(n)
            return n * 2
        end):andThen(function(n)
            return n + 5
        end)
        local ok, val = p:await()
        expect(ok).toBe(true)
        expect(val).toBe(25)
    end)

    Test.it("should assimilate foreign thenables", function()
        local thenable = {
            ["then"] = function(_, resolve)
                resolve("foreign value")
            end,
        }
        local ok, value = Async.resolve(thenable):await()
        expect(ok).toBe(true)
        expect(value).toBe("foreign value")
    end)

    Test.it("should resolve Async.all", function()
        local p1 = Async.resolve(1)
        local p2 = Async.resolve(2)
        local p3 = Async.resolve(3)
        local all = Async.all({p1, p2, p3})
        local ok, results = all:await()
        expect(ok).toBe(true)
        expect(#results).toBe(3)
        expect(results[1]).toBe(1)
        expect(results[2]).toBe(2)
        expect(results[3]).toBe(3)
    end)

    Test.it("should retry operations until success", function()
        local count = 0
        local res = Async.retry(function()
            count = count + 1
            if count < 3 then
                error("temporary failure")
            end
            return "success!"
        end, { maxAttempts = 5, delay = 0.01, backoff = 1 })
        expect(res).toBe("success!")
        expect(count).toBe(3)
    end)
end)
