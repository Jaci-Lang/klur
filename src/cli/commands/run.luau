--!strict
-- klur run command
--
-- Executes the target script in-process: the running binary IS the Jaci
-- runtime, so compiling and pcall-ing the file directly is both correct and
-- fast. Spawning an external `luau` is impossible in a self-contained single
-- binary (no engine on PATH) and was the cause of `klur run` exiting
-- silently with code 127.

local Fs = require("@klur/fs")
local Path = require("@klur/path")
local Packagefile = require("@klur/pm/packagefile")
local Process = require("@klur/process")
local Term = require("@klur/term")

-- Compile and execute source in the current VM. The @-prefixed absolute
-- chunkname lets the require navigator resolve relative requires against the
-- script's own directory, and matches the convention the test runner uses.
local function runInProcess(target: string, restArgs: {string}): number
    local abs = Path.resolve(target)
    local source = Fs.readFileOpt(abs)
    if not source then
        print(Term.red("[error] ") .. "Could not read: " .. target)
        return 1
    end

    local compile = loadstring or load
    local chunk, err = compile(source, "@" .. abs)
    if not chunk then
        print(Term.red("[error] ") .. "Failed to compile " .. target .. ":")
        print(Term.red(tostring(err)))
        return 1
    end

    local ok, result = pcall(chunk, table.unpack(restArgs))
    if not ok then
        io.stderr:write(tostring(result) .. "\n")
        return 1
    end
    return 0
end

return function(args: any): number
    local target = args.positional[1] or args.subcommand
    if not target or target == "" then
        -- Default to main in Packagefile
        local manifest = Packagefile.load()
        if manifest and manifest.main and Fs.isFile(manifest.main) then
            target = manifest.main
        else
            print(Term.red("[error] ") .. "No file or script specified to run")
            return 1
        end
    end

    -- Named Packagefile scripts are shell command lines; execute them as-is.
    local manifest = Packagefile.load()
    if manifest and manifest.scripts and manifest.scripts[target] then
        local scriptCmd = manifest.scripts[target]
        print(Term.dim("$ " .. scriptCmd))
        local res = Process.execRaw(scriptCmd)
        if #res.stdout > 0 then io.write(res.stdout) end
        if #res.stderr > 0 then io.stderr:write(res.stderr) end
        return res.exitCode
    end

    -- Resolve file target (try .luau, .lua, and dir/init.luau)
    if not Fs.isFile(target) then
        if Fs.isFile(target .. ".luau") then
            target = target .. ".luau"
        elseif Fs.isFile(target .. ".lua") then
            target = target .. ".lua"
        elseif Fs.isFile(Path.join(target, "init.luau")) then
            target = Path.join(target, "init.luau")
        else
            print(Term.red("[error] ") .. "Target file not found: " .. target)
            return 1
        end
    end

    local restArgs: {string} = {}
    for i = 2, #args.positional do
        table.insert(restArgs, args.positional[i])
    end

    return runInProcess(target, restArgs)
end
