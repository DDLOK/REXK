local open = false

local function openPanel()
    if open then return end
    open = true
    TriggerServerEvent('admin_ollie:refresh')
    SendNUIMessage({ action = 'open' })
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
end

local function closePanel()
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('admin', function()
    local ok = false
    pcall(function() ok = exports.account_ollie:isAdmin() end)
    if not ok then
        SetNotificationTextEntry('STRING'); AddTextComponentString('~r~admins only')
        DrawNotification(false, true); return
    end
    openPanel()
end, false)
RegisterKeyMapping('admin', 'Admin Panel', 'keyboard', 'F6')

RegisterNUICallback('close', function(_, cb) closePanel(); cb({}) end)

RegisterNUICallback('action', function(d, cb)
    TriggerServerEvent('admin_ollie:action', d.action, d.target, d.value)
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('admin_ollie:refresh')
    cb({ ok = true })
end)

RegisterNetEvent('admin_ollie:players')
AddEventHandler('admin_ollie:players', function(list)
    SendNUIMessage({ action = 'players', list = list })
end)

RegisterNetEvent('admin_ollie:tpTo')
AddEventHandler('admin_ollie:tpTo', function(coords)
    local p = PlayerPedId()
    DoScreenFadeOut(300); Wait(320)
    SetEntityCoords(p, coords.x, coords.y, coords.z, false, false, false, true)
    Wait(200); DoScreenFadeIn(300)
end)

RegisterNetEvent('admin_ollie:armor')
AddEventHandler('admin_ollie:armor', function() SetPedArmour(PlayerPedId(), 100) end)

RegisterNetEvent('admin_ollie:revive')
AddEventHandler('admin_ollie:revive', function()
    local p = PlayerPedId()
    NetworkResurrectLocalPlayer(GetEntityCoords(p), GetEntityHeading(p), true, false)
    SetPlayerInvincible(PlayerId(), false); ClearPedBloodDamage(p)
    SetEntityHealth(p, GetEntityMaxHealth(p))
end)

RegisterNetEvent('admin_ollie:freeze')
AddEventHandler('admin_ollie:freeze', function(on)
    FreezeEntityPosition(PlayerPedId(), on)
end)

RegisterNetEvent('admin_ollie:giveWeapon')
AddEventHandler('admin_ollie:giveWeapon', function(w)
    GiveWeaponToPed(PlayerPedId(), joaat(w), 500, false, true)
end)

RegisterNetEvent('admin_ollie:giveVehicle')
AddEventHandler('admin_ollie:giveVehicle', function(model)
    local m = joaat(model)
    if not IsModelInCdimage(m) then return end
    RequestModel(m)
    local t = GetGameTimer()
    while not HasModelLoaded(m) do Wait(0); if GetGameTimer() - t > 3000 then return end end
    local p = PlayerPedId()
    local c = GetEntityCoords(p)
    local v = CreateVehicle(m, c.x, c.y, c.z, GetEntityHeading(p), true, false)
    SetPedIntoVehicle(p, v, -1)
    SetModelAsNoLongerNeeded(m)
end)

RegisterNetEvent('admin_ollie:spectate')
AddEventHandler('admin_ollie:spectate', function(targetSrvId)
    local target = GetPlayerFromServerId(targetSrvId)
    if target == -1 then return end
    local tp = GetPlayerPed(target)
    NetworkSetInSpectatorMode(true, tp)
    SetNotificationTextEntry('STRING'); AddTextComponentString('~g~spectating - /unspec to return')
    DrawNotification(false, true)
end)

RegisterCommand('unspec', function()
    NetworkSetInSpectatorMode(false, 0)
    SetNotificationTextEntry('STRING'); AddTextComponentString('~g~returned')
    DrawNotification(false, true)
end, false)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/admin', 'open the admin panel (F6)', {})
end)
