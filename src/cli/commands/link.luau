--!strict
-- klur link and unlink commands

local Linker = require("@klur/pm/linker")
local Term = require("@klur/term")

return function(args: any): number
    local isUnlink = args.subcommand == "unlink"
    local target = args.positional[1]

    if isUnlink then
        local ok = Linker.unlink(target, ".")
        return ok and 0 or 1
    else
        if target and target ~= "" then
            local ok = Linker.link(target, ".")
            return ok and 0 or 1
        else
            local ok = Linker.register(".")
            return ok and 0 or 1
        end
    end
end
