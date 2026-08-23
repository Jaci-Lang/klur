--!strict
-- Deterministic Lockfile (Packagefile.lock) for KLUR

local Fs = require("@klur/fs")
local Path = require("@klur/path")

export type LockedPackage = {
    version: string,
    source: string, -- "git" | "link" | "path"
    repository: string?,
    commit: string?,
    integrity: string?,
    dependencies: {[string]: string}?,
}

export type LockfileData = {
    lockfileVersion: number,
    packages: {[string]: LockedPackage},
}

local Lockfile = {}

function Lockfile.getPath(dir: string?): string
    return Path.join(dir or ".", "Packagefile.lock")
end

function Lockfile.load(dir: string?): LockfileData?
    local path = Lockfile.getPath(dir)
    if not Fs.isFile(path) then
        return nil
    end

    local data = Fs.readJson(path)
    if not data or type(data) ~= "table" then
        return nil
    end

    data.packages = data.packages or {}
    data.lockfileVersion = data.lockfileVersion or 1
    return data :: LockfileData
end

function Lockfile.save(data: LockfileData, dir: string?): boolean
    local path = Lockfile.getPath(dir)
    data.lockfileVersion = 1
    data.packages = data.packages or {}
    return Fs.writeJson(path, data, true)
end

return Lockfile
