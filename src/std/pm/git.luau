--!strict
-- Git operations and specifier resolution for KLUR

local Process = require("@klur/process")
local Fs = require("@klur/fs")

export type ParsedSpec = {
    kind: "git" | "link" | "path" | "version",
    url: string?,
    ref: string?,
    raw: string,
    subpath: string?,
}

local Git = {}

function Git.isAvailable(): boolean
    return Process.which("git") ~= nil
end

function Git.parseSpec(spec: string): ParsedSpec
    spec = spec:gsub("^%s+", ""):gsub("%s+$", "")

    if spec:find("^link:") then
        return {
            kind = "link",
            url = spec:sub(6),
            raw = spec,
        }
    end

    if spec:find("^path:") then
        return {
            kind = "path",
            url = spec:sub(6),
            raw = spec,
        }
    end

    if spec:find("^file:") then
        return {
            kind = "path",
            url = spec:sub(6),
            raw = spec,
        }
    end

    -- github:org/repo or github:org/repo#v1.0.0
    if spec:find("^github:") then
        local rest = spec:sub(8)
        local repo, ref = rest:match("^([^#]+)#?(.*)$")
        local url = "https://github.com/" .. repo .. ".git"
        return {
            kind = "git",
            url = url,
            ref = (ref and ref ~= "") and ref or nil,
            raw = spec,
        }
    end

    -- git@ or https:// or git://
    if spec:find("^https?://") or spec:find("^git@") or spec:find("^git://") then
        local url, ref = spec:match("^([^#]+)#?(.*)$")
        return {
            kind = "git",
            url = url,
            ref = (ref and ref ~= "") and ref or nil,
            raw = spec,
        }
    end

    -- Default to version or tag specifier
    return {
        kind = "version",
        ref = spec,
        raw = spec,
    }
end

function Git.clone(url: string, destDir: string, ref: string?): (boolean, string)
    Fs.mkdirp(destDir)
    local args = {"clone", "--depth", "1"}
    if ref and ref ~= "" then
        table.insert(args, "--branch")
        table.insert(args, ref)
    end
    table.insert(args, url)
    table.insert(args, destDir)

    local res = Process.spawn("git", args)
    if not res.ok and ref then
        -- If shallow clone with branch failed, try cloning full and checkout ref
        Fs.rimraf(destDir)
        local fullRes = Process.spawn("git", {"clone", url, destDir})
        if fullRes.ok then
            local coRes = Process.spawn("git", {"checkout", ref}, { cwd = destDir })
            return coRes.ok, coRes.stderr
        end
        return false, fullRes.stderr
    end

    return res.ok, res.stderr
end

function Git.getHeadCommit(repoDir: string): string?
    local res = Process.spawn("git", {"rev-parse", "HEAD"}, { cwd = repoDir })
    if res.ok then
        return res.stdout:gsub("%s+", "")
    end
    return nil
end

return Git
