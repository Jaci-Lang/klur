local Test = require("@klur/test")
local Crypto = require("@klur/crypto")
local expect = Test.expect

Test.describe("Std: Crypto & Hashing", function()
    Test.it("should compute SHA-256 hex digest", function()
        local hash = Crypto.sha256("hello world")
        expect(hash).toBe("b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9")
    end)

    Test.it("should compute MD5 hex digest", function()
        local hash = Crypto.md5("hello world")
        expect(hash).toBe("5eb63bbbe01eeed093cb22bb8f5acdc3")
    end)

    Test.it("should generate valid UUID v4 strings", function()
        local uuid1 = Crypto.uuid()
        local uuid2 = Crypto.uuid()
        expect(#uuid1).toBe(36)
        expect(#uuid2).toBe(36)
        expect(uuid1:sub(15, 15)).toBe("4") -- version 4 check
        expect(uuid1 ~= uuid2).toBe(true)
    end)

    Test.it("should encode and decode base64", function()
        local raw = "Klee Luau Runtime"
        local enc = Crypto.base64Encode(raw)
        local dec = Crypto.base64Decode(enc)
        expect(dec).toBe(raw)
    end)

    Test.it("should perform timing-safe equality", function()
        expect(Crypto.timingSafeEqual("secret123", "secret123")).toBe(true)
        expect(Crypto.timingSafeEqual("secret123", "secret456")).toBe(false)
    end)
end)
