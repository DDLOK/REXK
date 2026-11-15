CurrentHouse = nil
InsideHouse = false
local currentBlip = nil

local function fwd(x, y, hd, dist)
    local rad = math.rad(hd)
    return x - math.sin(rad) * dist, y + math.cos(rad) * dist
end

local function loadIpl(ipl)
    if ipl and not IsIplActive(ipl) then RequestIpl(ipl) end
end

RegisterNetEvent('house_ollie:teleport')
AddEventHandler('house_ollie:teleport', function(h)
    local p = PlayerPedId()
    DoScreenFadeOut(400)
    Wait(420)
    -- land outside first so blips work
    SetEntityCoords(p, h.x, h.y, h.z, false, false, false, true)
    SetEntityHeading(p, h.h)
    CurrentHouse = h
    InsideHouse = false
    Wait(300)
    DoScreenFadeIn(400)
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~p~' .. h.name .. '  ~y~[E to enter / wardrobe nearby]')
    DrawNotification(false, true)

    if currentBlip then RemoveBlip(currentBlip) end
    currentBlip = AddBlipForCoord(h.x, h.y, h.z)
    SetBlipSprite(currentBlip, 40)
    SetBlipColour(currentBlip, 2)
    SetBlipScale(currentBlip, 0.9)
    SetBlipAsShortRange(currentBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Home: ' .. h.name)
    EndTextCommandSetBlipName(currentBlip)
end)

local function enterHouse()
    if not CurrentHouse or not CurrentHouse.inside then return end
    local p = PlayerPedId()
    DoScreenFadeOut(500); Wait(520)
    loadIpl(CurrentHouse.inside.ipl)
    local ins = CurrentHouse.inside
    SetEntityCoords(p, ins.x, ins.y, ins.z, false, false, false, true)
    SetEntityHeading(p, ins.h)
    InsideHouse = true
    Wait(400)
    DoScreenFadeIn(500)
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~g~inside: ~w~' .. ins.name .. '  ~y~[E near door to leave]')
    DrawNotification(false, true)
end

local function exitHouse()
    if not CurrentHouse then return end
    local p = PlayerPedId()
    DoScreenFadeOut(500); Wait(520)
    SetEntityCoords(p, CurrentHouse.x, CurrentHouse.y, CurrentHouse.z, false, false, false, true)
    SetEntityHeading(p, CurrentHouse.h)
    InsideHouse = false
    Wait(300)
    DoScreenFadeIn(500)
end

-- door + wardrobe markers + interactions
CreateThread(function()
    while true do
        local wait = 1000
        if CurrentHouse then
            local p = PlayerPedId()
            local pc = GetEntityCoords(p)

            if not InsideHouse then
                -- outside: show entrance door + wardrobe marker
                local dx, dy = CurrentHouse.x, CurrentHouse.y
                local wx, wy = fwd(CurrentHouse.x, CurrentHouse.y, CurrentHouse.h - 90.0, 2.0)
                local wz = CurrentHouse.z

                local doorDist = #(pc - vector3(dx, dy, CurrentHouse.z))
                if doorDist < 20.0 then
                    wait = 0
                    DrawMarker(27, dx, dy, CurrentHouse.z - 0.95, 0,0,0, 0,0,0, 1.6, 1.6, 0.4,
                        34, 211, 238, 130, false, true, 2, false, nil, nil, false)
                    if doorDist < 1.8 then
                        SetTextFont(4); SetTextScale(0.0, 0.42)
                        SetTextColour(255,255,255,255); SetTextOutline(); SetTextCentre(true); SetTextEntry('STRING')
                        AddTextComponentString('~y~[E]~w~ enter home')
                        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(dx, dy, CurrentHouse.z + 0.5)
                        if onScreen then DrawText(_x, _y) end
                        if IsControlJustReleased(0, 38) then enterHouse() end
                    end
                end

                local wDist = #(pc - vector3(wx, wy, wz))
                if wDist < 20.0 then
                    wait = 0
                    DrawMarker(27, wx, wy, wz - 0.95, 0,0,0, 0,0,0, 1.6, 1.6, 0.4,
                        255, 46, 126, 120, false, true, 2, false, nil, nil, false)
                    if wDist < 1.8 then
                        SetTextFont(4); SetTextScale(0.0, 0.42)
                        SetTextColour(255,255,255,255); SetTextOutline(); SetTextCentre(true); SetTextEntry('STRING')
                        AddTextComponentString('~y~[E]~w~ wardrobe')
                        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(wx, wy, wz + 0.5)
                        if onScreen then DrawText(_x, _y) end
                        if IsControlJustReleased(0, 38) then ExecuteCommand('wardrobe') end
                    end
                end
            else
                -- inside: show exit near the interior entry point
                local ins = CurrentHouse.inside
                local dist = #(pc - vector3(ins.x, ins.y, ins.z))
                if dist < 20.0 then
                    wait = 0
                    DrawMarker(27, ins.x, ins.y, ins.z - 0.95, 0,0,0, 0,0,0, 1.6, 1.6, 0.4,
                        255, 180, 60, 130, false, true, 2, false, nil, nil, false)
                    if dist < 1.8 then
                        SetTextFont(4); SetTextScale(0.0, 0.42)
                        SetTextColour(255,255,255,255); SetTextOutline(); SetTextCentre(true); SetTextEntry('STRING')
                        AddTextComponentString('~y~[E]~w~ leave home')
                        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(ins.x, ins.y, ins.z + 0.5)
                        if onScreen then DrawText(_x, _y) end
                        if IsControlJustReleased(0, 38) then exitHouse() end
                    end
                end
                -- also allow wardrobe from inside via /wardrobe or inside marker at offset
                local wx, wy = ins.x + 1.5, ins.y
                local wDist = #(pc - vector3(wx, wy, ins.z))
                if wDist < 20.0 then
                    wait = 0
                    DrawMarker(27, wx, wy, ins.z - 0.95, 0,0,0, 0,0,0, 1.0, 1.0, 0.4,
                        255, 46, 126, 120, false, true, 2, false, nil, nil, false)
                    if wDist < 1.4 then
                        SetTextFont(4); SetTextScale(0.0, 0.42)
                        SetTextColour(255,255,255,255); SetTextOutline(); SetTextCentre(true); SetTextEntry('STRING')
                        AddTextComponentString('~y~[E]~w~ wardrobe')
                        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(wx, wy, ins.z + 0.5)
                        if onScreen then DrawText(_x, _y) end
                        if IsControlJustReleased(0, 38) then ExecuteCommand('wardrobe') end
                    end
                end
            end
        end
        Wait(wait)
    end
end)

RegisterCommand('wardrobe', function()
    -- delegate to menu_ollie: open Self > Clothing directly
    TriggerEvent('menu_ollie:openClothing')
end, false)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/home',     'teleport to your house', {})
    TriggerEvent('chat:addSuggestion', '/myhouse',  'see which house is yours', {})
    TriggerEvent('chat:addSuggestion', '/rehouse',  'get reassigned to a new house', {})
    TriggerEvent('chat:addSuggestion', '/wardrobe', 'open the clothing menu', {})
end)
