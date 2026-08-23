--!strict
-- klur test command

local Fs = require("@klur/fs")
local Path = require("@klur/path")
local Process = require("@klur/process")
local TestRunner = require("@klur/test/runner")
local Term = require("@klur/term")

return function(args: any): number
    local testPattern = args.positional[1] or "*.test.luau"
    local files = Fs.glob(testPattern, ".")

    -- Also check for spec files if none found
    if #files == 0 then
        files = Fs.glob("*.spec.luau", ".")
    end

    if #files == 0 then
        print(Term.yellow("[warn] ") .. "No test files matching " .. testPattern .. " found.")
        return 0
    end

    print(Term.bold("Running KLUR Test Suite..."))
    local startTime = os.clock()
    local totalPassed = true

    for _, file in ipairs(files) do
        TestRunner.clear()
        local chunk, err = loadfile(file)
        if not chunk then
            print(Term.red("[error] ") .. "Failed to load test file " .. file .. ": " .. tostring(err))
            totalPassed = false
        else
            local ok, runErr = pcall(chunk)
            if not ok then
                print(Term.red("[error] ") .. "Error during test file evaluation " .. file .. ": " .. tostring(runErr))
                totalPassed = false
            else
                local results = TestRunner.run()
                local suitePassed = TestRunner.report(results, (os.clock() - startTime) * 1000)
                if not suitePassed then
                    totalPassed = false
                end
            end
        end
    end

    return totalPassed and 0 or 1
end
