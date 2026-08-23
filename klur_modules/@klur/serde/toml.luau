--!strict
-- Lightweight and fast TOML parser and serializer for KLUR

local Toml = {}

local function parseValue(val: string): any
    val = val:gsub("^%s+", ""):gsub("%s+$", "")
    if val == "true" then return true end
    if val == "false" then return false end
    if tonumber(val) ~= nil then return tonumber(val) end
    if (val:sub(1, 1) == '"' and val:sub(-1) == '"') or (val:sub(1, 1) == "'" and val:sub(-1) == "'") then
        return val:sub(2, -2)
    end
    if val:sub(1, 1) == "[" and val:sub(-1) == "]" then
        local inner = val:sub(2, -2)
        local list = {}
        for item in inner:gmatch("[^,]+") do
            table.insert(list, parseValue(item))
        end
        return list
    end
    return val
end

function Toml.decode(content: string): {[string]: any}
    local root: {[string]: any} = {}
    local currentTable = root

    for line in content:gmatch("[^\r\n]+") do
        local clean = line:gsub("#.*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" then
            local header = clean:match("^%[([%w%._%-]+)%]$")
            if header then
                local current = root
                for part in header:gmatch("[^%.]+") do
                    if not current[part] then
                        current[part] = {}
                    end
                    current = current[part]
                end
                currentTable = current
            else
                local k, v = clean:match("^([%w%._%-]+)%s*=%s*(.+)$")
                if k and v then
                    currentTable[k] = parseValue(v)
                end
            end
        end
    end

    return root
end

function Toml.encode(tbl: {[string]: any}): string
    local out = {}
    local subTables: {[string]: any} = {}

    for k, v in pairs(tbl) do
        if type(v) == "table" and not (v[1] ~= nil) then
            subTables[k] = v
        elseif type(v) == "string" then
            table.insert(out, string.format("%s = %q", tostring(k), v :: string))
        elseif type(v) == "boolean" or type(v) == "number" then
            table.insert(out, string.format("%s = %s", tostring(k), tostring(v)))
        elseif type(v) == "table" and v[1] ~= nil then
            local items = {}
            for _, item in ipairs(v) do
                if type(item) == "string" then
                    table.insert(items, string.format("%q", item))
                else
                    table.insert(items, tostring(item))
                end
            end
            table.insert(out, string.format("%s = [%s]", k, table.concat(items, ", ")))
        end
    end

    for section, subTbl in pairs(subTables) do
        table.insert(out, "\n[" .. section .. "]")
        for k, v in pairs(subTbl) do
            if type(v) == "string" then
                table.insert(out, string.format("%s = %q", k, v))
            elseif type(v) == "boolean" or type(v) == "number" then
                table.insert(out, string.format("%s = %s", k, tostring(v)))
            end
        end
    end

    return table.concat(out, "\n")
end

Toml.parse = Toml.decode
Toml.stringify = Toml.encode

return Toml
