-- =========================================================
-- client.lua - F5 main menu wiring
-- =========================================================

local godMode     = false
local noClip      = false
local infinAmmo   = false
local invisible   = false
local superSprint = false

local function notify(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(false, true)
end

local function ped() return PlayerPedId() end
local function pid() return PlayerId()    end

-- ========== helpers ==========
local function spawnVehicle(model)
    local m = joaat(model)
    RequestModel(m)
    local t = GetGameTimer()
    while not HasModelLoaded(m) do
        Wait(0)
        if GetGameTimer() - t > 3000 then notify('~r~model load failed: ~w~' .. model) return end
    end
    local p   = ped()
    local pos = GetEntityCoords(p)
    local hd  = GetEntityHeading(p)
    local veh = CreateVehicle(m, pos.x, pos.y, pos.z, hd, true, false)
    SetPedIntoVehicle(p, veh, -1)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetModelAsNoLongerNeeded(m)
    notify('~g~spawned: ~w~' .. model)
end

local function deleteVeh()
    local p = ped()
    if IsPedInAnyVehicle(p, false) then
        local v = GetVehiclePedIsIn(p, false)
        SetEntityAsMissionEntity(v, true, true)
        DeleteVehicle(v)
        notify('~g~vehicle deleted')
    else
        notify('~r~not in a vehicle')
    end
end

local function repairVeh()
    local p = ped()
    if IsPedInAnyVehicle(p, false) then
        local v = GetVehiclePedIsIn(p, false)
        SetVehicleFixed(v); SetVehicleDeformationFixed(v); SetVehicleUndriveable(v, false)
        SetVehicleEngineHealth(v, 1000.0); SetVehicleBodyHealth(v, 1000.0); SetVehiclePetrolTankHealth(v, 1000.0)
        notify('~g~vehicle repaired')
    end
end

local function flipVeh()
    local p = ped()
    if IsPedInAnyVehicle(p, false) then
        local v = GetVehiclePedIsIn(p, false)
        SetVehicleOnGroundProperly(v)
        notify('~g~vehicle flipped')
    end
end

local function giveWeapon(w)
    GiveWeaponToPed(ped(), joaat(w), 500, false, true)
    notify('~g~given: ~w~' .. w:lower():gsub('weapon_',''))
end

local function teleportTo(c)
    local p = ped()
    DoScreenFadeOut(300)
    Wait(320)
    SetEntityCoords(p, c.x, c.y, c.z, false, false, false, true)
    Wait(200)
    DoScreenFadeIn(300)
    notify('~g~teleported')
end

local function setTime(h, m)
    NetworkOverrideClockTime(h, m or 0, 0)
    notify(('~g~time: ~w~%02d:%02d'):format(h, m or 0))
end

local function setWeather(w)
    SetWeatherTypeOverTime(w, 5.0)
    ClearOverrideWeather()
    SetWeatherTypeNow(w)
    SetWeatherTypePersist(w)
    notify('~g~weather: ~w~' .. w)
end

-- ========== noclip ==========
CreateThread(function()
    while true do
        Wait(0)
        if noClip then
            local p = ped()
            SetEntityInvincible(p, true)
            SetEntityVisible(p, not invisible or false, false)
            FreezeEntityPosition(p, true)
            local x, y, z = table.unpack(GetEntityCoords(p))
            local heading = GetEntityHeading(p)
            local dx, dy, dz = 0.0, 0.0, 0.0
            local spd = 0.5
            if IsControlPressed(0, 21) then spd = 1.5 end   -- shift
            if IsControlPressed(0, 32) then                 -- w
                dx = -math.sin(math.rad(heading)) * spd
                dy =  math.cos(math.rad(heading)) * spd
            end
            if IsControlPressed(0, 33) then
                dx =  math.sin(math.rad(heading)) * spd
                dy = -math.cos(math.rad(heading)) * spd
            end
            if IsControlPressed(0, 34) then
                dx = dx + math.sin(math.rad(heading - 90)) * -spd
                dy = dy + math.cos(math.rad(heading - 90)) *  spd
            end
            if IsControlPressed(0, 35) then
                dx = dx + math.sin(math.rad(heading + 90)) * -spd
                dy = dy + math.cos(math.rad(heading + 90)) *  spd
            end
            if IsControlPressed(0, 44) then dz =  spd end  -- q
            if IsControlPressed(0, 38) then dz = -spd end  -- e
            SetEntityCoordsNoOffset(p, x + dx, y + dy, z + dz, true, true, true)
        end
    end
end)

-- ========== god mode ==========
CreateThread(function()
    while true do
        Wait(500)
        if godMode then
            SetPlayerInvincible(pid(), true)
            SetEntityInvincible(ped(), true)
            ClearPedBloodDamage(ped())
            SetEntityHealth(ped(), GetEntityMaxHealth(ped()))
        end
        if infinAmmo then
            local w = GetSelectedPedWeapon(ped())
            if w ~= `WEAPON_UNARMED` then
                SetPedInfiniteAmmo(ped(), true, w)
            end
        end
        if superSprint then
            SetRunSprintMultiplierForPlayer(pid(), 1.49)
            SetPedMoveRateOverride(ped(), 1.49)
        end
    end
end)

-- =========================================================
-- MENUS
-- =========================================================

local function teleportMenu()
    local items = {}
    for _, t in ipairs(Data.teleports) do
        table.insert(items, { label = t.name, onSelect = function() teleportTo(t.coords) end })
    end
    Menu.push(items, 'TELEPORTS')
end

local function vehicleCategoryMenu(cat)
    local items = {}
    for _, v in ipairs(Data.vehicles[cat]) do
        table.insert(items, { label = v, onSelect = function() spawnVehicle(v) end })
    end
    Menu.push(items, cat:upper())
end

local function vehicleMenu()
    local items = {}
    for cat, _ in pairs(Data.vehicles) do
        table.insert(items, { label = cat, submenu = true, onSelect = function() vehicleCategoryMenu(cat) end })
    end
    table.insert(items, 1, { label = 'Repair current',  onSelect = repairVeh })
    table.insert(items, 2, { label = 'Flip current',    onSelect = flipVeh })
    table.insert(items, 3, { label = 'Delete current',  onSelect = deleteVeh })
    Menu.push(items, 'VEHICLES')
end

local function weaponCategoryMenu(cat)
    local items = {}
    for _, w in ipairs(Data.weapons[cat]) do
        table.insert(items, { label = w:lower():gsub('weapon_',''), onSelect = function() giveWeapon(w) end })
    end
    Menu.push(items, cat:upper())
end

local function weaponMenu()
    local items = {
        { label = 'Give ALL weapons', onSelect = function()
            for _, group in pairs(Data.weapons) do
                for _, w in ipairs(group) do GiveWeaponToPed(ped(), joaat(w), 500, false, false) end
            end
            notify('~g~full arsenal loaded')
        end },
        { label = 'Remove all',       onSelect = function() RemoveAllPedWeapons(ped(), true); notify('~g~weapons cleared') end },
        { label = 'Refill ammo',      onSelect = function()
            local p = ped()
            for _, group in pairs(Data.weapons) do
                for _, w in ipairs(group) do
                    local h = joaat(w)
                    if HasPedGotWeapon(p, h, false) then SetPedAmmo(p, h, 500) end
                end
            end
            notify('~g~ammo refilled')
        end },
    }
    for cat, _ in pairs(Data.weapons) do
        table.insert(items, { label = cat, submenu = true, onSelect = function() weaponCategoryMenu(cat) end })
    end
    Menu.push(items, 'WEAPONS')
end

local function selfMenu()
    local items = {
        { label = 'Heal full',  onSelect = function() SetEntityHealth(ped(), GetEntityMaxHealth(ped())); notify('~g~healed') end },
        { label = 'Armor full', onSelect = function() SetPedArmour(ped(), 100); notify('~g~armored') end },
        { label = 'Revive',     onSelect = function()
            local p = ped()
            NetworkResurrectLocalPlayer(GetEntityCoords(p), GetEntityHeading(p), true, false)
            SetPlayerInvincible(pid(), false); ClearPedBloodDamage(p); SetEntityHealth(p, GetEntityMaxHealth(p))
            notify('~g~revived')
        end },
        { label = 'Suicide',    onSelect = function() SetEntityHealth(ped(), 0) end },
        { label = 'Clean skin', onSelect = function() ClearPedBloodDamage(ped()); ClearPedWetness(ped()); notify('~g~cleaned') end },
        { label = 'God Mode',       values = {'Off','On'}, cur = godMode     and 2 or 1, onChange = function(_, i) godMode     = (i==2) end },
        { label = 'No Clip',        values = {'Off','On'}, cur = noClip      and 2 or 1, onChange = function(_, i)
            noClip = (i == 2)
            local p = ped()
            if not noClip then
                SetEntityInvincible(p, godMode)
                FreezeEntityPosition(p, false)
                SetEntityVisible(p, true, false)
            end
            notify(noClip and '~g~noclip on (WASD/QE/shift)' or '~y~noclip off')
        end },
        { label = 'Invisible',      values = {'Off','On'}, cur = invisible   and 2 or 1, onChange = function(_, i) invisible   = (i==2); SetEntityVisible(ped(), not invisible, false) end },
        { label = 'Super Sprint',   values = {'Off','On'}, cur = superSprint and 2 or 1, onChange = function(_, i) superSprint = (i==2) end },
        { label = 'Infinite Ammo',  values = {'Off','On'}, cur = infinAmmo   and 2 or 1, onChange = function(_, i) infinAmmo   = (i==2) end },
    }
    Menu.push(items, 'SELF')
end

local function worldMenu()
    local timeItems = {}
    for h = 0, 23 do table.insert(timeItems, { label = ('%02d:00'):format(h), onSelect = function() setTime(h, 0) end }) end

    local wItems = {}
    for _, w in ipairs(Data.weathers) do
        table.insert(wItems, { label = w, onSelect = function() setWeather(w) end })
    end

    Menu.push({
        { label = 'Set Time',    submenu = true, onSelect = function() Menu.push(timeItems, 'TIME') end },
        { label = 'Set Weather', submenu = true, onSelect = function() Menu.push(wItems,    'WEATHER') end },
        { label = 'Clear Wanted', onSelect = function() SetPlayerWantedLevel(pid(), 0, false); SetPlayerWantedLevelNow(pid(), false); notify('~g~wanted cleared') end },
        { label = 'Max Wanted',   onSelect = function() SetPlayerWantedLevel(pid(), 5, false); SetPlayerWantedLevelNow(pid(), false); notify('~r~wanted maxed') end },
    }, 'WORLD')
end

local function playersMenu()
    TriggerServerEvent('menu_ollie:listPlayers')
end

RegisterNetEvent('menu_ollie:playerList')
AddEventHandler('menu_ollie:playerList', function(list)
    local items = {}
    for _, p in ipairs(list) do
        table.insert(items, {
            label = ('[%d] %s'):format(p.id, p.name),
            submenu = true,
            onSelect = function()
                Menu.push({
                    { label = 'Teleport TO',    onSelect = function() TriggerServerEvent('menu_ollie:tpTo',    p.id) end },
                    { label = 'Teleport them to me', onSelect = function() TriggerServerEvent('menu_ollie:bring', p.id) end },
                    { label = 'Spectate',       onSelect = function()
                        local tgt = GetPlayerFromServerId(p.id)
                        if tgt ~= -1 then
                            local tp = GetPlayerPed(tgt)
                            NetworkSetInSpectatorMode(true, tp)
                            notify('~g~spectating ~w~' .. p.name)
                        end
                    end },
                    { label = 'Stop spectating', onSelect = function() NetworkSetInSpectatorMode(false, 0); notify('~g~returned') end },
                }, p.name)
            end
        })
    end
    if #items == 0 then table.insert(items, { label = '(no other players)' }) end
    Menu.push(items, 'PLAYERS')
end)

RegisterNetEvent('menu_ollie:teleportTo')
AddEventHandler('menu_ollie:teleportTo', function(c)
    teleportTo(vector3(c.x, c.y, c.z))
end)

local function mainMenu()
    Menu.open({
        { label = 'Self',      submenu = true, onSelect = selfMenu },
        { label = 'Teleports', submenu = true, onSelect = teleportMenu },
        { label = 'Vehicles',  submenu = true, onSelect = vehicleMenu },
        { label = 'Weapons',   submenu = true, onSelect = weaponMenu },
        { label = 'World',     submenu = true, onSelect = worldMenu },
        { label = 'Players',   submenu = true, onSelect = playersMenu },
        { label = 'Close',     onSelect = Menu.close },
    }, "OLLIE'S BENCH")
end

-- F5 to open
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, 166) then  -- F5
            if Menu.isOpen() then Menu.close() else mainMenu() end
        end
    end
end)

RegisterCommand('menu', mainMenu, false)
TriggerEvent('chat:addSuggestion', '/menu', 'open the main menu (same as F5)', {})
