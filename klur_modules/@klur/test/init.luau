--!strict
-- Standard Test Suite for KLUR

local Runner = require("@self/runner")
local Assertions = require("@self/assertions")

local Test = {
    describe = Runner.describe,
    test = Runner.test,
    it = Runner.it,
    beforeEach = Runner.beforeEach,
    afterEach = Runner.afterEach,
    expect = Assertions.expect,
    run = Runner.run,
    report = Runner.report,
    clear = Runner.clear,
}

return Test
