--!strict
-- Local package linking system (klur link) for KLUR

local Core = require("@klur/core")
local Fs = require("@klur/fs")
local Path = require("@klur/path")
local Packagefile = require("./packagefile")
local Store = require("./store")
local Term = require("@klur/term")

local Linker = {}

function Linker.getLinksDir(): string
    local p = Path.join(Core.getKlurHome(), "links")
    Fs.mkdirp(p)
    return p
end

function Linker.register(projectDir: string?): boolean
    local root = Path.resolve(projectDir or ".")
    local manifest, err = Packagefile.load(Path.join(root, "Packagefile"))
    if not manifest then
        print(Term.red("[error] ") .. "Cannot link package without valid Packagefile: " .. tostring(err))
        return false
    end

    local linkPath = Path.join(Linker.getLinksDir(), manifest.name)
    Fs.mkdirp(Path.dirname(linkPath))
    Fs.writeFile(linkPath, root)
    print(Term.green("[ok] ") .. "Registered link for " .. Term.bold(manifest.name) .. " -> " .. root)
    return true
end

function Linker.link(pkgName: string, projectDir: string?): boolean
    local root = Path.resolve(projectDir or ".")
    local linkTargetFile = Path.join(Linker.getLinksDir(), pkgName)
    if not Fs.isFile(linkTargetFile) then
        print(Term.red("[error] ") .. "No registered link found for package " .. pkgName)
        return false
    end

    local sourceDir = Fs.readFile(linkTargetFile):gsub("%s+", "")
    if not Fs.isDir(sourceDir) then
        print(Term.red("[error] ") .. "Target directory for linked package no longer exists: " .. sourceDir)
        return false
    end

    local destDir = Path.join(root, "klur_modules", pkgName)
    Store.linkInto(sourceDir, destDir)
    print(Term.green("[ok] ") .. "Linked " .. Term.bold(pkgName) .. " -> " .. sourceDir)
    return true
end

function Linker.unlink(pkgName: string?, projectDir: string?): boolean
    local root = Path.resolve(projectDir or ".")
    if pkgName then
        local destDir = Path.join(root, "klur_modules", pkgName)
        Fs.rimraf(destDir)
        print(Term.green("[ok] ") .. "Unlinked " .. pkgName)
        return true
    else
        local manifest = Packagefile.load(Path.join(root, "Packagefile"))
        if manifest then
            local linkTargetFile = Path.join(Linker.getLinksDir(), manifest.name)
            Fs.removeFile(linkTargetFile)
            print(Term.green("[ok] ") .. "Unregistered global link for " .. manifest.name)
            return true
        end
    end
    return false
end

return Linker
