--!strict
-- Test Discovery, Execution Engine, and Reporting for KLUR

local Term = require("@klur/term")
local Assertions = require("./assertions")

export type TestCase = {
    name: string,
    fn: () -> (),
}

export type TestSuite = {
    name: string,
    tests: {TestCase},
    beforeEach: {() -> ()},
    afterEach: {() -> ()},
}

export type TestResult = {
    suite: string,
    name: string,
    passed: boolean,
    durationMs: number,
    error: string?,
}

if not (_G :: any).__KLUR_TEST_SUITES__ then
    (_G :: any).__KLUR_TEST_SUITES__ = {}
end

local function getSuites(): {TestSuite}
    return (_G :: any).__KLUR_TEST_SUITES__
end

local function getCurrentSuite(): TestSuite?
    return (_G :: any).__KLUR_CURRENT_SUITE__
end

local function setCurrentSuite(s: TestSuite?)
    (_G :: any).__KLUR_CURRENT_SUITE__ = s
end

local Runner = {
    expect = Assertions.expect,
}

function Runner.describe(name: string, fn: () -> ())
    local suite: TestSuite = {
        name = name,
        tests = {},
        beforeEach = {},
        afterEach = {},
    }
    table.insert(getSuites(), suite)
    local prev = getCurrentSuite()
    setCurrentSuite(suite)
    fn()
    setCurrentSuite(prev)
end

function Runner.test(name: string, fn: () -> ())
    local cur = getCurrentSuite()
    if not cur then
        Runner.describe("Default", function() end)
        cur = getCurrentSuite()
    end
    if cur then
        table.insert(cur.tests, {
            name = name,
            fn = fn,
        })
    end
end

Runner.it = Runner.test

function Runner.beforeEach(fn: () -> ())
    local cur = getCurrentSuite()
    if cur then
        table.insert(cur.beforeEach, fn)
    end
end

function Runner.afterEach(fn: () -> ())
    local cur = getCurrentSuite()
    if cur then
        table.insert(cur.afterEach, fn)
    end
end

function Runner.clear()
    (_G :: any).__KLUR_TEST_SUITES__ = {}
    (_G :: any).__KLUR_CURRENT_SUITE__ = nil
end

function Runner.run(): {TestResult}
    local results: {TestResult} = {}

    for _, suite in ipairs(getSuites()) do
        for _, t in ipairs(suite.tests) do
            for _, be in ipairs(suite.beforeEach) do
                be()
            end

            local start = os.clock()
            local ok, err = pcall(t.fn)
            local elapsedMs = (os.clock() - start) * 1000

            for _, ae in ipairs(suite.afterEach) do
                pcall(ae)
            end

            table.insert(results, {
                suite = suite.name,
                name = t.name,
                passed = ok,
                durationMs = elapsedMs,
                error = not ok and tostring(err) or nil,
            })
        end
    end

    return results
end

function Runner.report(results: {TestResult}, totalDurationMs: number): boolean
    local passedCount = 0
    local failedCount = 0

    print("")
    for _, res in ipairs(results) do
        if res.passed then
            passedCount = passedCount + 1
            print(string.format("  %s %s > %s %s",
                Term.green("✓"),
                Term.dim(res.suite),
                res.name,
                Term.dim(string.format("(%.1fms)", res.durationMs))
            ))
        else
            failedCount = failedCount + 1
            print(string.format("  %s %s > %s %s",
                Term.red("✗"),
                Term.dim(res.suite),
                Term.bold(res.name),
                Term.dim(string.format("(%.1fms)", res.durationMs))
            ))
            if res.error then
                print(Term.red("    " .. res.error:gsub("\n", "\n    ")))
            end
        end
    end

    print("")
    local summaryStr = string.format("Tests:  %s%s, %d total",
        passedCount > 0 and Term.green(string.format("%d passed", passedCount)) or "",
        failedCount > 0 and (", " .. Term.red(string.format("%d failed", failedCount))) or "",
        #results
    )
    local timeStr = string.format("Time:   %.2fms", totalDurationMs)
    print(summaryStr)
    print(timeStr)
    print("")

    return failedCount == 0
end

return Runner
