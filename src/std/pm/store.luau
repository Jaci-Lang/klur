--!strict
-- Content-addressable global cache store and linking system for KLUR

local Core = require("@klur/core")
local Fs = require("@klur/fs")
local Path = require("@klur/path")
local Crypto = require("@klur/crypto")

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

-- Copy a content-addressable cache entry into the project's module directory.
-- KLUR does not use symlinks: installed packages are real copies of the
-- content-addressable cache entry, which keeps the package tree self-contained
-- and works identically on Linux, macOS, and Windows.
function Store.linkInto(sourcePath: string, targetPath: string): boolean
    local parent = Path.dirname(targetPath)
    Fs.mkdirp(parent)
    Fs.rimraf(targetPath)
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
