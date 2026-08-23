--!strict
-- klur remove / klur rm command

local Installer = require("@klur/pm/installer")
local Term = require("@klur/term")

return function(args: any): number
    local pkgName = args.positional[1]
    if not pkgName or pkgName == "" then
        print(Term.red("[error] ") .. "Usage: klur remove <package-name>")
        return 1
    end
    local ok = Installer.remove(pkgName, ".")
    return ok and 0 or 1
end
