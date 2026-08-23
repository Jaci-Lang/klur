--!strict
-- Enhanced Process Execution and Environment for KLUR

local Path = require("@self/../fs/path")

type ProcessGlobals = {
    cwd: (() -> string)?,
    chdir: ((string) -> ())?,
    pid: number?,
    getpid: (() -> number)?,
    exit: ((number) -> ())?,
    env: {[string]: string}?,
    args: {string}?,
    os: string?,
    arch: string?,
    spawn: ((string, {string}) -> any)?,
}

type FsGlobals = {
    cwd: (() -> string)?,
    exists: ((string) -> boolean)?,
}

local _process: ProcessGlobals? = (_G :: any).process
local _fs: FsGlobals? = (_G :: any).fs

export type SpawnOptions = {
    cwd: string?,
    env: {[string]: string}?,
    stdin: string?,
    timeout: number?,
}

export type ProcessResult = {
    ok: boolean,
    exitCode: number,
    stdout: string,
    stderr: string,
}

local Process = {}

function Process.cwd(): string
    local p = _process
    if p and p.cwd then
        return p.cwd()
    end
    local f = _fs
    if f and f.cwd then
        return f.cwd()
    end
    return "."
end

function Process.chdir(dir: string): boolean
    local p = _process
    if p and p.chdir then
        local ok = pcall(function()
            if p and p.chdir then
                p.chdir(dir)
            end
        end)
        return ok
    end
    return false
end

function Process.pid(): number
    local p = _process
    if p then
        if p.pid then
            return p.pid
        end
        if p.getpid then
            return p.getpid()
        end
    end
    return 0
end

function Process.exit(code: number?)
    local c = code or 0
    local p = _process
    if p and p.exit then
        p.exit(c)
    elseif os and os.exit then
        os.exit(c)
    end
end

function Process.env(key: string, value: string?): string?
    local p = _process
    if value ~= nil then
        if os and os.setenv then
            os.setenv(key, value)
        end
        if p and p.env then
            p.env[key] = value
        end
        return value
    else
        if p and p.env and p.env[key] then
            return p.env[key]
        end
        if os and os.getenv then
            return os.getenv(key)
        end
        return nil
    end
end

function Process.which(cmd: string): string?
    if Path.isAbsolute(cmd) then
        return cmd
    end
    local pathEnv = Process.env("PATH") or ""
    local sep = Path.delimiter
    local f = _fs
    for dir in pathEnv:gmatch("[^" .. sep .. "]+") do
        local candidate = Path.join(dir, cmd)
        if f and f.exists and f.exists(candidate) then
            return candidate
        end
        if Path.isWindows then
            if f and f.exists and f.exists(candidate .. ".exe") then
                return candidate .. ".exe"
            end
            if f and f.exists and f.exists(candidate .. ".cmd") then
                return candidate .. ".cmd"
            end
            if f and f.exists and f.exists(candidate .. ".bat") then
                return candidate .. ".bat"
            end
        end
    end
    return nil
end

function Process.spawn(cmd: string, args: {string}?, opts: SpawnOptions?): ProcessResult
    local argList = args or {}
    local oldCwd: string? = nil
    if opts and opts.cwd then
        oldCwd = Process.cwd()
        Process.chdir(opts.cwd)
    end

    local result: ProcessResult = {
        ok = false,
        exitCode = 1,
        stdout = "",
        stderr = "",
    }

    local p = _process
    if p and p.spawn then
        local raw: any = p.spawn(cmd, argList)
        if raw then
            result.exitCode = raw.exitcode or 0
            result.stdout = raw.stdout or ""
            result.stderr = raw.stderr or ""
            result.ok = (result.exitCode == 0)
        end
    else
        -- Fallback to os.execute
        local fullCmd = cmd
        for _, a in ipairs(argList) do
            fullCmd = fullCmd .. " " .. string.format("%q", a)
        end
        local ok, _exitKind, code = os.execute(fullCmd)
        result.exitCode = (type(code) == "number") and code or (ok and 0 or 1)
        result.ok = result.exitCode == 0
    end

    if oldCwd then
        Process.chdir(oldCwd)
    end

    return result
end

function Process.exec(cmd: string, args: {string}?): ProcessResult
    return Process.spawn(cmd, args)
end

function Process.execRaw(cmdLine: string): ProcessResult
    local parts = {}
    for word in cmdLine:gmatch("%S+") do
        table.insert(parts, word)
    end
    if #parts == 0 then
        return { ok = true, exitCode = 0, stdout = "", stderr = "" }
    end
    local cmd = table.remove(parts, 1) :: string
    return Process.spawn(cmd, parts)
end

return Process
