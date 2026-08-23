--!strict
-- Terminal styling, colors, and ANSI helpers for KLUR

local Term = {}

local function hasColorSupport(): boolean
    local noColor = os.getenv("NO_COLOR")
    if noColor and noColor ~= "" then return false end
    local term = os.getenv("TERM")
    if term == "dumb" then return false end
    return true
end

local enabled = hasColorSupport()

function Term.setEnabled(val: boolean)
    enabled = val
end

function Term.isEnabled(): boolean
    return enabled
end

local function code(open: string, close: string)
    return function(s: string): string
        if not enabled then return s end
        return "\27[" .. open .. "m" .. s .. "\27[" .. close .. "m"
    end
end

Term.reset = "\27[0m"
Term.bold = code("1", "22")
Term.dim = code("2", "22")
Term.italic = code("3", "23")
Term.underline = code("4", "24")

Term.black = code("30", "39")
Term.red = code("31", "39")
Term.green = code("32", "39")
Term.yellow = code("33", "39")
Term.blue = code("34", "39")
Term.magenta = code("35", "39")
Term.cyan = code("36", "39")
Term.white = code("37", "39")
Term.gray = code("90", "39")

Term.bgRed = code("41", "49")
Term.bgGreen = code("42", "49")
Term.bgYellow = code("43", "49")
Term.bgBlue = code("44", "49")
Term.bgMagenta = code("45", "49")
Term.bgCyan = code("46", "49")
Term.bgWhite = code("47", "49")

function Term.stripAnsi(str: string): string
    return (str:gsub("\27%[[0-9;]*m", ""))
end

return Term
