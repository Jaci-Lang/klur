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

function Serde.parseJson(str: string): any
    if json and json.decode then
        return json.decode(str)
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
