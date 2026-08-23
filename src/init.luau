--!strict
-- Entry point for KLUR runtime and toolchain

local Core = require("@self/core")
local Std = require("@self/std")
local PM = require("@self/pm")
local CLI = require("@self/cli")

local KLUR = {
    Core = Core,
    Std = Std,
    PM = PM,
    CLI = CLI,
    -- Standard Batteries exported at top-level for convenience
    fs = Std.fs,
    path = Std.path,
    process = Std.process,
    net = Std.net,
    async = Std.async,
    crypto = Std.crypto,
    serde = Std.serde,
    term = Std.term,
    log = Std.log,
    test = Std.test,
    events = Std.events,
    collections = Std.collections,
    stream = Std.stream,
}

-- If executed directly from CLI
-- native process
local varargs = {...}
local rawArgs = {}
-- Prefer the native varargs (argv[1..argc-1]); fall back to process.args.
-- process.args can be ambiguous in embedded runtimes, so varargs are primary.
if #varargs > 0 then
    rawArgs = varargs
elseif process and process.args and #process.args > 0 then
    rawArgs = process.args
end

-- The luau -a marker (declare start of arguments) is passed through as a literal
-- token by the runtime. Everything after the first -a is the program's argument
-- list. Strip the leading tokens up to and including the first -a.
do
    local cut = 0
    for i, v in ipairs(rawArgs) do
        if v == "-a" then
            cut = i
            break
        end
    end
    if cut > 0 then
        local stripped = {}
        for i = cut + 1, #rawArgs do
            table.insert(stripped, rawArgs[i])
        end
        rawArgs = stripped
    end
end

if #rawArgs > 0 then
    local exitCode = CLI.main(rawArgs)
    if exitCode ~= 0 then
        Std.process.exit(exitCode)
    end
end

return KLUR
