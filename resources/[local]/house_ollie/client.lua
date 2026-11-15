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
    SetEntityCoords(p, h.x, h.y, h.z, false, false, false, true)
    SetEntityHeading(p, h.h)
    CurrentHouse = h
    InsideHouse = false
    Wait(300)
    DoScreenFadeIn(400)
    pcall(function() exports.notify_ezk:send('HOME', h.name .. ' — press E at the blue circle to enter', 'info', 5000) end)

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
    pcall(function() exports.notify_ezk:send('INSIDE', ins.name, 'success', 4000) end)
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

-- big, bright, pulsing markers with floating 3D text
local function drawBigMarker(x, y, z, r, g, b, label)
    -- rising/falling scale (pulsing) + rotation
    local t = GetGameTimer() / 1000.0
    local pulse = 1.8 + math.sin(t * 3.0) * 0.25
    -- filled cylinder going up from ground
    DrawMarker(1, x, y, z - 1.0, 0,0,0, 0,0,0,
        pulse, pulse, 1.5,
        r, g, b, 200,
        false, true, 2, false, nil, nil, false)
    -- bouncing down-arrow above
    local bounce = math.sin(t * 4.0) * 0.15
    DrawMarker(2, x, y, z + 1.6 + bounce, 0,0,0, 180.0, 0,0,
        0.6, 0.6, 0.6,
        r, g, b, 255,
        false, false, 2, false, nil, nil, false)
end

local function drawText3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.0, 0.5)
    SetTextColour(255,255,255,255)
    SetTextOutline()
    SetTextDropshadow(2, 0, 0, 0, 220)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        local wait = 1000
        if CurrentHouse then
            local p = PlayerPedId()
            local pc = GetEntityCoords(p)

            if not InsideHouse then
                local dx, dy, dz = CurrentHouse.x, CurrentHouse.y, CurrentHouse.z
                local wx, wy = fwd(dx, dy, CurrentHouse.h - 90.0, 2.0)
                local wz = dz

                local doorDist = #(pc - vector3(dx, dy, dz))
                if doorDist < 25.0 then
                    wait = 0
                    drawBigMarker(dx, dy, dz, 34, 211, 238)
                    drawText3D(dx, dy, dz + 2.2, '~b~[E]  ENTER HOME')
                    if doorDist < 2.5 and IsControlJustReleased(0, 38) then enterHouse() end
                end

                local wDist = #(pc - vector3(wx, wy, wz))
                if wDist < 25.0 then
                    wait = 0
                    drawBigMarker(wx, wy, wz, 255, 46, 126)
                    drawText3D(wx, wy, wz + 2.2, '~p~[E]  WARDROBE')
                    if wDist < 2.5 and IsControlJustReleased(0, 38) then ExecuteCommand('wardrobe') end
                end
            else
                local ins = CurrentHouse.inside
                local dist = #(pc - vector3(ins.x, ins.y, ins.z))
                if dist < 25.0 then
                    wait = 0
                    drawBigMarker(ins.x, ins.y, ins.z, 255, 180, 60)
                    drawText3D(ins.x, ins.y, ins.z + 2.2, '~y~[E]  LEAVE HOME')
                    if dist < 2.5 and IsControlJustReleased(0, 38) then exitHouse() end
                end
                local wx, wy = ins.x + 1.5, ins.y
                local wDist = #(pc - vector3(wx, wy, ins.z))
                if wDist < 25.0 then
                    wait = 0
                    drawBigMarker(wx, wy, ins.z, 255, 46, 126)
                    drawText3D(wx, wy, ins.z + 2.2, '~p~[E]  WARDROBE')
                    if wDist < 2.5 and IsControlJustReleased(0, 38) then ExecuteCommand('wardrobe') end
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
