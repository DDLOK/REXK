-- =========================================================
-- chat_ollie / server.lua
-- welcome lines, /me emote, /clear chat, join+leave broadcast
-- =========================================================

local function send(src, author, color, msg)
    TriggerClientEvent('chat:addMessage', src, {
        color = color,
        multiline = true,
        args = { author, msg }
    })
end

-- join welcome
AddEventHandler('playerJoining', function()
    local src  = source
    local name = GetPlayerName(src) or ('player ' .. src)
    send(-1, 'SERVER', {255, 100, 200}, ('^*%s ^rconnected'):format(name))
end)

-- leave notice
AddEventHandler('playerDropped', function(reason)
    local src  = source
    local name = GetPlayerName(src) or ('player ' .. src)
    send(-1, 'SERVER', {180, 180, 180}, ('%s left (%s)'):format(name, reason or '?'))
end)

-- first-spawn welcome (private to the joiner)
RegisterNetEvent('chat_ollie:welcome')
AddEventHandler('chat_ollie:welcome', function()
    local src = source
    send(src, 'EZK',   {255,  80, 200}, 'welcome to the bench - sign in with the form')
    send(src, 'EZK',   {255,  80, 200}, 'type /help for chat commands, F5 for the menu')
    send(src, 'EZK',   {120, 200, 255}, 'made by EZK TEAM - discord.gg/ojailbreaks')
end)

-- /me emote
RegisterCommand('me', function(src, args)
    if #args == 0 then return end
    local name = (src > 0 and GetPlayerName(src)) or 'console'
    local txt  = table.concat(args, ' ')
    send(-1, '* ' .. name, {200, 160, 255}, txt)
end, false)

-- /clear - wipe chat for everyone (admin only via ace)
RegisterCommand('clear', function(src, args)
    if src > 0 and not IsPlayerAceAllowed(src, 'command.clear') then
        send(src, 'SERVER', {255, 60, 60}, 'no perms, cheeks')
        return
    end
    TriggerClientEvent('chat:clear', -1)
end, false)

-- /help
RegisterCommand('help', function(src)
    send(src, 'HELP', {120, 255, 180}, '/me <action>   - emote')
    send(src, 'HELP', {120, 255, 180}, '/clear         - wipe chat (admin)')
    send(src, 'HELP', {120, 255, 180}, '/ooc <msg>     - out of character')
    send(src, 'HELP', {120, 255, 180}, '/pm <id> <msg> - private message')
end, false)

-- /ooc - global out of character
RegisterCommand('ooc', function(src, args)
    if #args == 0 then return end
    local name = (src > 0 and GetPlayerName(src)) or 'console'
    send(-1, '[OOC] ' .. name, {180, 220, 255}, table.concat(args, ' '))
end, false)

-- /pm <serverId> <msg>
RegisterCommand('pm', function(src, args)
    local target = tonumber(args[1])
    if not target or #args < 2 then
        send(src, 'SERVER', {255, 60, 60}, 'usage: /pm <id> <message>')
        return
    end
    table.remove(args, 1)
    local msg = table.concat(args, ' ')
    local from = (src > 0 and GetPlayerName(src)) or 'console'
    send(target, 'PM from ' .. from, {255, 200, 100}, msg)
    send(src,    'PM to '   .. (GetPlayerName(target) or target), {255, 200, 100}, msg)
end, false)

print('^2[chat_ollie]^7 loaded - made by EZK TEAM')
