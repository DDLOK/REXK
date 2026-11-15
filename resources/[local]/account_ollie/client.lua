-- =========================================================
-- account_ollie / client.lua - gatekeeps spawn until logged in
-- =========================================================

LoggedIn = false
IsAdminFlag = false
Username = nil

RegisterNetEvent('account_ollie:state')
AddEventHandler('account_ollie:state', function(s)
    LoggedIn    = s.logged
    IsAdminFlag = s.admin
    Username    = s.username
    if LoggedIn then
        SetNotificationTextEntry('STRING')
        AddTextComponentString(('~g~logged in as ~w~%s%s'):format(s.username, s.admin and ' ~y~[ADMIN]' or ''))
        DrawNotification(false, true)
    end
end)

AddEventHandler('onClientResourceStart', function(r)
    if r == GetCurrentResourceName() then
        TriggerServerEvent('account_ollie:requestState')
    end
end)

CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/login',    'login to your account',    { {name='username'}, {name='password'} })
    TriggerEvent('chat:addSuggestion', '/register', 'create a new account',     { {name='username'}, {name='password'} })
    TriggerEvent('chat:addSuggestion', '/logout',   'end your session',         {})
end)

-- exports to other resources
exports('isLoggedIn', function() return LoggedIn end)
exports('isAdmin',    function() return IsAdminFlag end)
exports('getUsername', function() return Username end)
