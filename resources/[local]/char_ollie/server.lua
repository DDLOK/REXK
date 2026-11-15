local FILE = 'chars.json'
local function load()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
    if not raw or raw == '' then return {} end
    local ok, d = pcall(json.decode, raw); return (ok and d) or {}
end
local function save(t) SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(t), -1) end

local function userOf(src)
    local ok, u = pcall(function() return exports.account_ollie:getUsername(src) end)
    return ok and u or nil
end

RegisterNetEvent('char_ollie:request')
AddEventHandler('char_ollie:request', function()
    local src = source
    local user = userOf(src); if not user then return end
    local all = load()
    local userData = all[user] or { chars = {}, selected = nil }
    all[user] = userData; save(all)
    TriggerClientEvent('char_ollie:list', src, userData)
end)

RegisterNetEvent('char_ollie:saveChar')
AddEventHandler('char_ollie:saveChar', function(idx, char)
    local src = source
    local user = userOf(src); if not user then return end
    local all = load()
    all[user] = all[user] or { chars = {}, selected = nil }
    -- normalize, clamp
    if idx == nil or idx < 1 or idx > 4 then return end
    char.name = tostring(char.name or 'Unnamed'):sub(1, 32)
    all[user].chars[idx] = char
    all[user].selected = idx
    save(all)
    TriggerClientEvent('char_ollie:list', src, all[user])
    TriggerClientEvent('char_ollie:applied', src, char)
end)

RegisterNetEvent('char_ollie:selectChar')
AddEventHandler('char_ollie:selectChar', function(idx)
    local src = source
    local user = userOf(src); if not user then return end
    local all = load()
    if not all[user] or not all[user].chars[idx] then return end
    all[user].selected = idx
    save(all)
    TriggerClientEvent('char_ollie:applied', src, all[user].chars[idx])
end)

RegisterNetEvent('char_ollie:deleteChar')
AddEventHandler('char_ollie:deleteChar', function(idx)
    local src = source
    local user = userOf(src); if not user then return end
    local all = load()
    if not all[user] then return end
    all[user].chars[idx] = nil
    if all[user].selected == idx then all[user].selected = nil end
    save(all)
    TriggerClientEvent('char_ollie:list', src, all[user])
end)

print('^2[char_ollie]^7 loaded - saved skins')
