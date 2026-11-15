-- =========================================================
-- spawn_ollie - skip default spawn, land at a sane spot
-- =========================================================

local spawns = {
    { name = 'Legion Sq',      coords = vector3( 215.0, -810.0,  30.7), h = 160.0 },
    { name = 'LSIA',           coords = vector3(-1037.0, -2737.7, 20.2), h = 328.0 },
    { name = 'Sandy Shores',   coords = vector3( 1960.0,  3740.0, 32.3), h = 200.0 },
    { name = 'Paleto Bay',     coords = vector3(-275.0,   6635.0,  7.4), h = 220.0 },
    { name = 'Mt Chiliad',     coords = vector3( 450.0,   5566.0, 781.1), h = 180.0 },
    { name = 'Grove Street',   coords = vector3(  83.0,  -1948.0, 20.8), h =  47.0 },
}

AddEventHandler('playerSpawned', function()
    -- if logged in, prefer going home; else random spawn point
    Wait(500)
    local loggedIn = false
    pcall(function() loggedIn = exports.account_ollie:isLoggedIn() end)
    if loggedIn then
        TriggerServerEvent('house_ollie:goHome')
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~p~home sweet home ~y~[F5 for menu]')
        DrawNotification(false, true)
        return
    end
    local s = spawns[math.random(#spawns)]
    local p = PlayerPedId()
    SetEntityCoords(p, s.coords.x, s.coords.y, s.coords.z, false, false, false, true)
    SetEntityHeading(p, s.h)
    SetPedDefaultComponentVariation(p)
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~p~spawned: ~w~' .. s.name .. '  ~y~[F5 for menu / sign in with the EZK form]')
    DrawNotification(false, true)
end)
