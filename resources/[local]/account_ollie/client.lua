-- =========================================================
-- account_ollie / client.lua - HARD gate: no gameplay until logged in
-- =========================================================

LoggedIn    = false
IsAdminFlag = false
Username    = nil
NuiOpen     = false

local SKYCAGE = vector3(-2000.0, -2000.0, 1200.0)

local function notify(txt)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(txt)
    DrawNotification(false, true)
end

local function openLogin()
    if LoggedIn then return end  -- never reopen once logged in
    NuiOpen = true
    SendNUIMessage({ action = 'open' })
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
end

local function closeLogin()
    NuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- GATE THREAD: keep player hidden/invincible/frozen until logged in.
-- NUI focus is only set once in openLogin — re-asserting every tick kills the cursor.
CreateThread(function()
    while true do
        if not LoggedIn then
            local p = PlayerPedId()
            if p ~= 0 and p ~= -1 then
                SetEntityInvincible(p, true)
                SetEntityVisible(p, false, false)
                FreezeEntityPosition(p, true)
                SetPlayerInvisibleLocally(PlayerId(), true)
            end
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

-- hide HUD every frame while gated (HideHudAndRadarThisFrame needs per-frame calls)
CreateThread(function()
    while true do
        if not LoggedIn then
            HideHudAndRadarThisFrame()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- safety net: if focus drops while unlogged, restore. If somehow set while logged in, clear.
CreateThread(function()
    while true do
        Wait(2000)
        if not LoggedIn and NuiOpen and not IsNuiFocused() then
            SetNuiFocus(true, true)
            SetCursorLocation(0.5, 0.5)
        elseif LoggedIn and IsNuiFocused() and not NuiOpen then
            -- stale focus — release it
            SetNuiFocus(false, false)
        end
    end
end)

local function releasePlayer()
    local p = PlayerPedId()
    SetEntityInvincible(p, false)
    SetEntityVisible(p, true, false)
    FreezeEntityPosition(p, false)
    SetPlayerInvisibleLocally(PlayerId(), false)
    SetPlayerControl(PlayerId(), true, 0)
    -- let spawn_ollie / house_ollie take over placement
end

RegisterNetEvent('account_ollie:state')
AddEventHandler('account_ollie:state', function(s)
    local wasLogged = LoggedIn
    LoggedIn    = s.logged
    IsAdminFlag = s.admin
    Username    = s.username
    if LoggedIn then
        closeLogin()
        releasePlayer()
        if not wasLogged then
            TriggerEvent('account_ollie:justLoggedIn')
        end
        notify(('~g~logged in as ~w~%s%s'):format(s.username, s.admin and ' ~y~[ADMIN]' or ''))
    else
        openLogin()
    end
end)

AddEventHandler('account_ollie:justLoggedIn', function()
    -- teleport to a sane place + respawn-ish
    Wait(500)
    TriggerServerEvent('house_ollie:goHome')
end)

AddEventHandler('onClientResourceStart', function(r)
    if r == GetCurrentResourceName() then
        Wait(500)
        TriggerServerEvent('account_ollie:requestState')
    end
end)

AddEventHandler('playerSpawned', function()
    Wait(500)
    if not LoggedIn then
        openLogin()
    end
end)

-- NUI callbacks
RegisterNUICallback('login', function(data, cb)
    TriggerServerEvent('account_ollie:nuiLogin', data.username, data.password)
    cb({ ok = true, msg = 'checking…' })
end)

RegisterNUICallback('register', function(data, cb)
    TriggerServerEvent('account_ollie:nuiRegister', data.username, data.password)
    cb({ ok = true, msg = 'creating…' })
end)

RegisterNUICallback('closed', function(_, cb)
    -- can only close if actually logged in
    if LoggedIn then
        NuiOpen = false
        SetNuiFocus(false, false)
    else
        SendNUIMessage({ action = 'open' })
    end
    cb({})
end)

RegisterNetEvent('account_ollie:nuiResult')
AddEventHandler('account_ollie:nuiResult', function(ok, msg)
    if ok then
        -- state push from server will unlock
    else
        SendNUIMessage({ action = 'open' })
    end
    notify((ok and '~g~' or '~r~') .. msg)
end)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/login',    'login to your account',    { {name='username'}, {name='password'} })
    TriggerEvent('chat:addSuggestion', '/register', 'create a new account',     { {name='username'}, {name='password'} })
    TriggerEvent('chat:addSuggestion', '/logout',   'end your session',         {})
    TriggerEvent('chat:addSuggestion', '/signin',   'open the login UI',        {})
end)

RegisterCommand('signin', openLogin, false)

exports('isLoggedIn', function() return LoggedIn end)
exports('isAdmin',    function() return IsAdminFlag end)
exports('getUsername', function() return Username end)
