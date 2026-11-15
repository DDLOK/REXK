-- =========================================================
-- police_ollie / loadout.lua
-- Cop weapons + vehicles, all using built-in GTA assets but
-- tuned aggressively for an actual RP police feel.
-- =========================================================

local function notify(t)
    SetNotificationTextEntry('STRING'); AddTextComponentString(t); DrawNotification(false, true)
end

local function isCop()
    local ok, j = pcall(function() return exports.jobs_ollie:getJob() end)
    local ok2, d = pcall(function() return exports.jobs_ollie:isOnDuty() end)
    return ok and ok2 and j == 'police' and d == true
end

-- ================== LOADOUT ==================
-- STUN, TASER (uses actual STUNGUN hash), pistol kitted, carbine kitted, shotgun
local POLICE_LOADOUT = {
    { w = 'WEAPON_FLASHLIGHT',    ammo = 1,   comps = {} },
    { w = 'WEAPON_NIGHTSTICK',    ammo = 1,   comps = {} },
    { w = 'WEAPON_STUNGUN',       ammo = 50,  comps = {} },
    { w = 'WEAPON_COMBATPISTOL',  ammo = 300, comps = {
        'COMPONENT_COMBATPISTOL_CLIP_02',
        'COMPONENT_AT_PI_FLSH',
    }},
    { w = 'WEAPON_CARBINERIFLE',  ammo = 300, comps = {
        'COMPONENT_CARBINERIFLE_CLIP_02',
        'COMPONENT_AT_AR_FLSH',
        'COMPONENT_AT_AR_AFGRIP',
        'COMPONENT_AT_SCOPE_MEDIUM',
        'COMPONENT_AT_AR_SUPP_02',
    }},
    { w = 'WEAPON_PUMPSHOTGUN',   ammo = 100, comps = {} },
}

RegisterCommand('loadout', function()
    if not isCop() then notify('~r~on-duty police only') return end
    local p = PlayerPedId()
    for _, item in ipairs(POLICE_LOADOUT) do
        local h = joaat(item.w)
        GiveWeaponToPed(p, h, item.ammo, false, false)
        for _, c in ipairs(item.comps) do
            GiveWeaponComponentToPed(p, h, joaat(c))
        end
        SetPedWeaponTintIndex(p, h, 6)  -- cop blue tint
    end
    SetPedArmour(p, 100)
    SetEntityHealth(p, GetEntityMaxHealth(p))
    -- subtle damage + recoil buff via weapon stats (per-client)
    local function buff(w, dmg)
        SetWeaponDamageModifier(joaat(w), dmg)
    end
    buff('WEAPON_COMBATPISTOL',  1.15)
    buff('WEAPON_CARBINERIFLE',  1.15)
    buff('WEAPON_PUMPSHOTGUN',   1.25)
    notify('~b~LOADOUT:~w~ kitted up')
end, false)

-- ================== VEHICLE ==================
local POLICE_CARS = {
    ['police']   = 'LSPD Cruiser',
    ['police2']  = 'LSPD Buffalo',
    ['police3']  = 'LSPD Interceptor (fastest)',
    ['police4']  = 'LSPD Unmarked',
    ['policeb']  = 'Police Bike',
    ['policet']  = 'Police Transporter',
    ['sheriff']  = 'Sheriff Cruiser',
    ['sheriff2'] = 'Sheriff SUV',
    ['fbi']      = 'FBI Sedan',
    ['fbi2']     = 'FBI SUV',
}

RegisterCommand('police', function(_, args)
    if not isCop() then notify('~r~on-duty police only') return end
    local model = args[1] or 'police3'
    if not POLICE_CARS[model] then
        notify('~y~pick: police / police2 / police3 / police4 / policeb / sheriff / fbi / fbi2')
        return
    end
    local m = joaat(model)
    RequestModel(m)
    local t = GetGameTimer()
    while not HasModelLoaded(m) do Wait(0); if GetGameTimer() - t > 3000 then notify('~r~model fail') return end end
    local p = PlayerPedId()
    local pos = GetEntityCoords(p)
    local hd  = GetEntityHeading(p)
    local veh = CreateVehicle(m, pos.x + 2.0, pos.y, pos.z, hd, true, false)
    SetModelAsNoLongerNeeded(m)

    -- MAX MODS
    SetVehicleModKit(veh, 0)
    for i = 11, 16 do SetVehicleMod(veh, i, GetNumVehicleMods(veh, i) - 1, false) end  -- engine/brakes/transmission/suspension/armor
    SetVehicleMod(veh, 18, 0, false)  -- turbo
    ToggleVehicleMod(veh, 18, true)   -- turbo on
    SetVehicleEnginePowerMultiplier(veh, 50.0)  -- +50% HP
    SetVehicleEngineTorqueMultiplier(veh, 1.3)
    ModifyVehicleTopSpeed(veh, 1.2)
    SetVehicleCanBeVisiblyDamaged(veh, false)
    SetVehicleFixed(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetPedIntoVehicle(p, veh, -1)

    notify('~b~SPAWN:~w~ ' .. (POLICE_CARS[model] or model) .. ' - fully upgraded')
end, false)

RegisterCommand('sirens', function()
    local p = PlayerPedId()
    if not IsPedInAnyVehicle(p, false) then return end
    local v = GetVehiclePedIsIn(p, false)
    local on = IsVehicleSirenOn(v)
    SetVehicleSiren(v, not on)
end, false)

RegisterCommand('lights', function()
    local p = PlayerPedId()
    if not IsPedInAnyVehicle(p, false) then return end
    local v = GetVehiclePedIsIn(p, false)
    local state = GetVehicleLightsState(v)
    SetVehicleLights(v, state == 2 and 0 or 2)
end, false)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/loadout', 'give yourself police loadout (on duty)', {})
    TriggerEvent('chat:addSuggestion', '/police',  'spawn a police car (on duty)', { {name='model', help='police|police2|police3|sheriff|fbi'} })
    TriggerEvent('chat:addSuggestion', '/sirens',  'toggle siren', {})
    TriggerEvent('chat:addSuggestion', '/lights',  'toggle lights', {})
end)
