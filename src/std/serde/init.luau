--!strict
-- Serialization and deserialization suite for KLUR

local Toml = require("@self/toml")
local DotEnv = require("@self/dotenv")

-- native json

local Serde = {
    toml = Toml,
    dotenv = DotEnv,
    json = json,
}

-- Older Jaci builds decode JSON null to a lightuserdata sentinel (json.null)
-- instead of nil. Normalize the decoded tree so Luau code sees standard
-- semantics: JSON null == nil.
local NULL_SENTINEL = json and json.null or nil

local function denull(value: any): any
    if value == NULL_SENTINEL then
        return nil
    end
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        local dv = denull(v)
        if dv ~= nil then
            out[k] = dv
        end
    end
    return out
end

function Serde.parseJson(str: string): any
    if json and json.decode then
        return denull(json.decode(str))
    end
    error("JSON library not available")
end

function Serde.stringifyJson(val: any, pretty: boolean?): string
    if json and json.encode then
        if pretty and json.pretty then
            return json.pretty(val)
        end
        return json.encode(val)
    end
    error("JSON library not available")
end

return Serde
