--!strict
-- klur info command

local Core = require("@klur/core")
local Store = require("@klur/pm/store")
local Term = require("@klur/term")
local Table = require("@klur/term/table")

return function(_: any): number
    print(Term.bold(Core.NAME) .. " - " .. Core.FULL_NAME)
    print(Term.dim("Version: " .. Core.VERSION))
    print("")

    local rows = {
        {"KLUR Version", Core.VERSION},
        {"OS / Platform", Core.getPlatform()},
        {"Architecture", Core.getArch()},
        {"KLUR Home", Core.getKlurHome()},
        {"Cache Store", Store.getStorePath()},
    }

    if _VERSION then
        table.insert(rows, {"Luau Engine", _VERSION})
    end

    print(Table.render({"Property", "Value"}, rows))
    print("")
    return 0
end
