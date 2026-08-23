--!strict
-- Cryptography and Hashing Utilities for KLUR

local Crypto = {}

local SHA256_K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}

local function ror(x: number, n: number): number
    return bit32.bor(bit32.rshift(x, n), bit32.lshift(x, 32 - n))
end

function Crypto.sha256(msg: string): string
    -- SHA-256 in pure Luau
    local h0, h1, h2, h3 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
    local h4, h5, h6, h7 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

    local bytes = {}
    for i = 1, #msg do
        table.insert(bytes, string.byte(msg, i))
    end

    local origBitLen = #bytes * 8
    table.insert(bytes, 0x80)

    while (#bytes % 64) ~= 56 do
        table.insert(bytes, 0x00)
    end

    for i = 7, 0, -1 do
        table.insert(bytes, bit32.band(bit32.rshift(origBitLen, i * 8), 0xff))
    end

    local w = {}
    for chunk = 0, (#bytes / 64) - 1 do
        local offset = chunk * 64
        for i = 0, 15 do
            local idx = offset + i * 4
            w[i] = bit32.bor(
                bit32.lshift(bytes[idx + 1], 24),
                bit32.lshift(bytes[idx + 2], 16),
                bit32.lshift(bytes[idx + 3], 8),
                bytes[idx + 4]
            )
        end

        for i = 16, 63 do
            local s0 = bit32.bxor(ror(w[i - 15], 7), ror(w[i - 15], 18), bit32.rshift(w[i - 15], 3))
            local s1 = bit32.bxor(ror(w[i - 2], 17), ror(w[i - 2], 19), bit32.rshift(w[i - 2], 10))
            w[i] = bit32.band(w[i - 16] + s0 + w[i - 7] + s1, 0xffffffff)
        end

        local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7

        for i = 0, 63 do
            local S1 = bit32.bxor(ror(e, 6), ror(e, 11), ror(e, 25))
            local ch = bit32.bxor(bit32.band(e, f), bit32.band(bit32.bnot(e), g))
            local temp1 = bit32.band(h + S1 + ch + SHA256_K[i + 1] + w[i], 0xffffffff)
            local S0 = bit32.bxor(ror(a, 2), ror(a, 13), ror(a, 22))
            local maj = bit32.bxor(bit32.band(a, b), bit32.band(a, c), bit32.band(b, c))
            local temp2 = bit32.band(S0 + maj, 0xffffffff)

            h = g
            g = f
            f = e
            e = bit32.band(d + temp1, 0xffffffff)
            d = c
            c = b
            b = a
            a = bit32.band(temp1 + temp2, 0xffffffff)
        end

        h0 = bit32.band(h0 + a, 0xffffffff)
        h1 = bit32.band(h1 + b, 0xffffffff)
        h2 = bit32.band(h2 + c, 0xffffffff)
        h3 = bit32.band(h3 + d, 0xffffffff)
        h4 = bit32.band(h4 + e, 0xffffffff)
        h5 = bit32.band(h5 + f, 0xffffffff)
        h6 = bit32.band(h6 + g, 0xffffffff)
        h7 = bit32.band(h7 + h, 0xffffffff)
    end

    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
end

local MD5_K = {
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
}

local MD5_S = {
    7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
    5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
    4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
    6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
}

local function rol(x: number, n: number): number
    return bit32.bor(bit32.lshift(x, n), bit32.rshift(x, 32 - n))
end

function Crypto.md5(msg: string): string
    local a0, b0, c0, d0 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476

    local bytes = {}
    for i = 1, #msg do
        table.insert(bytes, string.byte(msg, i))
    end

    local bitLen = #bytes * 8
    table.insert(bytes, 0x80)

    while (#bytes % 64) ~= 56 do
        table.insert(bytes, 0x00)
    end

    -- Little endian 64-bit length
    for i = 0, 7 do
        table.insert(bytes, bit32.band(bit32.rshift(bitLen, i * 8), 0xff))
    end

    for chunk = 0, (#bytes / 64) - 1 do
        local offset = chunk * 64
        local m = {}
        for i = 0, 15 do
            local idx = offset + i * 4
            m[i] = bit32.bor(
                bytes[idx + 1],
                bit32.lshift(bytes[idx + 2], 8),
                bit32.lshift(bytes[idx + 3], 16),
                bit32.lshift(bytes[idx + 4], 24)
            )
        end

        local a, b, c, d = a0, b0, c0, d0

        for i = 0, 63 do
            local f, g
            if i < 16 then
                f = bit32.bor(bit32.band(b, c), bit32.band(bit32.bnot(b), d))
                g = i
            elseif i < 32 then
                f = bit32.bor(bit32.band(d, b), bit32.band(bit32.bnot(d), c))
                g = (5 * i + 1) % 16
            elseif i < 48 then
                f = bit32.bxor(b, bit32.bxor(c, d))
                g = (3 * i + 5) % 16
            else
                f = bit32.bxor(c, bit32.bor(b, bit32.bnot(d)))
                g = (7 * i) % 16
            end

            local temp = bit32.band(a + f + MD5_K[i + 1] + m[g], 0xffffffff)
            local rotated = rol(temp, MD5_S[i + 1])
            local new_b = bit32.band(b + rotated, 0xffffffff)
            a = d
            d = c
            c = b
            b = new_b
        end

        a0 = bit32.band(a0 + a, 0xffffffff)
        b0 = bit32.band(b0 + b, 0xffffffff)
        c0 = bit32.band(c0 + c, 0xffffffff)
        d0 = bit32.band(d0 + d, 0xffffffff)
    end

    local function leHex(x: number): string
        local b1 = bit32.band(x, 0xff)
        local b2 = bit32.band(bit32.rshift(x, 8), 0xff)
        local b3 = bit32.band(bit32.rshift(x, 16), 0xff)
        local b4 = bit32.band(bit32.rshift(x, 24), 0xff)
        return string.format("%02x%02x%02x%02x", b1, b2, b3, b4)
    end

    return leHex(a0) .. leHex(b0) .. leHex(c0) .. leHex(d0)
end

function Crypto.uuid(): string
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return (string.gsub(template, "[xy]", function(c)
        local r = math.random(0, 15)
        local v = (c == "x") and r or (bit32.bor(bit32.band(r, 0x3), 0x8))
        return string.format("%x", v)
    end))
end

function Crypto.randomHex(length: number): string
    local res = {}
    for _ = 1, length do
        table.insert(res, string.format("%02x", math.random(0, 255)))
    end
    return table.concat(res)
end

function Crypto.timingSafeEqual(a: string, b: string): boolean
    if #a ~= #b then return false end
    local diff = 0
    for i = 1, #a do
        diff = bit32.bor(diff, bit32.bxor(string.byte(a, i), string.byte(b, i)))
    end
    return diff == 0
end

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function Crypto.base64Encode(data: string): string
    local bytes = {}
    for i = 1, #data do
        table.insert(bytes, string.byte(data, i))
    end

    local out = {}
    local len = #bytes
    local i = 1

    while i <= len do
        local b1 = bytes[i]
        local b2 = (i + 1 <= len) and bytes[i + 1] or nil
        local b3 = (i + 2 <= len) and bytes[i + 2] or nil

        local n = bit32.lshift(b1, 16)
        if b2 then n = bit32.bor(n, bit32.lshift(b2, 8)) end
        if b3 then n = bit32.bor(n, b3) end

        local c1 = bit32.band(bit32.rshift(n, 18), 0x3f) + 1
        local c2 = bit32.band(bit32.rshift(n, 12), 0x3f) + 1
        local c3 = b2 and (bit32.band(bit32.rshift(n, 6), 0x3f) + 1) or nil
        local c4 = b3 and (bit32.band(n, 0x3f) + 1) or nil

        table.insert(out, b64chars:sub(c1, c1))
        table.insert(out, b64chars:sub(c2, c2))
        table.insert(out, c3 and b64chars:sub(c3, c3) or "=")
        table.insert(out, c4 and b64chars:sub(c4, c4) or "=")

        i += 3
    end

    return table.concat(out)
end

function Crypto.base64Decode(data: string): string
    local clean = (data:gsub("[^A-Za-z0-9+/=]", ""))
    local out = {}
    local i = 1
    local len = #clean

    local map: {[string]: number} = {}
    for idx = 1, #b64chars do
        map[b64chars:sub(idx, idx)] = idx - 1
    end

    while i <= len do
        local ch1 = clean:sub(i, i)
        local ch2 = clean:sub(i + 1, i + 1)
        local ch3 = clean:sub(i + 2, i + 2)
        local ch4 = clean:sub(i + 3, i + 3)

        local v1 = map[ch1] or 0
        local v2 = map[ch2] or 0
        local v3 = (ch3 ~= "=") and (map[ch3] or 0) or nil
        local v4 = (ch4 ~= "=") and (map[ch4] or 0) or nil

        local n = bit32.bor(bit32.lshift(v1, 18), bit32.lshift(v2, 12))
        if v3 then n = bit32.bor(n, bit32.lshift(v3, 6)) end
        if v4 then n = bit32.bor(n, v4) end

        local b1 = bit32.band(bit32.rshift(n, 16), 0xff)
        table.insert(out, string.char(b1))

        if v3 then
            local b2 = bit32.band(bit32.rshift(n, 8), 0xff)
            table.insert(out, string.char(b2))
        end

        if v4 then
            local b3 = bit32.band(n, 0xff)
            table.insert(out, string.char(b3))
        end

        i += 4
    end

    return table.concat(out)
end

return Crypto
