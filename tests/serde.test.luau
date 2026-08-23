local Test = require("@klur/test")
local Serde = require("@klur/serde")
local Toml = require("../src/std/serde/toml")
local DotEnv = require("../src/std/serde/dotenv")
local expect = Test.expect

Test.describe("Std: Serde (TOML, DotEnv, JSON)", function()
    Test.it("should parse and serialize TOML", function()
        local tomlStr = [[
name = "klur"
version = "1.0.0"
threads = 4
enabled = true

[database]
host = "localhost"
port = 5432
]]
        local data = Toml.decode(tomlStr)
        expect(data.name).toBe("klur")
        expect(data.version).toBe("1.0.0")
        expect(data.threads).toBe(4)
        expect(data.enabled).toBe(true)
        expect(data.database).toBeDefined()
        expect(data.database.host).toBe("localhost")
        expect(data.database.port).toBe(5432)
    end)

    Test.it("should parse .env files", function()
        local envStr = [[
# Database config
DB_HOST=127.0.0.1
DB_PORT=3306
API_KEY="secret-token-123"
]]
        local envMap = DotEnv.parse(envStr)
        expect(envMap.DB_HOST).toBe("127.0.0.1")
        expect(envMap.DB_PORT).toBe("3306")
        expect(envMap.API_KEY).toBe("secret-token-123")
    end)

    Test.it("should stringify and parse JSON", function()
        local obj = { project = "KLUR", active = true, list = {1, 2, 3} }
        local str = Serde.stringifyJson(obj)
        local parsed = Serde.parseJson(str)
        expect(parsed.project).toBe("KLUR")
        expect(parsed.active).toBe(true)
        expect(#parsed.list).toBe(3)
    end)
end)
