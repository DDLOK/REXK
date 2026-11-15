-- =========================================================
-- jobs_ollie / work.lua - gameplay loops for each job
-- loaded as additional client_script
-- =========================================================

local activeJob = nil
local wpBlip = nil
local wpPed = nil
local wpVeh = nil

local function notify(txt)
    SetNotificationTextEntry('STRING'); AddTextComponentString(txt); DrawNotification(false, true)
end

local function clearJob()
    if wpBlip then RemoveBlip(wpBlip); wpBlip = nil end
    if wpPed and DoesEntityExist(wpPed) then DeleteEntity(wpPed); wpPed = nil end
    if wpVeh and DoesEntityExist(wpVeh) then SetEntityAsMissionEntity(wpVeh, true, true); DeleteEntity(wpVeh); wpVeh = nil end
    activeJob = nil
end

local function setBlip(x, y, z, sprite, color, label)
    if wpBlip then RemoveBlip(wpBlip) end
    wpBlip = AddBlipForCoord(x, y, z)
    SetBlipSprite(wpBlip, sprite or 1)
    SetBlipColour(wpBlip, color or 5)
    SetBlipRoute(wpBlip, true)
    SetBlipRouteColour(wpBlip, color or 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'Job')
    EndTextCommandSetBlipName(wpBlip)
end

-- ============ TAXI ============
local TAXI_STOPS = {
    vector3(-1037.0, -2737.0, 20.2),
    vector3( 428.5,  -981.1, 30.7),
    vector3( 925.0,   46.0,  81.1),
    vector3(1960.0,  3740.0, 32.3),
    vector3(-275.0,  6635.0,  7.4),
    vector3(-852.0,   160.0, 66.0),
    vector3( 7.9,     548.0, 175.4),
    vector3( 215.0,  -810.0, 30.7),
    vector3(-1282.0, -1117.0,  6.6),
}

local function pickFar(from)
    local best, bestD = nil, 0
    for _, s in ipairs(TAXI_STOPS) do
        local d = #(from - s)
        if d > bestD then best = s; bestD = d end
    end
    return best
end

local function startTaxi()
    local p = PlayerPedId()
    local me = GetEntityCoords(p)
    local pickup = TAXI_STOPS[math.random(#TAXI_STOPS)]
    setBlip(pickup.x, pickup.y, pickup.z, 198, 5, 'Taxi: Pickup')
    notify('~y~TAXI:~w~ drive to the pickup')
    activeJob = { kind = 'taxi', phase = 'toPickup', pickup = pickup }

    CreateThread(function()
        while activeJob and activeJob.kind == 'taxi' do
            Wait(500)
            local pos = GetEntityCoords(PlayerPedId())
            if activeJob.phase == 'toPickup' and #(pos - activeJob.pickup) < 8.0 then
                -- spawn passenger
                local m = `a_m_m_business_01`
                RequestModel(m); while not HasModelLoaded(m) do Wait(0) end
                wpPed = CreatePed(4, m, activeJob.pickup.x, activeJob.pickup.y, activeJob.pickup.z, 0.0, true, false)
                SetModelAsNoLongerNeeded(m)
                -- find nearby vehicle player is in; else fail-safe spawn one
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if veh ~= 0 then
                    TaskEnterVehicle(wpPed, veh, -1, 2, 2.0, 1, 0)
                else
                    notify('~r~TAXI:~w~ get in a car first')
                end
                local dest = pickFar(activeJob.pickup)
                activeJob.phase = 'toDest'
                activeJob.dest = dest
                setBlip(dest.x, dest.y, dest.z, 162, 2, 'Taxi: Drop-off')
                notify('~g~TAXI:~w~ drive the passenger to the drop-off')
            elseif activeJob.phase == 'toDest' and #(pos - activeJob.dest) < 10.0 then
                local pay = math.random(300, 600)
                TriggerServerEvent('jobs_ollie:pay', 'taxi', pay)
                notify(('~g~TAXI:~w~ fare delivered, +~g~$%d'):format(pay))
                if wpPed and DoesEntityExist(wpPed) then
                    TaskWanderStandard(wpPed, 10.0, 10)
                end
                clearJob()
            end
        end
    end)
end

-- ============ TRUCKER ============
local TRUCK_YARDS = {
    vector3(  -83.0,  6490.0, 31.5),
    vector3( 1230.0, -3250.0,  5.0),
    vector3(   50.0, -1740.0, 29.3),
}

local function startTrucker()
    local me = GetEntityCoords(PlayerPedId())
    local from = TRUCK_YARDS[math.random(#TRUCK_YARDS)]
    local to   = TRUCK_YARDS[math.random(#TRUCK_YARDS)]
    while to == from do to = TRUCK_YARDS[math.random(#TRUCK_YARDS)] end
    activeJob = { kind = 'trucker', phase = 'toLoad', from = from, to = to }
    setBlip(from.x, from.y, from.z, 477, 5, 'Trucker: Load')
    notify('~y~TRUCKER:~w~ go to the loading yard')

    CreateThread(function()
        while activeJob and activeJob.kind == 'trucker' do
            Wait(1000)
            local pos = GetEntityCoords(PlayerPedId())
            if activeJob.phase == 'toLoad' and #(pos - activeJob.from) < 20.0 then
                notify('~g~TRUCKER:~w~ loaded. drive to drop-off')
                setBlip(activeJob.to.x, activeJob.to.y, activeJob.to.z, 477, 2, 'Trucker: Drop')
                activeJob.phase = 'toDest'
            elseif activeJob.phase == 'toDest' and #(pos - activeJob.to) < 20.0 then
                local pay = math.random(500, 900)
                TriggerServerEvent('jobs_ollie:pay', 'trucker', pay)
                notify(('~g~TRUCKER:~w~ delivered, +~g~$%d'):format(pay))
                clearJob()
            end
        end
    end)
end

-- ============ CRIMINAL ============
local STORES = {
    vector3( 25.7,   -1347.3, 29.5),  -- 24/7 Strawberry
    vector3(-47.5,   -1757.5, 29.4),  -- LTD Grove
    vector3(1163.4,  -323.0,  69.2),  -- 24/7 Mirror Park
    vector3(2557.9,   382.1,  108.6), -- 24/7 Tataviam
}

local function startRob()
    local me = GetEntityCoords(PlayerPedId())
    local target = STORES[math.random(#STORES)]
    activeJob = { kind = 'crime', phase = 'toStore', target = target }
    setBlip(target.x, target.y, target.z, 52, 1, 'Robbery: Store')
    notify('~r~CRIMINAL:~w~ hit the marked store')

    CreateThread(function()
        while activeJob and activeJob.kind == 'crime' do
            Wait(500)
            local pos = GetEntityCoords(PlayerPedId())
            if activeJob.phase == 'toStore' and #(pos - activeJob.target) < 3.0 then
                notify('~r~ROBBERY:~w~ hold still for 30s')
                SetPlayerWantedLevel(PlayerId(), 3, false)
                SetPlayerWantedLevelNow(PlayerId(), false)
                activeJob.phase = 'holding'
                activeJob.until_ = GetGameTimer() + 30000
            elseif activeJob.phase == 'holding' then
                local pos2 = GetEntityCoords(PlayerPedId())
                if #(pos2 - activeJob.target) > 4.0 then
                    notify('~r~ROBBERY FAILED:~w~ you moved')
                    clearJob()
                elseif GetGameTimer() >= activeJob.until_ then
                    local pay = math.random(800, 1800)
                    TriggerServerEvent('jobs_ollie:pay', 'criminal', pay)
                    notify(('~g~GRAB:~w~ got ~g~$%d'):format(pay))
                    clearJob()
                end
            end
        end
    end)
end

-- ============ MECHANIC ============
local function startMech()
    local me = GetEntityCoords(PlayerPedId())
    -- pick a random coord 300-800m away
    local ang = math.random() * math.pi * 2
    local dist = 400 + math.random() * 400
    local tx = me.x + math.cos(ang) * dist
    local ty = me.y + math.sin(ang) * dist
    local found, z = GetGroundZFor_3dCoord(tx, ty, 1000.0, false)
    local tz = found and z or me.z
    activeJob = { kind = 'mech', phase = 'toCar', target = vector3(tx, ty, tz) }
    setBlip(tx, ty, tz, 446, 5, 'Mechanic: Breakdown')
    notify('~y~MECHANIC:~w~ customer with a dead car needs you')

    CreateThread(function()
        while activeJob and activeJob.kind == 'mech' do
            Wait(500)
            local pos = GetEntityCoords(PlayerPedId())
            if activeJob.phase == 'toCar' and #(pos - activeJob.target) < 5.0 then
                notify('~g~MECHANIC:~w~ hold position 15s to repair')
                activeJob.phase = 'fixing'
                activeJob.until_ = GetGameTimer() + 15000
            elseif activeJob.phase == 'fixing' then
                local pos2 = GetEntityCoords(PlayerPedId())
                if #(pos2 - activeJob.target) > 5.5 then
                    notify('~r~MECHANIC FAILED:~w~ left the car')
                    clearJob()
                elseif GetGameTimer() >= activeJob.until_ then
                    local pay = math.random(400, 700)
                    TriggerServerEvent('jobs_ollie:pay', 'mechanic', pay)
                    notify(('~g~REPAIRED:~w~ +~g~$%d'):format(pay))
                    clearJob()
                end
            end
        end
    end)
end

local LOOPS = {
    taxi     = startTaxi,
    trucker  = startTrucker,
    criminal = startRob,
    mechanic = startMech,
    ems      = function() notify('~y~EMS:~w~ revive downed players for cash (coming)') end,
    police   = function() notify('~b~POLICE:~w~ patrol + /cuff /uncuff on duty') end,
}

RegisterCommand('work', function()
    local job = exports.jobs_ollie:getJob()
    local onDuty = exports.jobs_ollie:isOnDuty()
    if job == 'unemployed' then notify('~r~get a job first (phone > jobs)') return end
    if not onDuty then notify('~r~go on duty first: /duty') return end
    if activeJob then
        notify('~y~you already have an active job. /canceljob to drop it')
        return
    end
    local fn = LOOPS[job]
    if fn then fn() else notify('~r~no work loop for this job') end
end, false)

RegisterCommand('canceljob', function()
    if activeJob then
        clearJob()
        notify('~y~job cancelled')
    end
end, false)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/work',      'start a job task (must be on duty)', {})
    TriggerEvent('chat:addSuggestion', '/canceljob', 'cancel your current work task', {})
end)
