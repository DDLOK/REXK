-- =========================================================
-- account_ollie / client.lua - NUI login + state sync
-- =========================================================

LoggedIn    = false
IsAdminFlag = false
Username    = nil
NuiOpen     = false

local function notify(txt)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(txt)
    DrawNotification(false, true)
end

local function openLogin()
    if NuiOpen then return end
    NuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

local function closeLogin()
    NuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNetEvent('account_ollie:state')
AddEventHandler('account_ollie:state', function(s)
    LoggedIn    = s.logged
    IsAdminFlag = s.admin
    Username    = s.username
    if LoggedIn then
        closeLogin()
        notify(('~g~logged in as ~w~%s%s'):format(s.username, s.admin and ' ~y~[ADMIN]' or ''))
    else
        openLogin()
    end
end)

AddEventHandler('onClientResourceStart', function(r)
    if r == GetCurrentResourceName() then
        Wait(500)
        TriggerServerEvent('account_ollie:requestState')
    end
end)

AddEventHandler('playerSpawned', function()
    Wait(1000)
    if not LoggedIn then openLogin() end
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
    NuiOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNetEvent('account_ollie:nuiResult')
AddEventHandler('account_ollie:nuiResult', function(ok, msg)
    SendNUIMessage({ action = ok and 'close' or 'open' })
    if ok then
        closeLogin()
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
