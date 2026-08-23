--!strict
-- klur publish command (Git-based distribution)

local Packagefile = require("@klur/pm/packagefile")
local Process = require("@klur/process")
local Term = require("@klur/term")

return function(_: any): number
    local manifest, err = Packagefile.load()
    if not manifest then
        print(Term.red("[error] ") .. "No valid Packagefile found: " .. tostring(err))
        return 1
    end

    local tag = "v" .. manifest.version
    print(Term.cyan("Publishing Git release ") .. Term.bold(manifest.name .. "@" .. tag) .. "...")

    -- Create git tag
    local tagRes = Process.spawn("git", {"tag", "-a", tag, "-m", "Release " .. tag})
    if not tagRes.ok then
        print(Term.yellow("[warn] ") .. "Could not create tag " .. tag .. ": " .. tagRes.stderr)
    end

    -- Push git tag
    local pushRes = Process.spawn("git", {"push", "origin", tag})
    if pushRes.ok then
        print(Term.green("[ok] ") .. "Successfully pushed release tag " .. Term.bold(tag) .. " to origin")
    else
        print(Term.yellow("[warn] ") .. "Tag created locally. Run 'git push origin " .. tag .. "' to publish.")
    end

    return 0
end
