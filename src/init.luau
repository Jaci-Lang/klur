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
if process and process.args and #process.args > 0 then
    rawArgs = process.args
elseif #varargs > 0 then
    rawArgs = varargs
end

if #rawArgs > 0 then
    local exitCode = CLI.main(rawArgs)
    if exitCode ~= 0 then
        Std.process.exit(exitCode)
    end
end

return KLUR
