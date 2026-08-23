local Test = require("@klur/test")
local Packagefile = require("../src/pm/packagefile")
local Lockfile = require("../src/pm/lockfile")
local Git = require("../src/pm/git")
local Store = require("../src/pm/store")
local Fs = require("@klur/fs")
local Path = require("@klur/path")
local expect = Test.expect

Test.describe("PM: Package Manager Core", function()
    local tmpDir = Path.join(".", ".test_tmp_pm")

    Test.beforeEach(function()
        Fs.mkdirp(tmpDir)
    end)

    Test.afterEach(function()
        Fs.rimraf(tmpDir)
    end)

    Test.it("should parse and serialize Packagefile", function()
        local manifest: Packagefile.PackageManifest = {
            name = "@myorg/sample",
            version = "1.2.3",
            description = "A sample package",
            main = "src/init.luau",
            scripts = {
                start = "klur run src/init.luau"
            },
            dependencies = {
                ["@klur/net"] = "github:klur-lang/net#v1.0.0"
            },
            devDependencies = {},
        }

        local pkgPath = Path.join(tmpDir, "Packagefile")
        Packagefile.save(manifest, pkgPath)
        expect(Fs.isFile(pkgPath)).toBe(true)

        local loaded, err = Packagefile.load(pkgPath)
        expect(err).toBeNil()
        expect(loaded).toBeDefined()
        expect(loaded.name).toBe("@myorg/sample")
        expect(loaded.version).toBe("1.2.3")
        expect(loaded.dependencies["@klur/net"]).toBe("github:klur-lang/net#v1.0.0")
    end)

    Test.it("should parse git specifiers", function()
        local spec1 = Git.parseSpec("github:org/repo#v1.0.0")
        expect(spec1.kind).toBe("git")
        expect(spec1.url).toBe("https://github.com/org/repo.git")
        expect(spec1.ref).toBe("v1.0.0")

        local spec2 = Git.parseSpec("link:../other-package")
        expect(spec2.kind).toBe("link")
        expect(spec2.url).toBe("../other-package")
    end)

    Test.it("should compute deterministic cache store keys", function()
        local key1 = Store.computeKey("https://github.com/org/repo.git", "v1.0.0")
        local key2 = Store.computeKey("https://github.com/org/repo.git", "v1.0.0")
        local key3 = Store.computeKey("https://github.com/org/repo.git", "v2.0.0")
        expect(key1).toBe(key2)
        expect(key1 ~= key3).toBe(true)
        expect(#key1).toBe(64)
    end)

    Test.it("should load and save Packagefile.lock", function()
        local lockData: Lockfile.LockfileData = {
            lockfileVersion = 1,
            packages = {
                ["@klur/net"] = {
                    version = "1.0.0",
                    source = "git",
                    repository = "https://github.com/klur-lang/net.git",
                    commit = "abc1234567890",
                    dependencies = {},
                }
            }
        }

        Lockfile.save(lockData, tmpDir)
        local loadedLock = Lockfile.load(tmpDir)
        expect(loadedLock).toBeDefined()
        expect(loadedLock.lockfileVersion).toBe(1)
        expect(loadedLock.packages["@klur/net"]).toBeDefined()
        expect(loadedLock.packages["@klur/net"].commit).toBe("abc1234567890")
    end)
end)
