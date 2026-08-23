--!strict
-- Interactive CLI prompt utilities for KLUR

local Term = require("@klur/term")

local Prompt = {}

function Prompt.ask(question: string, defaultVal: string?): string
    local promptStr = Term.cyan("? ") .. Term.bold(question)
    if defaultVal and defaultVal ~= "" then
        promptStr = promptStr .. Term.dim(" (" .. defaultVal .. ")")
    end
    promptStr = promptStr .. ": "
    io.write(promptStr)
    io.flush()
    local answer = io.read("*l")
    if not answer or answer == "" then
        return defaultVal or ""
    end
    return answer
end

function Prompt.confirm(question: string, defaultYes: boolean?): boolean
    local defaultStr = defaultYes ~= false and "Y/n" or "y/N"
    local promptStr = Term.cyan("? ") .. Term.bold(question) .. Term.dim(" (" .. defaultStr .. "): ")
    io.write(promptStr)
    io.flush()
    local answer = io.read("*l")
    if not answer or answer == "" then
        return defaultYes ~= false
    end
    answer = answer:lower()
    return answer == "y" or answer == "yes" or answer == "sim" or answer == "s"
end

return Prompt
