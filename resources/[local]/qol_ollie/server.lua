local FILE = 'starterpack_claimed.json'
local function load()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
    if not raw or raw == '' then return {} end
    local ok, d = pcall(json.decode, raw); return (ok and d) or {}
end
local function save(t) SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(t), -1) end

local function reply(src, color, author, msg)
    TriggerClientEvent('chat:addMessage', src, { color = color, args = { author, msg } })
end

RegisterCommand('starterpack', function(src)
    local user = exports.account_ollie:getUsername(src)
    if not user then reply(src, {255,80,80}, 'STARTER', 'login first') return end
    local claimed = load()
    if claimed[user] then reply(src, {255,80,80}, 'STARTER', 'already claimed') return end
    claimed[user] = os.time(); save(claimed)
    exports.cash_ollie:addCash(src, 2500)
    TriggerClientEvent('qol_ollie:starterpack', src)
    reply(src, {100,255,150}, 'STARTER', 'enjoy +$2500 + weapons + fresh outfit')
end, false)
