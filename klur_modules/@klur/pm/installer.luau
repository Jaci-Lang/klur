--!strict
-- Package Installation Engine for KLUR

local Fs = require("@klur/fs")
local Path = require("@klur/path")
local Packagefile = require("./packagefile")
local Lockfile = require("./lockfile")
local Resolver = require("./resolver")
local Store = require("./store")
local Term = require("@klur/term")
local Spinner = require("@klur/term/spinner")

local Installer = {}

function Installer.install(projectDir: string?, options: {includeDev: boolean?}?): (boolean, {string})
    local root = projectDir or "."
    local manifest, err = Packagefile.load(Path.join(root, "Packagefile"))
    if not manifest then
        return false, { err or "Packagefile not found" }
    end

    local lock = Lockfile.load(root)
    local allDeps: {[string]: string} = {}

    if manifest.dependencies then
        for k, v in pairs(manifest.dependencies) do
            allDeps[k] = v
        end
    end

    if (options and options.includeDev ~= false) and manifest.devDependencies then
        for k, v in pairs(manifest.devDependencies) do
            allDeps[k] = v
        end
    end

    if next(allDeps) == nil then
        print(Term.dim("No dependencies to install in " .. manifest.name))
        return true, {}
    end

    local spinner = Spinner.new("Resolving dependency tree...")
    spinner:start()

    local resolved, errors = Resolver.resolveTree(allDeps, lock, function(msg)
        spinner:update(msg)
    end)

    if #errors > 0 then
        spinner:fail("Failed to resolve dependencies")
        return false, errors
    end

    spinner:update("Materializing packages into klur_modules...")

    local modulesDir = Path.join(root, "klur_modules")
    Fs.mkdirp(modulesDir)

    local updatedLockPackages: {[string]: Lockfile.LockedPackage} = {}

    for name, node in pairs(resolved) do
        local targetDir = Path.join(modulesDir, name)
        if node.storePath and node.storePath ~= "" and Fs.exists(node.storePath) then
            Store.linkInto(node.storePath, targetDir)
        end

        updatedLockPackages[name] = {
            version = node.version,
            source = node.source,
            repository = node.repository,
            commit = node.commit,
            integrity = nil,
            dependencies = node.dependencies,
        }
    end

    -- Write updated lockfile
    local lockData: Lockfile.LockfileData = {
        lockfileVersion = 1,
        packages = updatedLockPackages,
    }
    Lockfile.save(lockData, root)

    spinner:succeed(string.format("Installed %d packages into klur_modules", (function()
        local count = 0
        for _ in pairs(resolved) do count = count + 1 end
        return count
    end)()))

    return true, {}
end

function Installer.add(pkgSpec: string, projectDir: string?, isDev: boolean?): boolean
    local root = projectDir or "."
    local manifest, err = Packagefile.load(Path.join(root, "Packagefile"))
    if not manifest then
        manifest = {
            name = Path.basename(Path.resolve(root)),
            version = "0.1.0",
            dependencies = {},
            devDependencies = {},
            scripts = {},
        }
    end

    -- Derive package name from spec
    local pkgName = pkgSpec
    if pkgSpec:find("^github:") then
        local rest = pkgSpec:sub(8):match("^([^#]+)") or ""
        pkgName = rest:match("/([^/]+)$") or rest
    elseif pkgSpec:find("^https?://") then
        local base = pkgSpec:match("/([^/]+)%.git") or pkgSpec:match("/([^/#]+)") or "pkg"
        pkgName = base
    end

    if isDev then
        manifest.devDependencies = manifest.devDependencies or {}
        manifest.devDependencies[pkgName] = pkgSpec
    else
        manifest.dependencies = manifest.dependencies or {}
        manifest.dependencies[pkgName] = pkgSpec
    end

    Packagefile.save(manifest, Path.join(root, "Packagefile"))
    local ok, errors = Installer.install(root)
    return ok
end

function Installer.remove(pkgName: string, projectDir: string?): boolean
    local root = projectDir or "."
    local manifest, err = Packagefile.load(Path.join(root, "Packagefile"))
    if not manifest then
        print(Term.red("[error] ") .. "Packagefile not found")
        return false
    end

    if manifest.dependencies and manifest.dependencies[pkgName] then
        manifest.dependencies[pkgName] = nil
    end
    if manifest.devDependencies and manifest.devDependencies[pkgName] then
        manifest.devDependencies[pkgName] = nil
    end

    Packagefile.save(manifest, Path.join(root, "Packagefile"))

    -- Remove from klur_modules
    local modPath = Path.join(root, "klur_modules", pkgName)
    Fs.rimraf(modPath)

    print(Term.green("[ok] ") .. "Removed " .. pkgName)
    return true
end

return Installer
