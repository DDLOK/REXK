local cuffed = false

local function nearestPlayer()
    local p = PlayerPedId()
    local me = GetEntityCoords(p)
    local best, bestDist = nil, 5.0
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= p and ped ~= 0 then
            local d = #(GetEntityCoords(ped) - me)
            if d < bestDist then best = pid; bestDist = d end
        end
    end
    if best then return GetPlayerServerId(best) end
    return nil
end

RegisterCommand('cuff', function()
    local id = nearestPlayer()
    if not id then
        SetNotificationTextEntry('STRING'); AddTextComponentString('~r~no one in range')
        DrawNotification(false, true); return
    end
    TriggerServerEvent('police_ollie:cuff', id)
end, false)

RegisterCommand('uncuff', function()
    local id = nearestPlayer()
    if not id then return end
    TriggerServerEvent('police_ollie:uncuff', id)
end, false)

RegisterNetEvent('police_ollie:applyCuff')
AddEventHandler('police_ollie:applyCuff', function(on)
    local p = PlayerPedId()
    cuffed = on
    if on then
        RequestAnimDict('mp_arresting')
        local t = GetGameTimer()
        while not HasAnimDictLoaded('mp_arresting') do Wait(0); if GetGameTimer() - t > 2000 then break end end
        TaskPlayAnim(p, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
        SetEnableHandcuffs(p, true)
        DisablePlayerFiring(PlayerId(), true)
        SetPedPathCanUseLadders(p, false)
    else
        ClearPedTasks(p)
        SetEnableHandcuffs(p, false)
    end
end)

CreateThread(function()
    while true do
        Wait(cuffed and 10 or 1000)
        if cuffed then
            DisableControlAction(0, 24, true)  -- attack
            DisableControlAction(0, 25, true)  -- aim
            DisableControlAction(0, 47, true)  -- weapon
            DisableControlAction(0, 58, true)  -- weapon
            DisableControlAction(0, 140, true) -- melee
            DisableControlAction(0, 263, true) -- melee heavy
        end
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/cuff',   'cuff nearest player (police on duty)', {})
    TriggerEvent('chat:addSuggestion', '/uncuff', 'uncuff nearest player (police on duty)', {})
end)
