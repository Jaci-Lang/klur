--!strict
-- Content-addressable global cache store and linking system for KLUR

local Core = require("@klur/core")
local Fs = require("@klur/fs")
local Path = require("@klur/path")
local Crypto = require("@klur/crypto")
local Process = require("@klur/process")

local Store = {}

function Store.getStorePath(): string
    local p = Core.getStoreDir()
    Fs.mkdirp(p)
    return p
end

function Store.computeKey(url: string, commitOrRef: string?): string
    local raw = url .. "@" .. (commitOrRef or "HEAD")
    return Crypto.sha256(raw)
end

function Store.getEntryPath(key: string): string
    return Path.join(Store.getStorePath(), key)
end

function Store.has(key: string): boolean
    local p = Store.getEntryPath(key)
    return Fs.isDir(p)
end

function Store.linkInto(sourcePath: string, targetPath: string): boolean
    local parent = Path.dirname(targetPath)
    Fs.mkdirp(parent)
    Fs.rimraf(targetPath)

    if not Path.isWindows then
        -- POSIX symlink using ln -sf
        local res = Process.spawn("ln", {"-sf", Path.resolve(sourcePath), targetPath})
        if res.ok then return true end
    end

    -- Fallback to recursive copy
    return Fs.copyDir(sourcePath, targetPath)
end

function Store.clean(): boolean
    local p = Store.getStorePath()
    return Fs.rimraf(p)
end

function Store.list(): {string}
    local p = Store.getStorePath()
    return Fs.readDir(p)
end

return Store
