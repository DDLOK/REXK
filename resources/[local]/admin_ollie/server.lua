-- =========================================================
-- admin_ollie - chat-command admin tools (ace-gated)
-- =========================================================

local function isAdmin(src)
    if src == 0 then return true end
    return IsPlayerAceAllowed(src, 'command')
        or IsPlayerAceAllowed(src, 'command.ac')
end

local function reply(src, color, author, msg)
    TriggerClientEvent('chat:addMessage', src, { color = color, args = { author, msg } })
end

RegisterCommand('ac', function(src, args)
    if not isAdmin(src) then reply(src, {255,60,60}, 'SERVER', 'no perms') return end
    if #args == 0 then return end
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 100, 100},
        args = { '📢 ANNOUNCE', table.concat(args, ' ') }
    })
end, false)

RegisterCommand('kick', function(src, args)
    if not isAdmin(src) then reply(src, {255,60,60}, 'SERVER', 'no perms') return end
    local target = tonumber(args[1])
    if not target then reply(src, {255,60,60}, 'SERVER', 'usage: /kick <id> [reason]') return end
    table.remove(args, 1)
    DropPlayer(target, 'kicked: ' .. (table.concat(args, ' ') or 'no reason'))
end, false)

local bansFile = 'bans.json'
local function loadBans()
    local raw = LoadResourceFile(GetCurrentResourceName(), bansFile)
    if not raw or raw == '' then return {} end
    local ok, data = pcall(json.decode, raw)
    return ok and data or {}
end
local function saveBans(t)
    SaveResourceFile(GetCurrentResourceName(), bansFile, json.encode(t), -1)
end

RegisterCommand('ban', function(src, args)
    if not isAdmin(src) then reply(src, {255,60,60}, 'SERVER', 'no perms') return end
    local target = tonumber(args[1])
    if not target then reply(src, {255,60,60}, 'SERVER', 'usage: /ban <id> [reason]') return end
    local ids = GetPlayerIdentifiers(target)
    if not ids or #ids == 0 then reply(src, {255,60,60}, 'SERVER', 'player not found') return end
    table.remove(args, 1)
    local reason = table.concat(args, ' ')
    if reason == '' then reason = 'no reason' end
    local bans = loadBans()
    for _, id in ipairs(ids) do
        bans[id] = { reason = reason, when = os.time(), by = (src == 0 and 'CONSOLE' or GetPlayerName(src)) }
    end
    saveBans(bans)
    DropPlayer(target, 'banned: ' .. reason)
    reply(src, {100,255,100}, 'SERVER', 'banned ' .. target)
end, false)

RegisterCommand('unban', function(src, args)
    if not isAdmin(src) then reply(src, {255,60,60}, 'SERVER', 'no perms') return end
    local id = args[1]
    if not id then reply(src, {255,60,60}, 'SERVER', 'usage: /unban <identifier>') return end
    local bans = loadBans()
    bans[id] = nil
    saveBans(bans)
    reply(src, {100,255,100}, 'SERVER', 'unbanned ' .. id)
end, false)

AddEventHandler('playerConnecting', function(name, setKickReason, def)
    local src = source
    def.defer()
    Wait(100)
    def.update('checking bench records...')
    Wait(0)
    local done = false
    local ok, err = pcall(function()
        local ids = GetPlayerIdentifiers(src) or {}
        local bans = loadBans()
        for _, id in ipairs(ids) do
            if bans[id] then
                def.done('banned: ' .. (bans[id].reason or 'no reason'))
                done = true
                return
            end
        end
    end)
    if not ok then
        print('^1[admin_ollie]^7 connect check error: ' .. tostring(err))
    end
    if not done then def.done() end
end)

RegisterCommand('players', function(src)
    local n = #GetPlayers()
    reply(src, {120,200,255}, 'SERVER', ('%d online'):format(n))
    for _, pid in ipairs(GetPlayers()) do
        reply(src, {180,180,180}, '  ', ('[%s] %s'):format(pid, GetPlayerName(pid)))
    end
end, false)

RegisterCommand('whoami', function(src)
    if src == 0 then print('console'); return end
    reply(src, {120,200,255}, 'YOU', ('id=%d name=%s'):format(src, GetPlayerName(src)))
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        reply(src, {180,180,180}, '  ', id)
    end
end, false)

print('^2[admin_ollie]^7 loaded - /ac /kick /ban /unban /players /whoami')
