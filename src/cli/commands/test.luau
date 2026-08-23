--!strict
-- klur test command

local Fs = require("@klur/fs")
local Path = require("@klur/path")
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
        -- Load the test file via loadstring with an @-prefixed chunkname so
        -- that the require navigator accepts it. A plain file-path chunkname
        -- is rejected by the ReplRequirer's is_require_allowed check.
        local contents = Fs.readFile(file)
        local chunkname = "@" .. file
        local chunk, err = loadstring(contents, chunkname)
        if not chunk then
            print(Term.red("[error] ") .. "Failed to compile test file " .. file .. ": " .. tostring(err))
            totalPassed = false
        else
            local ok, runErr = pcall(chunk)
            if not ok then
                print(Term.red("[error] ") .. "Error during test file " .. file .. ": " .. tostring(runErr))
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
