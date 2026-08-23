--!strict
-- Main CLI router and dispatcher for KLUR

local Core = require("@klur/core")
local Args = require("@self/args")
local Term = require("@klur/term")
local _Process = require("@klur/process")

local CmdInit = require("@self/commands/init_cmd")
local CmdInstall = require("@self/commands/install")
local CmdRemove = require("@self/commands/remove")
local CmdRun = require("@self/commands/run")
local CmdTest = require("@self/commands/test")
local CmdBuild = require("@self/commands/build")
local CmdLink = require("@self/commands/link")
local CmdCache = require("@self/commands/cache")
local CmdInfo = require("@self/commands/info")
local CmdPublish = require("@self/commands/publish")

local CLI = {}

local function printHelp()
    print(Term.bold("KLUR") .. " - " .. Core.FULL_NAME .. " (" .. Core.VERSION .. ")")
    print(Term.dim("Fast, batteries-included, modular Luau runtime and toolchain for Jaci"))
    print("")
    print(Term.bold("USAGE:"))
    print("  klur <command> [arguments...]")
    print("  klur <file.luau> [arguments...]")
    print("  klur run <script | file.luau>")
    print("")
    print(Term.bold("COMMANDS:"))
    print("  " .. Term.cyan("init") .. "        Initialize a new KLUR project with Packagefile")
    print("  " .. Term.cyan("run") .. "         Run a script defined in Packagefile or a .luau file")
    print("  " .. Term.cyan("install, i") .. "  Install all dependencies into klur_modules")
    print("  " .. Term.cyan("add") .. "         Add a dependency (e.g. github:user/repo#tag)")
    print("  " .. Term.cyan("remove, rm") .. "  Remove a dependency from Packagefile and klur_modules")
    print("  " .. Term.cyan("test") .. "        Run test suites (*.test.luau, *.spec.luau)")
    print("  " .. Term.cyan("build") .. "       Bundle into a standalone native binary")
    print("  " .. Term.cyan("link") .. "        Link a local package for development")
    print("  " .. Term.cyan("unlink") .. "      Unlink a local package")
    print("  " .. Term.cyan("cache") .. "       Manage global content-addressable cache store")
    print("  " .. Term.cyan("info") .. "        Display runtime environment and system information")
    print("  " .. Term.cyan("publish") .. "     Publish release tag to Git repository")
    print("  " .. Term.cyan("version, -v") .. " Print KLUR version")
    print("  " .. Term.cyan("help, -h") .. "    Show this help message")
    print("")
end

function CLI.main(argv: {string}): number
    local parsed = Args.parse(argv)
    local cmd = parsed.subcommand

    if cmd == "version" or cmd == "-v" or cmd == "--version" or parsed.options["version"] or parsed.options["v"] then
        print(Core.NAME .. " v" .. Core.VERSION)
        return 0
    end

    if not cmd or cmd == "help" or parsed.options["help"] or parsed.options["h"] then
        printHelp()
        return 0
    end

    if cmd == "init" then
        return CmdInit(parsed)
    elseif cmd == "install" or cmd == "i" then
        return CmdInstall(parsed)
    elseif cmd == "add" then
        return CmdInstall(parsed)
    elseif cmd == "remove" or cmd == "rm" then
        return CmdRemove(parsed)
    elseif cmd == "run" then
        return CmdRun(parsed)
    elseif cmd == "test" then
        return CmdTest(parsed)
    elseif cmd == "build" then
        return CmdBuild(parsed)
    elseif cmd == "link" or cmd == "unlink" then
        return CmdLink(parsed)
    elseif cmd == "cache" then
        return CmdCache(parsed)
    elseif cmd == "info" then
        return CmdInfo(parsed)
    elseif cmd == "publish" then
        return CmdPublish(parsed)
    else
        -- If subcommand looks like a file or script name, execute via run
        if cmd:find("%.lua[u]?$") or cmd:find("/") or cmd:find("\\") then
            return CmdRun(parsed)
        else
            -- Check if it is a script name in Packagefile
            local Packagefile = require("../pm/packagefile")
            local manifest = Packagefile.load()
            if manifest and manifest.scripts and manifest.scripts[cmd] then
                return CmdRun(parsed)
            end

            print(Term.red("[error] ") .. "Unknown command: " .. Term.bold(cmd))
            print("Run " .. Term.cyan("klur --help") .. " for available commands.")
            return 1
        end
    end
end

return CLI
