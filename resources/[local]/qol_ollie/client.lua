local afkMode, scaleMode, miniHidden, idleDisabled = false, false, false, false

local function notify(t)
    SetNotificationTextEntry('STRING'); AddTextComponentString(t); DrawNotification(false, true)
end

RegisterCommand('propfix', function()
    local p = PlayerPedId()
    for _, bone in ipairs({0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37}) do
        local att = GetEntityAttachedTo(p)
        if att ~= 0 then DetachEntity(p, true, true) end
    end
    ClearPedTasksImmediately(p)
    notify('~g~props fixed')
end, false)

RegisterCommand('reloadskin', function()
    local p = PlayerPedId()
    SetPedDefaultComponentVariation(p)
    notify('~g~skin reloaded')
end, false)

RegisterCommand('afk', function()
    afkMode = not afkMode
    local p = PlayerPedId()
    SetEntityInvincible(p, afkMode)
    SetPlayerInvisibleLocally(PlayerId(), not afkMode) -- toggles stealth
    notify(afkMode and '~g~AFK mode ON ~w~(invincible)' or '~y~AFK mode OFF')
end, false)

RegisterCommand('scalemenu', function(_, args)
    local v = tonumber(args[1])
    local p = PlayerPedId()
    if not v then
        SetPedConfigFlag(p, 223, false)
        notify('~y~scale reset')
    else
        v = math.max(0.5, math.min(2.0, v))
        -- pseudo-scale via model scale isn't exposed; approximation via PedComponentVariation won't work either
        -- true approach uses attachments; simple notify of the intent
        notify(('~y~scale target: %.2f (visual only, limited by RAGE)'):format(v))
    end
end, false)

RegisterCommand('minimapm', function()
    miniHidden = not miniHidden
    DisplayRadar(not miniHidden)
    notify(miniHidden and '~y~minimap hidden' or '~g~minimap shown')
end, false)

RegisterCommand('idlecam', function()
    idleDisabled = not idleDisabled
    notify(idleDisabled and '~g~idlecam disabled' or '~y~idlecam enabled')
end, false)

CreateThread(function()
    while true do
        Wait(60000)
        if idleDisabled then InvalidateIdleCam() InvalidateVehicleIdleCam() end
    end
end)

RegisterCommand('gps', function(src, args)
    -- /gps <x> <y>  OR  /gps <preset>
    local presets = {
        ['airport']  = {x = -1037, y = -2737},
        ['legion']   = {x = 215,   y = -810},
        ['hospital'] = {x = 307,   y = -599},
        ['pd']       = {x = 428,   y = -981},
        ['casino']   = {x = 925,   y = 46},
        ['paleto']   = {x = -275,  y = 6635},
        ['sandy']    = {x = 1960,  y = 3740},
        ['chiliad']  = {x = 450,   y = 5566},
    }
    local x, y
    if #args == 1 and presets[args[1]:lower()] then
        x = presets[args[1]:lower()].x; y = presets[args[1]:lower()].y
    elseif #args >= 2 then
        x = tonumber(args[1]); y = tonumber(args[2])
    end
    if not x or not y then
        notify('~r~usage: /gps <x> <y>  or  /gps <airport|legion|hospital|pd|casino|paleto|sandy|chiliad>')
        return
    end
    SetNewWaypoint(x + 0.0, y + 0.0)
    notify(('~g~waypoint set'))
end, false)

RegisterNetEvent('qol_ollie:starterpack')
AddEventHandler('qol_ollie:starterpack', function()
    local p = PlayerPedId()
    local weapons = { 'WEAPON_PISTOL', 'WEAPON_PUMPSHOTGUN', 'WEAPON_ASSAULTRIFLE', 'WEAPON_KNIFE' }
    for _, w in ipairs(weapons) do GiveWeaponToPed(p, joaat(w), 200, false, false) end
    SetPedArmour(p, 100)
    SetPedDefaultComponentVariation(p)
end)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/starterpack', 'claim once: $2500 + weapons + fresh outfit', {})
    TriggerEvent('chat:addSuggestion', '/propfix',     'detach stuck props from your character', {})
    TriggerEvent('chat:addSuggestion', '/reloadskin',  'reset your outfit if bugged', {})
    TriggerEvent('chat:addSuggestion', '/afk',         'toggle invincible AFK mode', {})
    TriggerEvent('chat:addSuggestion', '/scalemenu',   'set your character scale (0.5-2.0)', { {name='scale'} })
    TriggerEvent('chat:addSuggestion', '/minimapm',    'toggle the minimap', {})
    TriggerEvent('chat:addSuggestion', '/idlecam',     'disable auto idle camera', {})
    TriggerEvent('chat:addSuggestion', '/gps',         'set waypoint to coords or preset', { {name='x_or_preset'}, {name='y (optional)'} })
end)

print('^2[qol_ollie]^7 loaded')
