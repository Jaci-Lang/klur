local Core = require("@klur/core")
local Fs = require("@klur/fs")
local Path = require("@klur/path")
local Packagefile = require("@klur/pm/packagefile")
local Process = require("@klur/process")
local Term = require("@klur/term")

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

    -- Check if target is a script defined in Packagefile
    local manifest = Packagefile.load()
    if manifest and manifest.scripts and manifest.scripts[target] then
        local scriptCmd = manifest.scripts[target]
        print(Term.dim("$ " .. scriptCmd))
        local res = Process.execRaw(scriptCmd)
        if #res.stdout > 0 then io.write(res.stdout) end
        if #res.stderr > 0 then io.stderr:write(res.stderr) end
        return res.exitCode
    end

    -- Check if file exists
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

    -- Execute with Jaci
    local luauBin = Core.getLuauBinary()
    local restArgs = {}
    for i = 2, #args.positional do
        table.insert(restArgs, args.positional[i])
    end

    local execArgs = { target }
    for _, a in ipairs(restArgs) do table.insert(execArgs, a) end

    local res = Process.spawn(luauBin, execArgs)
    if #res.stdout > 0 then io.write(res.stdout) end
    if #res.stderr > 0 then io.stderr:write(res.stderr) end
    return res.exitCode
end
