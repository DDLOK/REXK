-- =========================================================
-- admin_ollie - account-based admin + NUI panel actions
-- =========================================================

local function isAdmin(src)
    if src == 0 then return true end
    local ok, r = pcall(function() return exports.account_ollie:isAdmin(src) end)
    return ok and r == true
end

local function reply(src, color, author, msg)
    TriggerClientEvent('chat:addMessage', src, { color = color, args = { author, msg } })
end

-- ========== classic chat commands ==========
RegisterCommand('ac', function(src, args)
    if not isAdmin(src) then reply(src, {255,60,60}, 'SERVER', 'admins only') return end
    if #args == 0 then return end
    TriggerClientEvent('chat:addMessage', -1, { color = {255,100,100}, args = { 'ANNOUNCE', table.concat(args, ' ') } })
end, false)

RegisterCommand('kick', function(src, args)
    if not isAdmin(src) then reply(src, {255,60,60}, 'SERVER', 'admins only') return end
    local target = tonumber(args[1]); if not target then return end
    table.remove(args, 1)
    local reason = table.concat(args, ' ')
    if reason == '' then reason = 'no reason' end
    DropPlayer(target, 'kicked: ' .. reason)
end, false)

local bansFile = 'bans.json'
local function loadBans()
    local raw = LoadResourceFile(GetCurrentResourceName(), bansFile)
    if not raw or raw == '' then return {} end
    local ok, d = pcall(json.decode, raw); return (ok and d) or {}
end
local function saveBans(t) SaveResourceFile(GetCurrentResourceName(), bansFile, json.encode(t), -1) end

RegisterCommand('ban', function(src, args)
    if not isAdmin(src) then reply(src, {255,60,60}, 'SERVER', 'admins only') return end
    local target = tonumber(args[1]); if not target then return end
    local ids = GetPlayerIdentifiers(target) or {}
    if #ids == 0 then return end
    table.remove(args, 1)
    local reason = table.concat(args, ' ')
    if reason == '' then reason = 'no reason' end
    local bans = loadBans()
    for _, id in ipairs(ids) do
        bans[id] = { reason = reason, when = os.time(), by = (src == 0 and 'CONSOLE' or GetPlayerName(src)) }
    end
    saveBans(bans)
    DropPlayer(target, 'banned: ' .. reason)
end, false)

RegisterCommand('unban', function(src, args)
    if not isAdmin(src) then reply(src, {255,60,60}, 'SERVER', 'admins only') return end
    local id = args[1]; if not id then return end
    local bans = loadBans(); bans[id] = nil; saveBans(bans)
end, false)

AddEventHandler('playerConnecting', function(name, _, def)
    local src = source
    def.defer(); Wait(100); def.update('checking bench records...'); Wait(0)
    local done = false
    pcall(function()
        local ids = GetPlayerIdentifiers(src) or {}
        local bans = loadBans()
        for _, id in ipairs(ids) do
            if bans[id] then def.done('banned: ' .. (bans[id].reason or 'no reason')); done = true; return end
        end
    end)
    if not done then def.done() end
end)

RegisterCommand('players', function(src)
    reply(src, {120,200,255}, 'SERVER', (#GetPlayers()) .. ' online')
    for _, pid in ipairs(GetPlayers()) do
        reply(src, {180,180,180}, '  ', ('[%s] %s'):format(pid, GetPlayerName(pid)))
    end
end, false)

RegisterCommand('whoami', function(src)
    if src == 0 then print('console'); return end
    reply(src, {120,200,255}, 'YOU', ('id=%d name=%s'):format(src, GetPlayerName(src)))
    for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do reply(src, {180,180,180}, '  ', id) end
end, false)

-- ========== NUI panel ==========
RegisterNetEvent('admin_ollie:refresh')
AddEventHandler('admin_ollie:refresh', function()
    local src = source
    if not isAdmin(src) then return end
    local list = {}
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        local bal = 0
        pcall(function() bal = exports.cash_ollie:getCash(pid) end)
        local job = 'unemployed'
        pcall(function() job = exports.jobs_ollie:getJob(pid) end)
        local user = nil
        pcall(function() user = exports.account_ollie:getUsername(pid) end)
        table.insert(list, { id = pid, name = GetPlayerName(pid), account = user, cash = bal, job = job })
    end
    TriggerClientEvent('admin_ollie:players', src, list)
end)

RegisterNetEvent('admin_ollie:action')
AddEventHandler('admin_ollie:action', function(action, target, value)
    local src = source
    if not isAdmin(src) then return end
    target = tonumber(target)
    if not target or GetPlayerPed(target) == 0 then return end
    local tname = GetPlayerName(target)

    if action == 'kick' then
        DropPlayer(target, 'kicked by admin')
    elseif action == 'ban' then
        local ids = GetPlayerIdentifiers(target) or {}
        local bans = loadBans()
        for _, id in ipairs(ids) do bans[id] = { reason = 'admin ban', when = os.time(), by = GetPlayerName(src) } end
        saveBans(bans)
        DropPlayer(target, 'banned by admin')
    elseif action == 'givemoney' then
        local v = tonumber(value) or 0
        if v > 0 then exports.cash_ollie:addCash(target, v) end
        reply(src, {100,255,150}, 'ADMIN', ('gave $%d to %s'):format(v, tname))
    elseif action == 'takemoney' then
        local v = tonumber(value) or 0
        if v > 0 then exports.cash_ollie:removeCash(target, v) end
        reply(src, {100,255,150}, 'ADMIN', ('took $%d from %s'):format(v, tname))
    elseif action == 'tpto' then
        local c = GetEntityCoords(GetPlayerPed(target))
        TriggerClientEvent('admin_ollie:tpTo', src, { x = c.x, y = c.y, z = c.z })
    elseif action == 'bring' then
        local c = GetEntityCoords(GetPlayerPed(src))
        TriggerClientEvent('admin_ollie:tpTo', target, { x = c.x, y = c.y, z = c.z })
    elseif action == 'heal' then
        local p = GetPlayerPed(target)
        SetEntityHealth(p, GetEntityMaxHealth(p))
    elseif action == 'armor' then
        TriggerClientEvent('admin_ollie:armor', target)
    elseif action == 'revive' then
        TriggerClientEvent('admin_ollie:revive', target)
    elseif action == 'setjob' then
        pcall(function() exports.jobs_ollie:setJob(target, tostring(value)) end)
    elseif action == 'giveweap' then
        TriggerClientEvent('admin_ollie:giveWeapon', target, tostring(value or 'WEAPON_PISTOL'):upper())
    elseif action == 'givecar' then
        TriggerClientEvent('admin_ollie:giveVehicle', target, tostring(value or 'adder'):lower())
    elseif action == 'freeze' then
        TriggerClientEvent('admin_ollie:freeze', target, true)
    elseif action == 'unfreeze' then
        TriggerClientEvent('admin_ollie:freeze', target, false)
    elseif action == 'spectate' then
        TriggerClientEvent('admin_ollie:spectate', src, target)
    elseif action == 'makeadmin' then
        local raw = LoadResourceFile('account_ollie', 'accounts.json')
        local ok, acc = pcall(json.decode, raw or '{}')
        if ok and acc then
            local user
            pcall(function() user = exports.account_ollie:getUsername(target) end)
            if user and acc[user] then
                acc[user].admin = true
                SaveResourceFile('account_ollie', 'accounts.json', json.encode(acc), -1)
                reply(src, {100,255,150}, 'ADMIN', 'promoted ' .. user .. ' - they relog to apply')
                TriggerClientEvent('chat:addMessage', target, { color = {100,255,150}, args = { 'ADMIN', 'you have been promoted - relog to see F6' } })
            end
        end
    end
end)

print('^2[admin_ollie]^7 v2 loaded - NUI panel (F6) + classic commands')
