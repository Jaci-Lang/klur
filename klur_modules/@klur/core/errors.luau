--!strict
-- Error handling and backtrace formatting utilities for KLUR

local Errors = {}

export type KlurError = {
    name: string,
    message: string,
    stack: string?,
    code: string?,
}

function Errors.new(name: string, message: string, code: string?): KlurError
    local stack = debug.traceback("", 2)
    return {
        name = name,
        message = message,
        stack = stack,
        code = code,
    }
end

function Errors.format(err: any): string
    if type(err) == "table" and err.name and err.message then
        local out = string.format("error[%s]: %s", err.name, err.message)
        if err.stack then
            out = out .. "\n" .. err.stack
        end
        return out
    end
    return tostring(err)
end

return Errors
