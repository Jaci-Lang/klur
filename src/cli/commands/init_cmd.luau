--!strict
-- klur init command

local Fs = require("@klur/fs")
local Path = require("@klur/path")
local Packagefile = require("@klur/pm/packagefile")
local Store = require("@klur/pm/store")
local Term = require("@klur/term")
local Prompt = require("@klur/term/prompt")

return function(args: any): number
    local cwd = Path.resolve(".")
    local defaultName = Path.basename(cwd)
    local isInteractive = not args.options["yes"] and not args.options["y"]

    local name = defaultName
    local version = "0.1.0"
    local description = "A modern Luau project built with KLUR"

    if isInteractive and Term.isEnabled() then
        name = Prompt.ask("Package name", defaultName)
        version = Prompt.ask("Version", "0.1.0")
        description = Prompt.ask("Description", description)
    end

    local manifest: Packagefile.PackageManifest = {
        name = name,
        version = version,
        description = description,
        main = "src/init.luau",
        scripts = {
            start = "klur run src/init.luau",
            test = "klur test",
            build = "klur build src/init.luau --output dist/" .. name,
        },
        dependencies = {},
        devDependencies = {},
        license = "MIT",
    }

    Packagefile.save(manifest, "Packagefile")
    Fs.mkdirp("src")
    Fs.mkdirp("tests")

    if not Fs.exists("src/init.luau") then
        Fs.writeFile("src/init.luau", [[-- Entry point
print("Hello from " .. "]] .. name .. [[" .. "!")
]])
    end

    if not Fs.exists("tests/main.test.luau") then
        Fs.writeFile("tests/main.test.luau", [[local Test = require("@klur/test")
local expect = Test.expect

Test.describe("]] .. name .. [[", function()
    Test.it("should work correctly", function()
        expect(1 + 1).toBe(2)
    end)
end)
]])
    end

    if not Fs.exists(".gitignore") then
        Fs.writeFile(".gitignore", [[klur_modules/
dist/
.klur/
*.tmp
*.log
]])
    end

    -- Link standard @klur batteries into klur_modules
    local currentFile = debug.info(1, "s")
    if currentFile:sub(1, 1) == "@" then
        currentFile = currentFile:sub(2)
    end
    local klurRoot = Path.resolve(Path.join(Path.dirname(currentFile), "../../.."))
    local klurSrcMod = Path.join(klurRoot, "klur_modules", "@klur")
    if Fs.exists(klurSrcMod) then
        local targetKlurMod = Path.join("klur_modules", "@klur")
        Fs.mkdirp(targetKlurMod)
        local entries = Fs.readDir(klurSrcMod)
        for _, entry in ipairs(entries) do
            local srcPkg = Path.join(klurSrcMod, entry)
            local targetPkg = Path.join(targetKlurMod, entry)
            Store.linkInto(srcPkg, targetPkg)
        end
    end

    print(Term.green("[ok] ") .. "Initialized KLUR project in " .. Term.bold(cwd))
    print("  Run " .. Term.cyan("klur run src/init.luau") .. " to start")
    print("  Run " .. Term.cyan("klur test") .. " to run tests")
    return 0
end
