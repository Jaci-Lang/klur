--!strict
-- KLUR Package Management Suite

local Packagefile = require("@self/packagefile")
local Lockfile = require("@self/lockfile")
local Git = require("@self/git")
local Store = require("@self/store")
local Resolver = require("@self/resolver")
local Installer = require("@self/installer")
local Linker = require("@self/linker")

local PM = {
    Packagefile = Packagefile,
    Lockfile = Lockfile,
    Git = Git,
    Store = Store,
    Resolver = Resolver,
    Installer = Installer,
    Linker = Linker,
    install = Installer.install,
    add = Installer.add,
    remove = Installer.remove,
    link = Linker.link,
    register = Linker.register,
    unlink = Linker.unlink,
}

return PM
