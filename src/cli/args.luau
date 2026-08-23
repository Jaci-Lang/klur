--!strict
-- Command-line argument parser for KLUR

export type ParsedArgs = {
    subcommand: string?,
    positional: {string},
    options: {[string]: any},
    raw: {string},
}

local Args = {}

function Args.parse(argv: {string}): ParsedArgs
    local positional: {string} = {}
    local options: {[string]: any} = {}
    local subcommand: string? = nil
    local i = 1

    while i <= #argv do
        local arg = argv[i]
        if not arg then break end
        if arg:sub(1, 2) == "--" then
            local key, val = arg:sub(3):match("^([^=]+)=(.*)$")
            if key then
                options[key] = val
            else
                local flag = arg:sub(3)
                local nextArg = argv[i + 1]
                if nextArg ~= nil and nextArg:sub(1, 1) ~= "-" then
                    options[flag] = nextArg
                    i = i + 1
                else
                    options[flag] = true
                end
            end
        elseif arg:sub(1, 1) == "-" and #arg > 1 then
            local flag = arg:sub(2)
            local nextArg = argv[i + 1]
            if nextArg ~= nil and nextArg:sub(1, 1) ~= "-" then
                options[flag] = nextArg
                i = i + 1
            else
                options[flag] = true
            end
        else
            if not subcommand and #positional == 0 then
                subcommand = arg
            else
                table.insert(positional, arg)
            end
        end
        i = i + 1
    end

    return {
        subcommand = subcommand,
        positional = positional,
        options = options,
        raw = argv,
    }
end

return Args
