local FILE = 'wallets.json'
local START = 500
local cache = {} -- [src] = balance, synced from file on login

local function load()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
    if not raw or raw == '' then return {} end
    local ok, d = pcall(json.decode, raw)
    return (ok and d) or {}
end
local function save(t) SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(t), -1) end

local function reply(src, color, author, msg)
    TriggerClientEvent('chat:addMessage', src, { color = color, args = { author, msg } })
end

local function userOf(src)
    local ok, u = pcall(function() return exports.account_ollie:getUsername(src) end)
    return ok and u or nil
end

local function get(src)
    local u = userOf(src); if not u then return 0 end
    if cache[src] then return cache[src] end
    local t = load()
    if t[u] == nil then t[u] = START; save(t) end
    cache[src] = t[u]
    return cache[src]
end

local function set(src, v)
    local u = userOf(src); if not u then return end
    cache[src] = math.max(0, math.floor(v))
    local t = load(); t[u] = cache[src]; save(t)
    TriggerClientEvent('cash_ollie:sync', src, cache[src])
end

local function add(src, v) set(src, get(src) + v) end
local function sub(src, v)
    if get(src) < v then return false end
    set(src, get(src) - v); return true
end

exports('getCash', get)
exports('addCash', add)
exports('removeCash', sub)
exports('setCash', set)

RegisterNetEvent('cash_ollie:request')
AddEventHandler('cash_ollie:request', function() TriggerClientEvent('cash_ollie:sync', source, get(source)) end)

RegisterCommand('balance', function(src)
    reply(src, {100,255,150}, 'BANK', ('$%d'):format(get(src)))
end, false)

RegisterCommand('pay', function(src, args)
    local target = tonumber(args[1])
    local amount = tonumber(args[2])
    if not target or not amount or amount <= 0 then
        reply(src, {255,80,80}, 'BANK', 'usage: /pay <id> <amount>')
        return
    end
    if target == src then reply(src, {255,80,80}, 'BANK', 'nice try') return end
    if GetPlayerPed(target) == 0 then reply(src, {255,80,80}, 'BANK', 'player not online') return end
    if not sub(src, amount) then reply(src, {255,80,80}, 'BANK', 'insufficient funds') return end
    add(target, amount)
    reply(src,    {100,255,150}, 'BANK', ('sent $%d to %s'):format(amount, GetPlayerName(target)))
    reply(target, {100,255,150}, 'BANK', ('received $%d from %s'):format(amount, GetPlayerName(src)))
end, false)

RegisterCommand('givemoney', function(src, args)
    local isAdmin = src == 0 or pcall(function() return exports.account_ollie:isAdmin(src) end)
    if src ~= 0 and not exports.account_ollie:isAdmin(src) then
        reply(src, {255,80,80}, 'BANK', 'admins only'); return
    end
    local target = tonumber(args[1])
    local amount = tonumber(args[2])
    if not target or not amount then reply(src, {255,80,80}, 'BANK', 'usage: /givemoney <id> <amount>') return end
    add(target, amount)
    reply(src, {100,255,150}, 'BANK', ('gave $%d to %s'):format(amount, GetPlayerName(target)))
end, false)

AddEventHandler('playerDropped', function()
    cache[source] = nil
end)

print('^2[cash_ollie]^7 loaded - wallet, /balance /pay')
