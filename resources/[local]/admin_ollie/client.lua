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

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/admin', 'open the admin panel (F6)', {})
end)
