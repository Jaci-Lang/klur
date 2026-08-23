local Test = require("@klur/test")
local Path = require("@klur/path")
local expect = Test.expect

Test.describe("Std: Path", function()
    Test.it("should normalize POSIX and relative paths", function()
        expect(Path.normalize("a/b/../c/./d")).toBe("a/c/d")
        expect(Path.normalize("a///b//c")).toBe("a/b/c")
        expect(Path.normalize("./foo/bar")).toBe("foo/bar")
    end)

    Test.it("should join path segments", function()
        expect(Path.join("src", "core", "init.luau")).toBe("src/core/init.luau")
        expect(Path.join("a", "b", "..", "c")).toBe("a/c")
    end)

    Test.it("should extract dirname", function()
        expect(Path.dirname("src/core/init.luau")).toBe("src/core")
        expect(Path.dirname("foo.luau")).toBe(".")
    end)

    Test.it("should extract basename with and without ext", function()
        expect(Path.basename("src/core/init.luau")).toBe("init.luau")
        expect(Path.basename("src/core/init.luau", ".luau")).toBe("init")
    end)

    Test.it("should extract extname", function()
        expect(Path.extname("src/core/init.luau")).toBe(".luau")
        expect(Path.extname("README.md")).toBe(".md")
        expect(Path.extname("Packagefile")).toBe("")
    end)

    Test.it("should check absolute paths", function()
        expect(Path.isAbsolute("/usr/local/bin")).toBe(true)
        expect(Path.isAbsolute("src/main.luau")).toBe(false)
        expect(Path.isAbsolute("./main.luau")).toBe(false)
    end)
end)
