--!strict
-- Rich assertion and expectation framework for KLUR

local Assertions = {}

local function deepEqual(a: any, b: any): boolean
    if a == b then return true end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return false end
    for k, v in pairs(a) do
        if not deepEqual(v, b[k]) then return false end
    end
    for k, _ in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local function formatValue(v: any): string
    if type(v) == "string" then
        return string.format("%q", v)
    elseif type(v) == "table" then
        local _json = (_G :: any).json
        if _json and _json.encode then
            local ok, s = pcall(function() return _json.encode(v) end)
            if ok then return s end
        end
        return tostring(v)
    end
    return tostring(v)
end

function Assertions.expect(actual: any)
    local isNegated = false

    local function assertCond(condition: boolean, message: string)
        if isNegated then
            condition = not condition
            message = "Expected NOT " .. message
        end
        if not condition then
            error(message, 3)
        end
    end

    local exp: any = {}

    local function unwrap(firstArg: any, secondArg: any): any
        if firstArg == exp then
            return secondArg
        end
        return firstArg
    end

    function exp.toBe(a: any, b: any)
        local expected = unwrap(a, b)
        assertCond(
            actual == expected,
            string.format("to be %s, but got %s", formatValue(expected), formatValue(actual))
        )
    end

    function exp.toEqual(a: any, b: any)
        local expected = unwrap(a, b)
        assertCond(
            deepEqual(actual, expected),
            string.format("to deeply equal %s, but got %s", formatValue(expected), formatValue(actual))
        )
    end

    function exp.toBeNil()
        assertCond(
            actual == nil,
            string.format("to be nil, but got %s", formatValue(actual))
        )
    end

    function exp.toBeDefined()
        assertCond(
            actual ~= nil,
            "to be defined, but got nil"
        )
    end

    function exp.toBeTruthy()
        assertCond(
            actual ~= false and actual ~= nil,
            string.format("to be truthy, but got %s", formatValue(actual))
        )
    end

    function exp.toBeFalsy()
        assertCond(
            actual == false or actual == nil,
            string.format("to be falsy, but got %s", formatValue(actual))
        )
    end

    function exp.toContain(a: any, b: any)
        local item = unwrap(a, b)
        local found = false
        if type(actual) == "string" then
            found = (actual :: string):find(tostring(item), 1, true) ~= nil
        elseif type(actual) == "table" then
            for _, v in ipairs(actual :: {any}) do
                if deepEqual(v, item) then
                    found = true
                    break
                end
            end
        end
        assertCond(
            found,
            string.format("to contain %s", formatValue(item))
        )
    end

    function exp.toHaveLength(a: any, b: any)
        local expectedLen = unwrap(a, b)
        local actualLen = (type(actual) == "table" or type(actual) == "string") and #actual or 0
        assertCond(
            actualLen == expectedLen,
            string.format("to have length %d, but got %d", expectedLen, actualLen)
        )
    end

    function exp.toBeGreaterThan(a: any, b: any)
        local expected = unwrap(a, b)
        assertCond(
            type(actual) == "number" and (actual :: number) > expected,
            string.format("to be greater than %s, but got %s", tostring(expected), tostring(actual))
        )
    end

    function exp.toBeLessThan(a: any, b: any)
        local expected = unwrap(a, b)
        assertCond(
            type(actual) == "number" and (actual :: number) < expected,
            string.format("to be less than %s, but got %s", tostring(expected), tostring(actual))
        )
    end

    function exp.toThrow(a: any, b: any)
        local expectedMsg = unwrap(a, b)
        if type(actual) ~= "function" then
            error("toThrow matcher requires a function", 2)
        end
        local ok, err = pcall(actual)
        local threw = not ok
        if threw and expectedMsg then
            local errStr = tostring(err)
            threw = errStr:find(expectedMsg, 1, true) ~= nil
        end
        assertCond(
            threw,
            expectedMsg and string.format("to throw error containing %q", expectedMsg) or "to throw an error"
        )
    end

    exp.never = setmetatable({}, {
        __index = function(_, k)
            isNegated = true
            return exp[k]
        end
    })

    return exp
end

return Assertions
