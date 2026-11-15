-- =========================================================
-- places_ollie / client.lua - blips + E interactions
-- =========================================================

local function labelFor(p)
    if p.kind == 'signup'  then return '~y~[E]~w~ sign up: ~b~' .. p.name end
    if p.kind == 'shop_247' then return '~y~[E]~w~ buy snack ($5, +25HP)' end
    if p.kind == 'ammu'    then return '~y~[E]~w~ ammunation ($200, pistol+100 ammo)' end
    if p.kind == 'cloth'   then return '~y~[E]~w~ change clothes (free)' end
    if p.kind == 'customs' then return '~y~[E]~w~ repair + wash ($150)' end
    if p.kind == 'gas'     then return '~y~[E]~w~ refuel ($40)' end
    if p.kind == 'bank'    then return '~y~[E]~w~ open phone bank' end
    return '~y~[E]~w~ interact'
end

-- create all blips once
CreateThread(function()
    Wait(500)
    for _, p in ipairs(PLACES) do
        local b = AddBlipForCoord(p.coord.x, p.coord.y, p.coord.z)
        SetBlipSprite(b, p.sprite or 1)
        SetBlipColour(b, p.color or 0)
        SetBlipScale(b, p.scale or 0.75)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(p.name)
        EndTextCommandSetBlipName(b)
    end
end)

local function drawBigMarker(x, y, z, r, g, b)
    local t = GetGameTimer() / 1000.0
    local pulse = 1.3 + math.sin(t * 3.0) * 0.2
    DrawMarker(1, x, y, z - 1.0, 0,0,0, 0,0,0,
        pulse, pulse, 1.2, r, g, b, 180,
        false, true, 2, false, nil, nil, false)
end

local function drawText3D(x, y, z, txt)
    SetDrawOrigin(x, y, z, 0)
    SetTextFont(4); SetTextProportional(1); SetTextScale(0.0, 0.42)
    SetTextColour(255,255,255,255); SetTextOutline()
    SetTextDropshadow(2, 0, 0, 0, 220)
    SetTextCentre(true); SetTextEntry('STRING')
    AddTextComponentString(txt)
    DrawText(0.0, 0.0); ClearDrawOrigin()
end

local function colorFor(p)
    if p.kind == 'signup'  then return 34, 211, 238 end     -- cyan
    if p.kind == 'shop_247' then return 48, 212, 122 end    -- green
    if p.kind == 'ammu'    then return 255, 84, 103 end     -- red
    if p.kind == 'cloth'   then return 255, 46, 126 end     -- pink
    if p.kind == 'customs' then return 255, 176, 32 end     -- orange
    if p.kind == 'gas'     then return 255, 255, 120 end    -- yellow
    if p.kind == 'bank'    then return 168, 85, 247 end     -- purple
    return 200, 200, 200
end

local function doInteract(p)
    if p.kind == 'signup' then
        TriggerServerEvent('jobs_ollie:apply', p.job)
        pcall(function() exports.notify_ezk:success('EMPLOYED', 'signed up as ' .. p.job) end)
    elseif p.kind == 'shop_247' then
        TriggerServerEvent('places_ollie:buy', 'snack', 5, 25)
    elseif p.kind == 'ammu' then
        TriggerServerEvent('places_ollie:buy', 'pistol', 200, 0)
    elseif p.kind == 'cloth' then
        TriggerEvent('char_ollie:openSelector')
    elseif p.kind == 'customs' then
        TriggerServerEvent('places_ollie:buy', 'repair', 150, 0)
    elseif p.kind == 'gas' then
        TriggerServerEvent('places_ollie:buy', 'fuel', 40, 0)
    elseif p.kind == 'bank' then
        ExecuteCommand('phone')
    end
end

-- proximity + E handler
CreateThread(function()
    while true do
        local wait = 1000
        local pc = GetEntityCoords(PlayerPedId())
        for _, p in ipairs(PLACES) do
            local d = #(pc - p.coord)
            if d < 25.0 then
                wait = 0
                local r, g, b = colorFor(p)
                drawBigMarker(p.coord.x, p.coord.y, p.coord.z, r, g, b)
                drawText3D(p.coord.x, p.coord.y, p.coord.z + 2.0, labelFor(p))
                if d < 2.5 and IsControlJustReleased(0, 38) then
                    doInteract(p)
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('places_ollie:buyResult')
AddEventHandler('places_ollie:buyResult', function(what, ok, extra)
    if what == 'snack' and ok then
        local p = PlayerPedId()
        SetEntityHealth(p, math.min(GetEntityMaxHealth(p), GetEntityHealth(p) + 25))
        pcall(function() exports.notify_ezk:success('SNACK', 'bought snack, +25 HP') end)
    elseif what == 'pistol' and ok then
        local p = PlayerPedId()
        GiveWeaponToPed(p, joaat('WEAPON_PISTOL'), 100, false, true)
        pcall(function() exports.notify_ezk:success('AMMUNATION', 'pistol + 100 ammo') end)
    elseif what == 'repair' and ok then
        local p = PlayerPedId()
        if IsPedInAnyVehicle(p, false) then
            local v = GetVehiclePedIsIn(p, false)
            SetVehicleFixed(v); SetVehicleDirtLevel(v, 0.0); SetVehicleEngineHealth(v, 1000.0)
            SetVehicleBodyHealth(v, 1000.0); SetVehiclePetrolTankHealth(v, 1000.0)
            pcall(function() exports.notify_ezk:success('LS CUSTOMS', 'vehicle repaired + washed') end)
        else
            pcall(function() exports.notify_ezk:warn('LS CUSTOMS', 'not in a vehicle (refunded)') end)
            TriggerServerEvent('places_ollie:refund', 150)
        end
    elseif what == 'fuel' and ok then
        pcall(function() exports.notify_ezk:success('GAS', 'tank filled') end)
    elseif not ok then
        pcall(function() exports.notify_ezk:err('BROKE', 'not enough cash: $' .. (extra or '?')) end)
    end
end)
