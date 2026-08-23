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
        if arg:sub(1, 2) == "--" then
            local key, val = arg:sub(3):match("^([^=]+)=(.*)$")
            if key then
                options[key] = val
            else
                local flag = arg:sub(3)
                if i + 1 <= #argv and argv[i + 1]:sub(1, 1) ~= "-" then
                    options[flag] = argv[i + 1]
                    i = i + 1
                else
                    options[flag] = true
                end
            end
        elseif arg:sub(1, 1) == "-" and #arg > 1 then
            local flag = arg:sub(2)
            if i + 1 <= #argv and argv[i + 1]:sub(1, 1) ~= "-" then
                options[flag] = argv[i + 1]
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
