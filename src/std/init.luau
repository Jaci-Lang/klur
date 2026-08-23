--!strict
-- KLUR Standard Batteries Suite

local Fs = require("@self/fs")
local Path = require("@self/fs/path")
local Process = require("@self/process")
local Net = require("@self/net")
local Async = require("@self/async")
local Crypto = require("@self/crypto")
local Serde = require("@self/serde")
local Term = require("@self/term")
local Log = require("@self/log")
local Test = require("@self/test")
local Events = require("@self/events")
local Collections = require("@self/collections")
local Stream = require("@self/stream")

local Std = {
    fs = Fs,
    path = Path,
    process = Process,
    net = Net,
    async = Async,
    crypto = Crypto,
    serde = Serde,
    term = Term,
    log = Log,
    test = Test,
    events = Events,
    collections = Collections,
    stream = Stream,
}

return Std
