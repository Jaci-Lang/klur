local Test = require("@klur/test")
local Fs = require("@klur/fs")
local Path = require("@klur/path")
local expect = Test.expect

Test.describe("Std: Filesystem", function()
    local tmpDir = Path.join(".", ".test_tmp_fs")

    Test.beforeEach(function()
        Fs.mkdirp(tmpDir)
    end)

    Test.afterEach(function()
        Fs.rimraf(tmpDir)
    end)

    Test.it("should write and read files", function()
        local testFile = Path.join(tmpDir, "hello.txt")
        Fs.writeFile(testFile, "Hello KLUR!")
        expect(Fs.exists(testFile)).toBe(true)
        expect(Fs.readFile(testFile)).toBe("Hello KLUR!")
    end)

    Test.it("should stat files and directories correctly", function()
        local testFile = Path.join(tmpDir, "stat_test.txt")
        Fs.writeFile(testFile, "12345")
        local s = Fs.stat(testFile)
        expect(s).toBeDefined()
        expect(s.isFile).toBe(true)
        expect(s.isDirectory).toBe(false)
        expect(s.size).toBe(5)

        local dirStat = Fs.stat(tmpDir)
        expect(dirStat).toBeDefined()
        expect(dirStat.isDirectory).toBe(true)
    end)

    Test.it("should support mkdirp and rimraf recursively", function()
        local nested = Path.join(tmpDir, "a", "b", "c", "d")
        Fs.mkdirp(nested)
        expect(Fs.isDir(nested)).toBe(true)

        local f = Path.join(nested, "item.txt")
        Fs.writeFile(f, "data")
        expect(Fs.isFile(f)).toBe(true)

        Fs.rimraf(Path.join(tmpDir, "a"))
        expect(Fs.exists(Path.join(tmpDir, "a"))).toBe(false)
    end)

    Test.it("should read and write JSON files", function()
        local jsonFile = Path.join(tmpDir, "test.json")
        local payload = { name = "klur", count = 42, active = true }
        Fs.writeJson(jsonFile, payload)
        local loaded = Fs.readJson(jsonFile)
        expect(loaded).toBeDefined()
        expect(loaded.name).toBe("klur")
        expect(loaded.count).toBe(42)
        expect(loaded.active).toBe(true)
    end)

    Test.it("should copy files and directories", function()
        local srcFile = Path.join(tmpDir, "orig.txt")
        local dstFile = Path.join(tmpDir, "copy.txt")
        Fs.writeFile(srcFile, "copy test content")
        Fs.copyFile(srcFile, dstFile)
        expect(Fs.readFile(dstFile)).toBe("copy test content")
    end)
end)
