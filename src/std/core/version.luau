--!strict
-- Core semantic version parser and comparator for KLUR

export type SemVer = {
    major: number,
    minor: number,
    patch: number,
    prerelease: string?,
    build: string?,
    raw: string,
}

local Version = {}
Version.__index = Version

function Version.parse(vstr: string): SemVer?
    if type(vstr) ~= "string" then return nil end
    local clean = vstr:gsub("^%s+", ""):gsub("%s+$", "")
    if clean:sub(1, 1) == "v" or clean:sub(1, 1) == "V" then
        clean = clean:sub(2)
    end

    local main, pre, build = clean:match("^([0-9]+%.[0-9]+%.[0-9]+)%-?([0-9A-Za-z%.%-_]*)%+?([0-9A-Za-z%.%-_]*)$")
    if not main then
        local major, minor = clean:match("^([0-9]+)%.([0-9]+)$")
        if major and minor then
            main = major .. "." .. minor .. ".0"
        else
            local majorOnly = clean:match("^([0-9]+)$")
            if majorOnly then
                main = majorOnly .. ".0.0"
            else
                return nil
            end
        end
    end

    local majStr, minStr, patStr = main:match("^([0-9]+)%.([0-9]+)%.([0-9]+)$")
    local major = tonumber(majStr) or 0
    local minor = tonumber(minStr) or 0
    local patch = tonumber(patStr) or 0

    local semver: SemVer = {
        major = major,
        minor = minor,
        patch = patch,
        prerelease = (pre and #pre > 0) and pre or nil,
        build = (build and #build > 0) and build or nil,
        raw = vstr,
    }
    return setmetatable(semver :: any, Version) :: any
end

function Version.compare(a: SemVer, b: SemVer): number
    if a.major ~= b.major then
        return a.major > b.major and 1 or -1
    end
    if a.minor ~= b.minor then
        return a.minor > b.minor and 1 or -1
    end
    if a.patch ~= b.patch then
        return a.patch > b.patch and 1 or -1
    end
    if a.prerelease and not b.prerelease then
        return -1
    elseif not a.prerelease and b.prerelease then
        return 1
    elseif a.prerelease and b.prerelease then
        if a.prerelease < b.prerelease then return -1 end
        if a.prerelease > b.prerelease then return 1 end
    end
    return 0
end

function Version.satisfies(ver: SemVer | string, range: string): boolean
    local v: SemVer? = typeof(ver) == "string" and Version.parse(ver :: string) or (ver :: SemVer)
    if not v then return false end
    range = range:gsub("^%s+", ""):gsub("%s+$", "")
    if range == "*" or range == "" or range == "latest" then
        return true
    end

    if range:sub(1, 1) == "^" then
        local target = Version.parse(range:sub(2))
        if not target then return false end
        if Version.compare(v, target) < 0 then return false end
        if target.major > 0 then
            return v.major == target.major
        elseif target.minor > 0 then
            return v.major == 0 and v.minor == target.minor
        else
            return v.major == 0 and v.minor == 0 and v.patch == target.patch
        end
    elseif range:sub(1, 1) == "~" then
        local target = Version.parse(range:sub(2))
        if not target then return false end
        if Version.compare(v, target) < 0 then return false end
        return v.major == target.major and v.minor == target.minor
    elseif range:sub(1, 2) == ">=" then
        local target = Version.parse(range:sub(3))
        return target ~= nil and Version.compare(v, target) >= 0
    elseif range:sub(1, 2) == "<=" then
        local target = Version.parse(range:sub(3))
        return target ~= nil and Version.compare(v, target) <= 0
    elseif range:sub(1, 1) == ">" then
        local target = Version.parse(range:sub(2))
        return target ~= nil and Version.compare(v, target) > 0
    elseif range:sub(1, 1) == "<" then
        local target = Version.parse(range:sub(2))
        return target ~= nil and Version.compare(v, target) < 0
    elseif range:sub(1, 1) == "=" then
        local target = Version.parse(range:sub(2))
        return target ~= nil and Version.compare(v, target) == 0
    else
        local target = Version.parse(range)
        if target then
            return Version.compare(v, target) == 0
        end
        return v.raw == range
    end
end

function Version.format(v: SemVer): string
    local str = string.format("%d.%d.%d", v.major, v.minor, v.patch)
    if v.prerelease then str = str .. "-" .. v.prerelease end
    if v.build then str = str .. "+" .. v.build end
    return str
end

function Version:__tostring(): string
    return Version.format(self)
end

return Version
