-- =========================================================
-- house_ollie / server.lua
-- each account gets 1 of N preset houses, persistent
-- =========================================================

local HOUSES = {
    { name = "Michael's House",     x = -852.4,  y = 160.0,   z = 65.5,   h = 112.0 },
    { name = "Franklin's House",    x = 7.9,     y = 548.0,   z = 175.4,  h = 178.0 },
    { name = "Trevor's Trailer",    x = 1972.0,  y = 3817.0,  z = 33.4,   h = 302.0 },
    { name = "Vespucci Beach Apt",  x = -1282.0, y = -1117.0, z = 6.6,    h = 118.0 },
    { name = "Rockford Hills Villa",x = -1167.0, y = -445.0,  z = 37.0,   h = 126.0 },
    { name = "Vinewood Loft",       x = 294.0,   y = 174.0,   z = 104.3,  h = 158.0 },
    { name = "Chumash Beach House", x = -3167.0, y = 1083.0,  z = 20.8,   h = 240.0 },
    { name = "Sandy Shores Shack",  x = 1395.0,  y = 3604.0,  z = 34.9,   h = 196.0 },
    { name = "Grove Street House",  x = 83.0,    y = -1948.0, z = 20.8,   h = 47.0 },
    { name = "Paleto Cabin",        x = -170.0,  y = 6424.0,  z = 31.5,   h = 46.0 },
}

local FILE = 'assignments.json'
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

local function assignHouse(username)
    local t = load()
    if t[username] then return t[username] end
    -- pick the lowest unused index; wrap if everyone has one
    local used = {}
    for _, i in pairs(t) do used[i] = true end
    local pick
    for i = 1, #HOUSES do if not used[i] then pick = i break end end
    if not pick then pick = ((#t) % #HOUSES) + 1 end
    t[username] = pick
    save(t)
    return pick
end

local function sendHome(src)
    local user = exports.account_ollie:getUsername(src)
    if not user then reply(src, {255,80,80}, 'HOUSE', 'login first via the EZK form') return end
    local idx = assignHouse(user)
    local h = HOUSES[idx]
    TriggerClientEvent('house_ollie:teleport', src, { x = h.x, y = h.y, z = h.z, h = h.h, name = h.name })
end

RegisterCommand('home', sendHome, false)

RegisterNetEvent('house_ollie:goHome')
AddEventHandler('house_ollie:goHome', function()
    sendHome(source)
end)

RegisterCommand('myhouse', function(src)
    local user = exports.account_ollie:getUsername(src)
    if not user then reply(src, {255,80,80}, 'HOUSE', 'login first') return end
    local idx = assignHouse(user)
    reply(src, {180,220,255}, 'HOUSE', ('your house: %s (#%d)'):format(HOUSES[idx].name, idx))
end, false)

RegisterCommand('rehouse', function(src)
    local user = exports.account_ollie:getUsername(src)
    if not user then reply(src, {255,80,80}, 'HOUSE', 'login first') return end
    local t = load()
    t[user] = nil
    save(t)
    local idx = assignHouse(user)
    reply(src, {180,220,255}, 'HOUSE', ('new house: %s'):format(HOUSES[idx].name))
end, false)

-- /buyhouse <index> - pay to swap your assigned house to a specific one
local HOUSE_PRICE = 15000
RegisterCommand('buyhouse', function(src, args)
    local user = exports.account_ollie:getUsername(src)
    if not user then reply(src, {255,80,80}, 'HOUSE', 'login first') return end
    local idx = tonumber(args[1])
    if not idx then
        reply(src, {120,200,255}, 'HOUSE', 'usage: /buyhouse <1-' .. #HOUSES .. '>')
        for i, h in ipairs(HOUSES) do
            reply(src, {180,180,180}, '  ' .. i, h.name .. ' - $' .. HOUSE_PRICE)
        end
        return
    end
    if not HOUSES[idx] then reply(src, {255,80,80}, 'HOUSE', 'invalid') return end
    local ok = exports.cash_ollie:removeCash(src, HOUSE_PRICE)
    if not ok then reply(src, {255,80,80}, 'HOUSE', 'need $' .. HOUSE_PRICE) return end
    local t = load(); t[user] = idx; save(t)
    reply(src, {100,255,150}, 'HOUSE', 'bought ' .. HOUSES[idx].name)
    sendHome(src)
end, false)

print('^2[house_ollie]^7 loaded - ' .. #HOUSES .. ' house slots')
