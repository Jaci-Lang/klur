--!strict
-- CLI Spinner for long operations in KLUR

local Term = require("@klur/term")

local frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

local Spinner = {}
Spinner.__index = Spinner

export type SpinnerInstance = {
    message: string,
    idx: number,
    active: boolean,
    start: (self: SpinnerInstance, msg: string?) -> (),
    update: (self: SpinnerInstance, msg: string) -> (),
    stop: (self: SpinnerInstance) -> (),
    succeed: (self: SpinnerInstance, msg: string?) -> (),
    fail: (self: SpinnerInstance, msg: string?) -> (),
}

function Spinner.new(initialMsg: string?): SpinnerInstance
    local self = setmetatable({
        message = initialMsg or "",
        idx = 1,
        active = false,
    }, Spinner)
    return self :: any
end

function Spinner:start(msg: string?)
    if msg then self.message = msg end
    self.active = true
    if Term.isEnabled() then
        io.write(Term.cyan(frames[self.idx]) .. " " .. self.message)
        io.flush()
    else
        print("-> " .. self.message)
    end
end

function Spinner:tick()
    if not self.active or not Term.isEnabled() then return end
    self.idx = (self.idx % #frames) + 1
    io.write("\r\27[K" .. Term.cyan(frames[self.idx]) .. " " .. self.message)
    io.flush()
end

function Spinner:update(msg: string)
    self.message = msg
    self:tick()
end

function Spinner:stop()
    self.active = false
    if Term.isEnabled() then
        io.write("\r\27[K")
        io.flush()
    end
end

function Spinner:succeed(msg: string?)
    self:stop()
    local text = msg or self.message
    print(Term.green("[ok]") .. " " .. text)
end

function Spinner:fail(msg: string?)
    self:stop()
    local text = msg or self.message
    print(Term.red("[error]") .. " " .. text)
end

return Spinner
