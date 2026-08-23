--!strict
-- klur cache command

local Store = require("@klur/pm/store")
local Core = require("@klur/core")
local Term = require("@klur/term")

return function(args: any): number
    local action = args.positional[1] or "dir"

    if action == "dir" or action == "path" then
        print(Store.getStorePath())
        return 0
    elseif action == "clean" or action == "clear" then
        Store.clean()
        print(Term.green("[ok] ") .. "Cleared KLUR global cache store")
        return 0
    elseif action == "list" or action == "ls" then
        local entries = Store.list()
        print(Term.bold(string.format("KLUR Cache Store (%d entries):", #entries)))
        for _, e in ipairs(entries) do
            print("  - " .. e)
        end
        return 0
    else
        print(Term.red("[error] ") .. "Unknown cache action: " .. action .. ". Use 'dir', 'list', or 'clean'.")
        return 1
    end
end
