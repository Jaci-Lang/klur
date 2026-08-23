--!strict
-- klur install / klur add command

local Installer = require("@klur/pm/installer")
local Term = require("@klur/term")

return function(args: any): number
    local spec = args.positional[1]
    if spec and spec ~= "" then
        local isDev = args.options["dev"] or args.options["D"] or false
        local ok = Installer.add(spec, ".", isDev)
        return ok and 0 or 1
    else
        local ok, errors = Installer.install(".", { includeDev = not args.options["prod"] })
        if not ok then
            for _, err in ipairs(errors) do
                print(Term.red("[error] ") .. err)
            end
            return 1
        end
        return 0
    end
end
