--!strict
-- High Performance Data Structures and Collections for KLUR

-- ============================================================================
-- Queue (O(1) Enqueue / Dequeue)
-- ============================================================================
export type Queue<T> = {
    push: (self: Queue<T>, item: T) -> (),
    pop: (self: Queue<T>) -> T?,
    peek: (self: Queue<T>) -> T?,
    size: (self: Queue<T>) -> number,
    isEmpty: (self: Queue<T>) -> boolean,
    clear: (self: Queue<T>) -> (),
    toArray: (self: Queue<T>) -> {T},
}

local QueueImpl = {}
QueueImpl.__index = QueueImpl

function QueueImpl.new<T>(): Queue<T>
    local self = setmetatable({
        _head = 1,
        _tail = 0,
        _items = {} :: {T},
    }, QueueImpl)
    return (self :: any) :: Queue<T>
end

function QueueImpl.push(self: any, item: any)
    self._tail += 1
    self._items[self._tail] = item
end

function QueueImpl.pop(self: any): any?
    if self._head > self._tail then
        return nil
    end
    local item = self._items[self._head]
    self._items[self._head] = nil
    self._head += 1

    -- Periodic compaction
    if self._head > 1000 and self._head > self._tail / 2 then
        local newItems = {}
        local count = 0
        for i = self._head, self._tail do
            count += 1
            newItems[count] = self._items[i]
        end
        self._items = newItems
        self._head = 1
        self._tail = count
    end

    return item
end

function QueueImpl.peek(self: any): any?
    if self._head > self._tail then return nil end
    return self._items[self._head]
end

function QueueImpl.size(self: any): number
    return math.max(0, self._tail - self._head + 1)
end

function QueueImpl.isEmpty(self: any): boolean
    return (self :: any):size() == 0
end

function QueueImpl.clear(self: any)
    self._items = {}
    self._head = 1
    self._tail = 0
end

function QueueImpl.toArray(self: any): {any}
    local res = {}
    for i = self._head, self._tail do
        table.insert(res, self._items[i])
    end
    return res
end

-- ============================================================================
-- Stack (LIFO)
-- ============================================================================
export type Stack<T> = {
    push: (self: Stack<T>, item: T) -> (),
    pop: (self: Stack<T>) -> T?,
    peek: (self: Stack<T>) -> T?,
    size: (self: Stack<T>) -> number,
    isEmpty: (self: Stack<T>) -> boolean,
    clear: (self: Stack<T>) -> (),
}

local StackImpl = {}
StackImpl.__index = StackImpl

function StackImpl.new<T>(): Stack<T>
    local self = setmetatable({
        _items = {} :: {T},
    }, StackImpl)
    return (self :: any) :: Stack<T>
end

function StackImpl.push(self: any, item: any)
    table.insert(self._items, item)
end

function StackImpl.pop(self: any): any?
    return table.remove(self._items)
end

function StackImpl.peek(self: any): any?
    local items = self._items :: {any}
    return items[#items]
end

function StackImpl.size(self: any): number
    local items = self._items :: {any}
    return #items
end

function StackImpl.isEmpty(self: any): boolean
    return (self :: any):size() == 0
end

function StackImpl.clear(self: any)
    self._items = {}
end

-- ============================================================================
-- Set (Unique Values)
-- ============================================================================
export type Set<T> = {
    add: (self: Set<T>, item: T) -> boolean,
    has: (self: Set<T>, item: T) -> boolean,
    delete: (self: Set<T>, item: T) -> boolean,
    size: (self: Set<T>) -> number,
    clear: (self: Set<T>) -> (),
    values: (self: Set<T>) -> {T},
}

local SetImpl = {}
SetImpl.__index = SetImpl

function SetImpl.new<T>(initial: {T}?): Set<T>
    local self = setmetatable({
        _map = {} :: {[any]: boolean},
        _count = 0,
    }, SetImpl)
    if initial then
        for _, v in ipairs(initial) do
            (self :: any):add(v)
        end
    end
    return (self :: any) :: Set<T>
end

function SetImpl.add(self: any, item: any): boolean
    if not self._map[item] then
        self._map[item] = true
        self._count = (self._count :: number) + 1
        return true
    end
    return false
end

function SetImpl.has(self: any, item: any): boolean
    return self._map[item] == true
end

function SetImpl.delete(self: any, item: any): boolean
    if self._map[item] then
        self._map[item] = nil
        self._count = (self._count :: number) - 1
        return true
    end
    return false
end

function SetImpl.size(self: any): number
    return self._count :: number
end

function SetImpl.clear(self: any)
    self._map = {}
    self._count = 0
end

function SetImpl.values(self: any): {any}
    local res = {}
    for k in pairs(self._map) do
        table.insert(res, k)
    end
    return res
end

-- ============================================================================
-- LRU Cache
-- ============================================================================
export type LRUCache<K, V> = {
    get: (self: LRUCache<K, V>, key: K) -> V?,
    set: (self: LRUCache<K, V>, key: K, value: V) -> (),
    has: (self: LRUCache<K, V>, key: K) -> boolean,
    delete: (self: LRUCache<K, V>, key: K) -> boolean,
    size: (self: LRUCache<K, V>) -> number,
    clear: (self: LRUCache<K, V>) -> (),
}

type LRUNode = {
    key: any,
    val: any,
    prev: any?,
    next: any?,
}

local LRUImpl = {}
LRUImpl.__index = LRUImpl

function LRUImpl.new<K, V>(capacity: number): LRUCache<K, V>
    local self = setmetatable({
        _capacity = capacity,
        _size = 0,
        _head = nil :: any?,
        _tail = nil :: any?,
        _lookup = {} :: {[any]: any},
    }, LRUImpl)
    return (self :: any) :: LRUCache<K, V>
end

function LRUImpl._moveToHead(self: any, node: any)
    if self._head == node then return end

    -- Detach node
    if node.prev then node.prev.next = node.next end
    if node.next then node.next.prev = node.prev end
    if self._tail == node then self._tail = node.prev end

    -- Attach to head
    node.prev = nil
    node.next = self._head
    if self._head then self._head.prev = node end
    self._head = node
    if not self._tail then self._tail = node end
end

function LRUImpl.get(self: any, key: any): any?
    local node = self._lookup[key]
    if not node then return nil end
    LRUImpl._moveToHead(self, node)
    return node.val
end

function LRUImpl.set(self: any, key: any, value: any)
    local existing = self._lookup[key]
    if existing then
        existing.val = value
        LRUImpl._moveToHead(self, existing)
        return
    end

    local node: LRUNode = {
        key = key,
        val = value,
        prev = nil,
        next = self._head,
    }

    if self._head then self._head.prev = node end
    self._head = node
    if not self._tail then self._tail = node end

    self._lookup[key] = node
    self._size = (self._size :: number) + 1

    if (self._size :: number) > (self._capacity :: number) then
        -- Evict tail
        local tail = self._tail
        if tail then
            self._lookup[tail.key] = nil
            self._tail = tail.prev
            if self._tail then self._tail.next = nil else self._head = nil end
            self._size = (self._size :: number) - 1
        end
    end
end

function LRUImpl.has(self: any, key: any): boolean
    return self._lookup[key] ~= nil
end

function LRUImpl.delete(self: any, key: any): boolean
    local node = self._lookup[key]
    if not node then return false end

    if node.prev then node.prev.next = node.next end
    if node.next then node.next.prev = node.prev end
    if self._head == node then self._head = node.next end
    if self._tail == node then self._tail = node.prev end

    self._lookup[key] = nil
    self._size = (self._size :: number) - 1
    return true
end

function LRUImpl.size(self: any): number
    return self._size :: number
end

function LRUImpl.clear(self: any)
    self._lookup = {}
    self._head = nil
    self._tail = nil
    self._size = 0
end

local Collections = {
    Queue = QueueImpl,
    Stack = StackImpl,
    Set = SetImpl,
    LRUCache = LRUImpl,
}

return Collections
