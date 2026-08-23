--!strict
-- High-level HTTP Client for KLUR

export type RequestOptions = {
    method: string?,
    headers: {[string]: string}?,
    body: (string | {[string]: any})?,
    query: {[string]: any}?,
    timeout: number?,
}

export type Response = {
    status: number,
    statusText: string,
    ok: boolean,
    headers: {[string]: string},
    body: string,
    json: (self: Response) -> any,
    text: (self: Response) -> string,
}

local Client = {}

local function buildQueryString(query: {[string]: any}): string
    local parts = {}
    for k, v in pairs(query) do
        local encKey = tostring(k)
        local encVal = tostring(v)
        if net and net.urlEncode then
            encKey = net.urlEncode(encKey)
            encVal = net.urlEncode(encVal)
        end
        table.insert(parts, encKey .. "=" .. encVal)
    end
    return table.concat(parts, "&")
end

function Client.request(url: string, opts: RequestOptions?): Response
    local method = (opts and opts.method) or "GET"
    local headers = (opts and opts.headers) or {}
    local finalUrl = url

    if opts and opts.query then
        local qs = buildQueryString(opts.query)
        if qs ~= "" then
            finalUrl = finalUrl .. (finalUrl:find("%?") and "&" or "?") .. qs
        end
    end

    local _json = (_G :: any).json
    local _net = (_G :: any).net

    local bodyStr: string? = nil
    if opts and opts.body then
        if type(opts.body) == "table" then
            headers["Content-Type"] = headers["Content-Type"] or "application/json"
            if _json and _json.encode then
                bodyStr = _json.encode(opts.body)
            end
        else
            bodyStr = tostring(opts.body)
        end
    end

    local rawRes: any = nil
    if _net and _net.request then
        rawRes = _net.request({
            url = finalUrl,
            method = method,
            headers = headers,
            body = bodyStr,
        })
    elseif _net and _net.get and (method == "GET" or method == "get") then
        rawRes = _net.get(finalUrl, headers)
    else
        error("Network HTTP request not supported on this platform")
    end

    local status = (rawRes and (rawRes.status or rawRes.statusCode)) or 200
    local rawHeaders = (rawRes and (rawRes.headers or {})) or {}
    local rawBody = (rawRes and (rawRes.body or "")) or ""

    local response: Response = {
        status = status,
        statusText = status >= 200 and status < 300 and "OK" or "Error",
        ok = status >= 200 and status < 300,
        headers = rawHeaders,
        body = rawBody,
        text = function(self: Response): string
            return self.body
        end,
        json = function(self: Response): any
            if _json and _json.decode then
                return _json.decode(self.body)
            end
            error("JSON decode not available")
        end,
    }

    return response
end

function Client.get(url: string, opts: RequestOptions?): Response
    local o = opts or {}
    o.method = "GET"
    return Client.request(url, o)
end

function Client.post(url: string, body: (string | {[string]: any})?, opts: RequestOptions?): Response
    local o = opts or {}
    o.method = "POST"
    o.body = body
    return Client.request(url, o)
end

function Client.put(url: string, body: (string | {[string]: any})?, opts: RequestOptions?): Response
    local o = opts or {}
    o.method = "PUT"
    o.body = body
    return Client.request(url, o)
end

function Client.delete(url: string, opts: RequestOptions?): Response
    local o = opts or {}
    o.method = "DELETE"
    return Client.request(url, o)
end

function Client.fetch(url: string, opts: RequestOptions?): Response
    return Client.request(url, opts)
end

return Client
