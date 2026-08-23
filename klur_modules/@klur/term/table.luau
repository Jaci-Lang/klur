--!strict
-- ASCII/Unicode Table Formatter for KLUR

local Term = require("@klur/term")

local Table = {}

function Table.render(headers: {string}, rows: {{string}}): string
    local colWidths: {number} = {}
    for i, h in ipairs(headers) do
        colWidths[i] = #Term.stripAnsi(h)
    end

    for _, row in ipairs(rows) do
        for i, cell in ipairs(row) do
            local len = #Term.stripAnsi(tostring(cell or ""))
            if not colWidths[i] or len > colWidths[i] then
                colWidths[i] = len
            end
        end
    end

    local function pad(s: string, width: number): string
        local visibleLen = #Term.stripAnsi(s)
        local diff = width - visibleLen
        if diff <= 0 then return s end
        return s .. string.rep(" ", diff)
    end

    local out = {}
    local headerLine = {}
    for i, h in ipairs(headers) do
        table.insert(headerLine, Term.bold(pad(h, colWidths[i])))
    end
    table.insert(out, table.concat(headerLine, "   "))

    local sepLine = {}
    for i = 1, #headers do
        table.insert(sepLine, string.rep("-", colWidths[i]))
    end
    table.insert(out, Term.dim(table.concat(sepLine, "   ")))

    for _, row in ipairs(rows) do
        local line = {}
        for i = 1, #headers do
            local cell = tostring(row[i] or "")
            table.insert(line, pad(cell, colWidths[i]))
        end
        table.insert(out, table.concat(line, "   "))
    end

    return table.concat(out, "\n")
end

return Table
