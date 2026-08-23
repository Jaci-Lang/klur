--!strict
-- Packagefile (Luau DSL & table format) parser and serializer for KLUR

local Fs = require("@klur/fs")
local Path = require("@klur/path")

export type PackageManifest = {
    name: string,
    version: string,
    description: string?,
    main: string?,
    bin: {[string]: string}?,
    scripts: {[string]: string}?,
    dependencies: {[string]: string}?,
    devDependencies: {[string]: string}?,
    repository: string?,
    license: string?,
    private: boolean?,
}

local Packagefile = {}

function Packagefile.find(startDir: string?): string?
    local current = Path.resolve(startDir or ".")
    while true do
        local candidate = Path.join(current, "Packagefile")
        if Fs.isFile(candidate) then
            return candidate
        end
        local parent = Path.dirname(current)
        if parent == current or parent == "." or parent == "/" or parent == "\\" then
            break
        end
        current = parent
    end
    return nil
end

function Packagefile.load(filePath: string?): (PackageManifest?, string?)
    local path = filePath or Packagefile.find()
    if not path or not Fs.isFile(path) then
        return nil, "Packagefile not found"
    end

    local content = Fs.readFile(path)
    local declaredPkg: any = nil

    local env = {
        package = function(tbl: any)
            declaredPkg = tbl
            return tbl
        end,
    }
    setmetatable(env, { __index = _G })

    -- loadstring is provided by the embedded runtime; fall back to load.
    local compile = loadstring or load
    local chunk, err = compile(content, "@" .. path)
    if not chunk then
        return nil, "Failed to compile Packagefile: " .. tostring(err)
    end

    setfenv(chunk, env)
    local ok, res = pcall(chunk)
    if not ok then
        return nil, "Failed to execute Packagefile: " .. tostring(res)
    end

    local manifest = declaredPkg or res
    if type(manifest) ~= "table" then
        return nil, "Packagefile must return a table or call package({...})"
    end

    if not manifest.name or type(manifest.name) ~= "string" then
        return nil, "Packagefile must contain a valid 'name' string"
    end
    if not manifest.version or type(manifest.version) ~= "string" then
        manifest.version = "0.1.0"
    end

    manifest.dependencies = manifest.dependencies or {}
    manifest.devDependencies = manifest.devDependencies or {}
    manifest.scripts = manifest.scripts or {}
    manifest.bin = manifest.bin or {}

    return manifest :: PackageManifest, nil
end

function Packagefile.serialize(pkg: PackageManifest): string
    local out = {}
    table.insert(out, "return {")
    table.insert(out, string.format("    name = %q,", pkg.name))
    table.insert(out, string.format("    version = %q,", pkg.version))
    if pkg.description then
        table.insert(out, string.format("    description = %q,", pkg.description))
    end
    if pkg.main then
        table.insert(out, string.format("    main = %q,", pkg.main))
    end
    if pkg.license then
        table.insert(out, string.format("    license = %q,", pkg.license))
    end

    if pkg.bin and next(pkg.bin) ~= nil then
        table.insert(out, "    bin = {")
        for k, v in pairs(pkg.bin) do
            table.insert(out, string.format("        [%q] = %q,", k, v))
        end
        table.insert(out, "    },")
    end

    if pkg.scripts and next(pkg.scripts) ~= nil then
        table.insert(out, "    scripts = {")
        for k, v in pairs(pkg.scripts) do
            table.insert(out, string.format("        [%q] = %q,", k, v))
        end
        table.insert(out, "    },")
    end

    if pkg.dependencies and next(pkg.dependencies) ~= nil then
        table.insert(out, "    dependencies = {")
        for k, v in pairs(pkg.dependencies) do
            table.insert(out, string.format("        [%q] = %q,", k, v))
        end
        table.insert(out, "    },")
    else
        table.insert(out, "    dependencies = {},")
    end

    if pkg.devDependencies and next(pkg.devDependencies) ~= nil then
        table.insert(out, "    devDependencies = {")
        for k, v in pairs(pkg.devDependencies) do
            table.insert(out, string.format("        [%q] = %q,", k, v))
        end
        table.insert(out, "    },")
    end

    table.insert(out, "}")
    return table.concat(out, "\n") .. "\n"
end

function Packagefile.save(pkg: PackageManifest, filePath: string?): boolean
    local target = filePath or "Packagefile"
    local content = Packagefile.serialize(pkg)
    return Fs.atomicWrite(target, content)
end

return Packagefile
