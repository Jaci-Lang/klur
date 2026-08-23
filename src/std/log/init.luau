--!strict
-- High performance structured and leveled logging for KLUR

local Term = require("@klur/term")

export type LogLevel = "debug" | "info" | "warn" | "error" | "silent"

local levelPriorities: {[LogLevel]: number} = {
    debug = 1,
    info = 2,
    warn = 3,
    error = 4,
    silent = 5,
}

local currentLevel: LogLevel = "info"

local Logger = {}

function Logger.setLevel(level: LogLevel)
    if levelPriorities[level] then
        currentLevel = level
    end
end

function Logger.getLevel(): LogLevel
    return currentLevel
end

local function shouldLog(level: LogLevel): boolean
    local targetPri = levelPriorities[level] or 2
    local curPri = levelPriorities[currentLevel] or 2
    return targetPri >= curPri
end

local function timestamp(): string
    if os and os.date then
        return os.date("%H:%M:%S") :: string
    end
    return ""
end

function Logger.debug(msg: string, ...: any)
    if not shouldLog("debug") then return end
    local ts = Term.dim(timestamp())
    local tag = Term.magenta("[debug]")
    print(string.format("%s %s %s", ts, tag, string.format(msg, ...)))
end

function Logger.info(msg: string, ...: any)
    if not shouldLog("info") then return end
    local ts = Term.dim(timestamp())
    local tag = Term.blue("[info]")
    print(string.format("%s %s %s", ts, tag, string.format(msg, ...)))
end

function Logger.success(msg: string, ...: any)
    if not shouldLog("info") then return end
    local ts = Term.dim(timestamp())
    local tag = Term.green("[ok]")
    print(string.format("%s %s %s", ts, tag, string.format(msg, ...)))
end

function Logger.warn(msg: string, ...: any)
    if not shouldLog("warn") then return end
    local ts = Term.dim(timestamp())
    local tag = Term.yellow("[warn]")
    print(string.format("%s %s %s", ts, tag, string.format(msg, ...)))
end

function Logger.error(msg: string, ...: any)
    if not shouldLog("error") then return end
    local ts = Term.dim(timestamp())
    local tag = Term.red("[error]")
    io.stderr:write(string.format("%s %s %s\n", ts, tag, string.format(msg, ...)))
    io.stderr:flush()
end

return Logger
