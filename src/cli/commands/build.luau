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

    -- Prefer the engine this klur is running on: in source mode it is the
    -- luau binary; in a single binary it is the binary itself, which accepts
    -- --build as an engine flag. Fall back to PATH/build-dir discovery.
    local builder = (process and process.executable) or Core.getLuauBinary()
    local buildArgs = {"--build", entry, "-o", output, "--direct"}

    if codegen then table.insert(buildArgs, "--codegen") end
    if strip then table.insert(buildArgs, "--strip") end
    if compress then table.insert(buildArgs, "--compress") end

    -- Solver: embed the package directories the static graph cannot reach.
    -- Project-local packages are found by the runtime walk-up on their own,
    -- but modules only reached through dynamically-loaded chunks (test files
    -- via loadstring) and the toolchain packages living next to the engine
    -- must be carried explicitly. The engine stays neutral: it only embeds
    -- what it is told to.
    local function addEmbed(dir: string)
        if dir ~= "" and Fs.isDir(dir) then
            table.insert(buildArgs, "--embed")
            table.insert(buildArgs, dir)
        end
    end

    local pkgDirNames = {"klur_modules", "luau_packages", "packages", "node_modules"}
    local cwd = Process.cwd()
    for _, name in pkgDirNames do
        addEmbed(Path.join(cwd, name))
    end

    local exeDir = Path.dirname(builder)
    for _, name in pkgDirNames do
        addEmbed(Path.join(exeDir, name))
    end

    local res = Process.spawn(builder, buildArgs)
    if #res.stderr > 0 then io.stderr:write(res.stderr) end
    if #res.stdout > 0 then io.write(res.stdout) end
    if not res.ok then
        print(Term.red("[error] ") .. "Build failed (exit code " .. res.exitCode .. ")")
        return res.exitCode
    end

    print(Term.green("[ok] ") .. "Successfully built " .. Term.bold(output))
    return 0
end
