--!strict
-- Lightweight HTTP Server and Router for KLUR

export type ServerRequest = {
    method: string,
    path: string,
    headers: {[string]: string},
    body: string,
    query: {[string]: string},
    params: {[string]: string},
    json: (self: ServerRequest) -> any,
}

export type ServerResponse = {
    status: (self: ServerResponse, code: number) -> ServerResponse,
    setHeader: (self: ServerResponse, key: string, value: string) -> ServerResponse,
    send: (self: ServerResponse, body: string) -> (),
    json: (self: ServerResponse, data: any) -> (),
    html: (self: ServerResponse, htmlContent: string) -> (),
}

export type Handler = (req: ServerRequest, res: ServerResponse) -> ()
export type Middleware = (req: ServerRequest, res: ServerResponse, next: () -> ()) -> ()

local Server = {}
Server.__index = Server

function Server.new()
    local self = setmetatable({
        _routes = {} :: {[string]: {[string]: Handler}},
        _middlewares = {} :: {Middleware},
    }, Server)
    return self
end

function Server:use(middleware: Middleware)
    table.insert(self._middlewares, middleware)
    return self
end

function Server:get(path: string, handler: Handler)
    self:_addRoute("GET", path, handler)
    return self
end

function Server:post(path: string, handler: Handler)
    self:_addRoute("POST", path, handler)
    return self
end

function Server:put(path: string, handler: Handler)
    self:_addRoute("PUT", path, handler)
    return self
end

function Server:delete(path: string, handler: Handler)
    self:_addRoute("DELETE", path, handler)
    return self
end

function Server:_addRoute(method: string, path: string, handler: Handler)
    if not self._routes[method] then
        self._routes[method] = {}
    end
    self._routes[method][path] = handler
end

function Server:listen(port: number, host: string?, callback: (() -> ())?)
    local bindHost = host or "127.0.0.1"
    if net and net.listen then
        net.listen(bindHost, port, function(rawReq: any)
            local req: ServerRequest = {
                method = rawReq.method or "GET",
                path = rawReq.path or "/",
                headers = rawReq.headers or {},
                body = rawReq.body or "",
                query = rawReq.query or {},
                params = {},
                json = function(self: ServerRequest): any
                    local _json = (_G :: any).json
                    if _json and _json.decode then
                        return _json.decode(self.body)
                    end
                    return nil
                end,
            }

            local resHeaders: {[string]: string} = {
                ["Server"] = "KLUR",
                ["Content-Type"] = "text/plain; charset=utf-8",
            }
            local statusCode = 200

            local res: ServerResponse = {
                status = function(self: ServerResponse, code: number)
                    statusCode = code
                    return self
                end,
                setHeader = function(self: ServerResponse, key: string, val: string)
                    resHeaders[key] = val
                    return self
                end,
                send = function(self: ServerResponse, bodyStr: string)
                    return {
                        status = statusCode,
                        headers = resHeaders,
                        body = bodyStr,
                    }
                end,
                json = function(self: ServerResponse, data: any)
                    resHeaders["Content-Type"] = "application/json"
                    local _json = (_G :: any).json
                    local body = (_json and _json.encode and _json.encode(data)) or "{}"
                    return {
                        status = statusCode,
                        headers = resHeaders,
                        body = body,
                    }
                end,
                html = function(self: ServerResponse, htmlStr: string)
                    resHeaders["Content-Type"] = "text/html; charset=utf-8"
                    return {
                        status = statusCode,
                        headers = resHeaders,
                        body = htmlStr,
                    }
                end,
            }

            local handler = self._routes[req.method] and self._routes[req.method][req.path]
            if handler then
                return handler(req, res)
            end

            return {
                status = 404,
                headers = resHeaders,
                body = "Not Found",
            }
        end)
    end
    if callback then
        callback()
    end
end

return Server
