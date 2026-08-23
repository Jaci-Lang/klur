--!strict
-- klur build command (Bundles standalone binary using Jaci's Single Binary Compiler)

local Core = require("@klur/core")
local Fs = require("@klur/fs")
local Path = require("@klur/path")
local Process = require("@klur/process")
local Term = require("@klur/term")

return function(args: any): number
    local entry = args.positional[1] or "src/init.luau"
    local output = args.options["output"] or args.options["o"] or Path.basename(entry, ".luau")
    local codegen = args.options["codegen"] or true
    local strip = args.options["strip"] or false
    local compress = args.options["compress"] or false

    if not Fs.isFile(entry) then
        print(Term.red("[error] ") .. "Entry file not found: " .. entry)
        return 1
    end

    local outDir = Path.dirname(output)
    if outDir ~= "." and outDir ~= "" then
        Fs.mkdirp(outDir)
    end

    print(Term.cyan("Building standalone native executable: ") .. Term.bold(entry) .. " -> " .. Term.bold(output))

    local luauBin = Core.getLuauBinary()
    local buildArgs = {"--build", entry, "-o", output, "--direct"}

    if codegen then table.insert(buildArgs, "--codegen") end
    if strip then table.insert(buildArgs, "--strip") end
    if compress then table.insert(buildArgs, "--compress") end

    local res = Process.spawn(luauBin, buildArgs)
    if not res.ok then
        print(Term.red("[error] ") .. "Build failed:")
        if #res.stderr > 0 then print(res.stderr) end
        return res.exitCode
    end

    print(Term.green("[ok] ") .. "Successfully built " .. Term.bold(output))
    return 0
end
