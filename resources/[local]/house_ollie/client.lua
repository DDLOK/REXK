CurrentHouse = nil

local function fwd(x, y, hd, dist)
    local rad = math.rad(hd)
    return x - math.sin(rad) * dist, y + math.cos(rad) * dist
end

RegisterNetEvent('house_ollie:teleport')
AddEventHandler('house_ollie:teleport', function(h)
    local p = PlayerPedId()
    DoScreenFadeOut(400)
    Wait(420)
    SetEntityCoords(p, h.x, h.y, h.z, false, false, false, true)
    SetEntityHeading(p, h.h)
    CurrentHouse = h
    Wait(300)
    DoScreenFadeIn(400)
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~p~home: ~w~' .. h.name .. '  ~y~[E on wardrobe for clothes]')
    DrawNotification(false, true)

    -- add a blip once per house
    local blip = AddBlipForCoord(h.x, h.y, h.z)
    SetBlipSprite(blip, 40)      -- house
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.9)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Home: ' .. h.name)
    EndTextCommandSetBlipName(blip)
end)

-- wardrobe marker + interaction
CreateThread(function()
    while true do
        local wait = 1000
        if CurrentHouse then
            local p = PlayerPedId()
            local pc = GetEntityCoords(p)
            -- wardrobe is 2m to the side of the house spawn, 1m back
            local wx, wy = fwd(CurrentHouse.x, CurrentHouse.y, CurrentHouse.h - 90.0, 2.0)
            local wz = CurrentHouse.z
            local dist = #(pc - vector3(wx, wy, wz))
            if dist < 20.0 then
                wait = 0
                DrawMarker(27, wx, wy, wz - 0.95, 0,0,0, 0,0,0, 1.6, 1.6, 0.4,
                    255, 46, 126, 120, false, true, 2, false, nil, nil, false)
                if dist < 1.8 then
                    SetTextFont(4); SetTextScale(0.0, 0.42)
                    SetTextColour(255,255,255,255); SetTextOutline()
                    SetTextCentre(true); SetTextEntry('STRING')
                    AddTextComponentString('~y~[E]~w~ open wardrobe')
                    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(wx, wy, wz + 0.5)
                    if onScreen then DrawText(_x, _y) end
                    if IsControlJustReleased(0, 38) then  -- E
                        ExecuteCommand('wardrobe')
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
