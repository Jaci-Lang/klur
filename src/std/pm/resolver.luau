--!strict
-- Dependency Resolution and Graph Solving for KLUR

local Git = require("./git")
local Store = require("./store")
local Packagefile = require("./packagefile")
local Lockfile = require("./lockfile")
local Fs = require("@klur/fs")
local Path = require("@klur/path")

export type ResolvedNode = {
    name: string,
    spec: string,
    version: string,
    source: string,
    repository: string?,
    commit: string?,
    storePath: string,
    dependencies: {[string]: string},
}

local Resolver = {}

function Resolver.resolveTree(
    rootDependencies: {[string]: string},
    lock: Lockfile.LockfileData?,
    logProgress: ((msg: string) -> ())?
): ({[string]: ResolvedNode}, {string})

    local resolved: {[string]: ResolvedNode} = {}
    local queue: {{name: string, spec: string}} = {}
    local errors: {string} = {}
    local visitedSpecs: {[string]: boolean} = {}

    for name, spec in pairs(rootDependencies) do
        table.insert(queue, { name = name, spec = spec })
    end

    while #queue > 0 do
        local item = table.remove(queue, 1) :: {name: string, spec: string}
        local name = item.name
        local spec = item.spec

        if not resolved[name] then
            if logProgress then
                logProgress("Resolving " .. name .. " (" .. spec .. ")")
            end

            local parsed = Git.parseSpec(spec)
            local node: ResolvedNode? = nil

            if parsed.kind == "link" or parsed.kind == "path" then
                local localPath = Path.resolve(parsed.url or ".")
                local innerPkg = Packagefile.load(Path.join(localPath, "Packagefile"))
                node = {
                    name = name,
                    spec = spec,
                    version = (innerPkg and innerPkg.version) or "0.0.0",
                    source = parsed.kind,
                    repository = nil,
                    commit = nil,
                    storePath = localPath,
                    dependencies = (innerPkg and innerPkg.dependencies) or {},
                }
            elseif parsed.kind == "git" then
                local url = parsed.url or ""
                local ref = parsed.ref
                local locked = lock and lock.packages and lock.packages[name]

                local commit = (locked and locked.commit) or ref
                local key = Store.computeKey(url, commit)
                local storePath = Store.getEntryPath(key)

                if not Store.has(key) then
                    local ok, err = Git.clone(url, storePath, ref)
                    if not ok then
                        table.insert(errors, "Failed to clone " .. name .. " from " .. url .. ": " .. tostring(err))
                    end
                end

                local realCommit = Git.getHeadCommit(storePath) or commit
                local innerPkg = Packagefile.load(Path.join(storePath, "Packagefile"))

                node = {
                    name = name,
                    spec = spec,
                    version = (innerPkg and innerPkg.version) or (ref or "0.0.0"),
                    source = "git",
                    repository = url,
                    commit = realCommit,
                    storePath = storePath,
                    dependencies = (innerPkg and innerPkg.dependencies) or {},
                }
            else
                -- Version fallback or unsupported registry
                node = {
                    name = name,
                    spec = spec,
                    version = spec,
                    source = "version",
                    repository = nil,
                    commit = nil,
                    storePath = "",
                    dependencies = {},
                }
            end

            if node then
                resolved[name] = node
                if node.dependencies then
                    for depName, depSpec in pairs(node.dependencies) do
                        if not resolved[depName] then
                            table.insert(queue, { name = depName, spec = depSpec })
                        end
                    end
                end
            end
        end
    end

    return resolved, errors
end

return Resolver
