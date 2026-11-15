-- =========================================================
-- server.lua - player list + teleport-to-player
-- =========================================================

RegisterNetEvent('menu_ollie:listPlayers')
AddEventHandler('menu_ollie:listPlayers', function()
    local src = source
    local list = {}
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        if pid ~= src then
            table.insert(list, { id = pid, name = GetPlayerName(pid) or ('player ' .. pid) })
        end
    end
    TriggerClientEvent('menu_ollie:playerList', src, list)
end)

RegisterNetEvent('menu_ollie:tpTo')
AddEventHandler('menu_ollie:tpTo', function(targetId)
    local src = source
    local target = GetPlayerPed(targetId)
    if target == 0 then return end
    local c = GetEntityCoords(target)
    TriggerClientEvent('menu_ollie:teleportTo', src, { x = c.x, y = c.y, z = c.z })
end)

RegisterNetEvent('menu_ollie:bring')
AddEventHandler('menu_ollie:bring', function(targetId)
    local src = source
    local srcPed = GetPlayerPed(src)
    if srcPed == 0 then return end
    local c = GetEntityCoords(srcPed)
    TriggerClientEvent('menu_ollie:teleportTo', targetId, { x = c.x, y = c.y, z = c.z })
end)

print('^2[menu_ollie]^7 loaded - F5 menu ready - made by EZK TEAM')
