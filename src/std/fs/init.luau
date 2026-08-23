--!strict
-- High-level Enhanced Filesystem Operations for KLUR

local Path = require("@self/path")

export type StatResult = {
    exists: boolean,
    isDirectory: boolean,
    isFile: boolean,
    size: number,
    modified: number,
}

local Fs = {
    path = Path,
}

function Fs.exists(filePath: string): boolean
    if fs and fs.exists then
        return fs.exists(filePath)
    end
    local ok, res = pcall(function()
        local s = fs and fs.stat and fs.stat(filePath)
        return s ~= nil and s.exists == true
    end)
    return ok and res == true
end

function Fs.stat(filePath: string): StatResult?
    if fs and fs.stat then
        local s = fs.stat(filePath)
        if s and s.exists then
            return s :: any
        end
    end
    return nil
end

function Fs.isDir(filePath: string): boolean
    local s = Fs.stat(filePath)
    return s ~= nil and s.isDirectory == true
end

function Fs.isFile(filePath: string): boolean
    local s = Fs.stat(filePath)
    return s ~= nil and s.isFile == true
end

function Fs.readFile(filePath: string): string
    if fs and fs.readFile then
        return fs.readFile(filePath)
    end
    error("Filesystem readFile not available on current runtime")
end

function Fs.readFileOpt(filePath: string): string?
    if not Fs.exists(filePath) then return nil end
    local ok, res = pcall(function()
        return Fs.readFile(filePath)
    end)
    return ok and res or nil
end

function Fs.writeFile(filePath: string, contents: string): boolean
    if fs and fs.writeFile then
        fs.writeFile(filePath, contents)
        return true
    end
    error("Filesystem writeFile not available on current runtime")
end

function Fs.appendFile(filePath: string, contents: string): boolean
    if fs and fs.appendFile then
        fs.appendFile(filePath, contents)
        return true
    end
    local existing = Fs.readFileOpt(filePath) or ""
    return Fs.writeFile(filePath, existing .. contents)
end

function Fs.mkdirp(dirPath: string): boolean
    local norm = Path.normalize(dirPath)
    if Fs.exists(norm) then
        return Fs.isDir(norm)
    end

    local parent = Path.dirname(norm)
    if parent ~= norm and parent ~= "." and parent ~= "/" and parent ~= "\\" then
        Fs.mkdirp(parent)
    end

    if fs and fs.makeDir then
        pcall(function() fs.makeDir(norm) end)
        return Fs.exists(norm)
    end
    return false
end

function Fs.makeDir(dirPath: string, recursive: boolean?): boolean
    if recursive then
        return Fs.mkdirp(dirPath)
    end
    if fs and fs.makeDir then
        fs.makeDir(dirPath)
        return true
    end
    return false
end

function Fs.removeFile(filePath: string): boolean
    if not Fs.exists(filePath) then return true end
    if fs and fs.removeFile then
        fs.removeFile(filePath)
        return true
    end
    return false
end

function Fs.readDir(dirPath: string): {string}
    if fs and fs.readDir then
        return fs.readDir(dirPath)
    end
    return {}
end

function Fs.unlink(targetPath: string): boolean
    if not Fs.exists(targetPath) then return true end
    if fs and fs.removeFile then
        pcall(function() fs.removeFile(targetPath) end)
        if not Fs.exists(targetPath) then return true end
    end
    if os and os.execute then
        local cmd = (Path.isWindows and 'rmdir /q /s "' or 'rm -rf "') .. targetPath .. '"'
        os.execute(cmd)
        return not Fs.exists(targetPath)
    end
    return false
end

function Fs.rimraf(targetPath: string): boolean
    if not Fs.exists(targetPath) then return true end
    return Fs.unlink(targetPath)
end

function Fs.removeDir(dirPath: string, recursive: boolean?): boolean
    if recursive then
        return Fs.rimraf(dirPath)
    end
    if fs and fs.removeDir then
        fs.removeDir(dirPath)
        return true
    end
    return false
end

function Fs.copyFile(src: string, dest: string): boolean
    local parent = Path.dirname(dest)
    Fs.mkdirp(parent)
    if fs and fs.copy then
        fs.copy(src, dest)
        return true
    end
    local data = Fs.readFile(src)
    return Fs.writeFile(dest, data)
end

function Fs.copyDir(src: string, dest: string): boolean
    if not Fs.isDir(src) then return false end
    Fs.mkdirp(dest)
    local entries = Fs.readDir(src)
    for _, entry in ipairs(entries) do
        local srcChild = Path.join(src, entry)
        local destChild = Path.join(dest, entry)
        if Fs.isDir(srcChild) then
            Fs.copyDir(srcChild, destChild)
        else
            Fs.copyFile(srcChild, destChild)
        end
    end
    return true
end

function Fs.move(src: string, dest: string): boolean
    local parent = Path.dirname(dest)
    Fs.mkdirp(parent)
    if fs and fs.move then
        fs.move(src, dest)
        return true
    end
    if Fs.isDir(src) then
        Fs.copyDir(src, dest)
        Fs.rimraf(src)
    else
        Fs.copyFile(src, dest)
        Fs.removeFile(src)
    end
    return true
end

function Fs.atomicWrite(filePath: string, contents: string): boolean
    local parent = Path.dirname(filePath)
    Fs.mkdirp(parent)
    local tmpPath = filePath .. ".tmp." .. tostring(os.time()) .. "." .. tostring(math.random(1000, 9999))
    Fs.writeFile(tmpPath, contents)
    return Fs.move(tmpPath, filePath)
end

function Fs.walk(root: string, callback: (path: string, isDirectory: boolean) -> boolean?): {string}
    local results: {string} = {}
    local function walkInternal(current: string)
        if not Fs.exists(current) then return end
        local isDirectory = Fs.isDir(current)
        local continueRec = callback(current, isDirectory)
        if continueRec == false then return end
        table.insert(results, current)
        if isDirectory then
            local children = Fs.readDir(current)
            for _, child in ipairs(children) do
                walkInternal(Path.join(current, child))
            end
        end
    end
    walkInternal(root)
    return results
end

function Fs.glob(pattern: string, rootDir: string?): {string}
    local root = rootDir or "."
    local matched: {string} = {}

    -- Convert glob pattern to Lua pattern
    local function globToLua(glob: string): string
        local p = glob:gsub("%-", "%%-"):gsub("%.", "%%.")
        p = p:gsub("%*%*", ".*")
        p = p:gsub("%*", "[^/]*")
        p = p:gsub("%?", "[^/]")
        return "^" .. p .. "$"
    end

    local luaPattern = globToLua(pattern)
    local rootNorm = Path.normalize(root)

    Fs.walk(root, function(path: string, isDirectory: boolean)
        if isDirectory then
            local base = Path.basename(path)
            if base == ".git" or base == "node_modules" or base == "klur_modules" or base == ".baseline" or base == "build" then
                return false
            end
            return true
        end

        local relPath = Path.relative(rootNorm, path)
        local baseName = Path.basename(path)

        if relPath:match(luaPattern) or path:match(luaPattern) or baseName:match(luaPattern) then
            table.insert(matched, path)
        end
        return true
    end)

    return matched
end

function Fs.readJson(filePath: string): any?
    local raw = Fs.readFileOpt(filePath)
    if not raw then return nil end
    -- native json
    if json and json.decode then
        local ok, data = pcall(function() return json.decode(raw) end)
        return ok and data or nil
    end
    return nil
end

function Fs.writeJson(filePath: string, data: any, pretty: boolean?): boolean
    -- native json
    if json and json.encode then
        local str = ""
        if pretty and json.pretty then
            str = json.pretty(data)
        else
            str = json.encode(data)
        end
        return Fs.atomicWrite(filePath, str .. "\n")
    end
    return false
end

return Fs
