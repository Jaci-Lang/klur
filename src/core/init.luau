--!strict
-- Core metadata and runtime environment for KLUR

local Version = require("@self/version")
local Errors = require("@self/errors")

-- native process
-- native fs

local Core = {
    VERSION = "0.1.0",
    NAME = "KLUR",
    FULL_NAME = "Klee Luau Runtime",
    Version = Version,
    Errors = Errors,
}

function Core.getPlatform(): string
    if process and process.os then
        return process.os
    end
    return "unknown"
end

function Core.getArch(): string
    if process and process.arch then
        return process.arch
    end
    return "unknown"
end

function Core.isWindows(): boolean
    return Core.getPlatform() == "windows"
end

function Core.isLinux(): boolean
    return Core.getPlatform() == "linux"
end

function Core.isMacOS(): boolean
    return Core.getPlatform() == "macos" or Core.getPlatform() == "darwin"
end

function Core.getEnv(key: string, default: string?): string?
    if os and os.getenv then
        local val = os.getenv(key)
        if val ~= nil and val ~= "" then return val end
    end
    if process and process.env then
        local val = process.env[key]
        if val ~= nil and val ~= "" then return val end
    end
    return default
end

function Core.getHomeDir(): string
    if Core.isWindows() then
        return Core.getEnv("USERPROFILE", "C:\\Users\\Default") :: string
    end
    return Core.getEnv("HOME", "/root") :: string
end

function Core.getKlurHome(): string
    local explicit = Core.getEnv("KLUR_HOME")
    if explicit and explicit ~= "" then
        return explicit
    end
    local home = Core.getHomeDir()
    local sep = Core.isWindows() and "\\" or "/"
    return home .. sep .. ".klur"
end

function Core.getTargetTriple(): string
    local osName = Core.getPlatform()
    local arch = Core.getArch()

    if osName == "linux" then
        if arch == "arm64" or arch == "aarch64" then
            return "aarch64-unknown-linux-gnu"
        else
            return "x86_64-unknown-linux-gnu"
        end
    elseif osName == "macos" or osName == "darwin" then
        if arch == "arm64" or arch == "aarch64" then
            return "aarch64-apple-darwin"
        else
            return "x86_64-apple-darwin"
        end
    elseif osName == "windows" then
        if arch == "arm64" or arch == "aarch64" then
            return "aarch64-pc-windows-msvc"
        else
            return "x86_64-pc-windows-msvc"
        end
    end
    return "x86_64-unknown-linux-gnu"
end

function Core.getStoreDir(): string
    local explicit = Core.getEnv("KLUR_STORE")
    if explicit and explicit ~= "" then
        return explicit
    end
    local sep = Core.isWindows() and "\\" or "/"
    return Core.getKlurHome() .. sep .. "store"
end

function Core.getBinDir(): string
    local sep = Core.isWindows() and "\\" or "/"
    return Core.getKlurHome() .. sep .. "bin"
end

function Core.getExtensionsDir(): string
    local explicit = Core.getEnv("KLUR_EXTENSIONS")
    if explicit and explicit ~= "" then
        return explicit
    end
    local sep = Core.isWindows() and "\\" or "/"
    return Core.getKlurHome() .. sep .. "extensions"
end

function Core.getLuauBinary(): string
    if os and os.getenv then
        local envBin = os.getenv("JACI_BIN") or os.getenv("LUAU_BIN")
        if envBin and envBin ~= "" and fs and fs.exists and fs.exists(envBin) then
            return envBin
        end
    end

    local candidates = {
        Core.getKlurHome() .. "/bin/luau",
        "build/luau",
        "../build/luau",
    }
    for _, c in ipairs(candidates) do
        if fs and fs.exists and fs.exists(c) then
            return c
        end
    end
    return "luau"
end

return Core
