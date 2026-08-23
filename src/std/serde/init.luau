--!strict
-- Serialization and deserialization suite for KLUR

local Toml = require("@self/toml")
local DotEnv = require("@self/dotenv")

local _json = (_G :: any).json or {}

local Serde = {
    toml = Toml,
    dotenv = DotEnv,
    json = _json,
}

function Serde.parseJson(str: string): any
    if _json and _json.decode then
        return _json.decode(str)
    end
    error("JSON library not available")
end

function Serde.stringifyJson(val: any, pretty: boolean?): string
    if _json and _json.encode then
        if pretty and _json.pretty then
            return _json.pretty(val)
        end
        return _json.encode(val)
    end
    error("JSON library not available")
end

return Serde
