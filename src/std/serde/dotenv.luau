--!strict
-- .env file parser and environment loader for KLUR

local DotEnv = {}

function DotEnv.parse(content: string): {[string]: string}
    local envMap: {[string]: string} = {}
    for line in content:gmatch("[^\r\n]+") do
        local clean = line:gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" and clean:sub(1, 1) ~= "#" then
            local k, v = clean:match("^([%w_]+)%s*=%s*(.*)$")
            if k and v then
                if (v:sub(1, 1) == '"' and v:sub(-1) == '"') or (v:sub(1, 1) == "'" and v:sub(-1) == "'") then
                    v = v:sub(2, -2)
                end
                envMap[k] = v
            end
        end
    end
    return envMap
end

function DotEnv.load(filePath: string?): {[string]: string}
    local target = filePath or ".env"
    if not (fs and fs.exists and fs.exists(target)) then
        return {}
    end
    local content = fs.readFile(target)
    local vars = DotEnv.parse(content)
    for k, v in pairs(vars) do
        if os and os.setenv then
            os.setenv(k, v)
        end
        if process and process.env then
            process.env[k] = v
        end
    end
    return vars
end

return DotEnv
