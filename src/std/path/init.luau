--!strict
-- Cross-platform Path Manipulation for KLUR

local isWindows = false
if process and process.os == "windows" then
    isWindows = true
end

local Path = {
    sep = isWindows and "\\" or "/",
    delimiter = isWindows and ";" or ":",
    isWindows = isWindows,
}

function Path.normalize(p: string): string
    if p == "" then return "." end
    local clean = p:gsub("\\", "/")
    local isAbs = clean:sub(1, 1) == "/"
    local isWinAbs = isWindows and clean:match("^[A-Za-z]:/") ~= nil
    local winDrive = ""

    if isWinAbs then
        winDrive = clean:sub(1, 2)
        clean = clean:sub(3)
    end

    local segments: {string} = {}
    for part in clean:gmatch("[^/]+") do
        if part == "." then
            -- Skip current dir
        elseif part == ".." then
            if #segments > 0 and segments[#segments] ~= ".." then
                table.remove(segments)
            elseif not isAbs and not isWinAbs then
                table.insert(segments, "..")
            end
        else
            table.insert(segments, part)
        end
    end

    local result = table.concat(segments, "/")
    if isWinAbs then
        result = winDrive .. "/" .. result
    elseif isAbs then
        result = "/" .. result
    elseif result == "" then
        result = "."
    end

    if isWindows then
        result = result:gsub("/", "\\")
    end
    return result
end

function Path.isAbsolute(p: string): boolean
    if p:sub(1, 1) == "/" or p:sub(1, 1) == "\\" then
        return true
    end
    if isWindows and p:match("^[A-Za-z]:[/\\]") then
        return true
    end
    return false
end

function Path.join(...: string): string
    local parts = {...}
    local cleanParts: {string} = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then
            table.insert(cleanParts, part)
        end
    end
    if #cleanParts == 0 then return "." end
    local joined = table.concat(cleanParts, "/")
    return Path.normalize(joined)
end

function Path.resolve(...: string): string
    local parts = {...}
    local cwd = "."
    if process and process.cwd then
        cwd = process.cwd()
    elseif fs and fs.cwd then
        cwd = fs.cwd()
    end

    local resolved = cwd
    for _, part in ipairs(parts) do
        if Path.isAbsolute(part) then
            resolved = part
        else
            resolved = resolved .. "/" .. part
        end
    end
    return Path.normalize(resolved)
end

function Path.dirname(p: string): string
    local norm = Path.normalize(p)
    if isWindows then norm = norm:gsub("\\", "/") end
    local lastSlash = norm:match("^(.*)/[^/]*$")
    if not lastSlash then
        if norm:sub(1, 1) == "/" then return "/" end
        return "."
    end
    if lastSlash == "" then return "/" end
    if isWindows then
        return (lastSlash:gsub("/", "\\"))
    end
    return lastSlash
end

function Path.basename(p: string, ext: string?): string
    local norm = Path.normalize(p)
    if isWindows then norm = (norm:gsub("\\", "/")) end
    local name = norm:match("([^/]+)$") or norm
    if ext and ext ~= "" and #name >= #ext and name:sub(-#ext) == ext then
        name = name:sub(1, -#ext - 1)
    end
    return name
end

function Path.extname(p: string): string
    local base = Path.basename(p)
    local dotIdx = base:match("^.+()%.%w+$")
    if not dotIdx then
        return ""
    end
    return base:sub(dotIdx)
end

function Path.relative(from: string, to: string): string
    local fromNorm = Path.resolve(from)
    local toNorm = Path.resolve(to)
    if fromNorm == toNorm then return "" end

    local fromParts: {string} = {}
    for part in fromNorm:gmatch("[^\\/]+") do table.insert(fromParts, part) end
    local toParts: {string} = {}
    for part in toNorm:gmatch("[^\\/]+") do table.insert(toParts, part) end

    local same = 0
    while same < #fromParts and same < #toParts and fromParts[same + 1] == toParts[same + 1] do
        same = same + 1
    end

    local result: {string} = {}
    for _ = same + 1, #fromParts do
        table.insert(result, "..")
    end
    for i = same + 1, #toParts do
        table.insert(result, toParts[i])
    end

    if #result == 0 then return "." end
    return table.concat(result, isWindows and "\\" or "/")
end

return Path
