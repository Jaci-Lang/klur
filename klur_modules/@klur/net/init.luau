--!strict
-- Networking and HTTP suite for KLUR

local Client = require("@self/client")
local Server = require("@self/server")

local Net = {
    Client = Client,
    Server = Server,
    fetch = Client.fetch,
    get = Client.get,
    post = Client.post,
    put = Client.put,
    delete = Client.delete,
    request = Client.request,
}

return Net
