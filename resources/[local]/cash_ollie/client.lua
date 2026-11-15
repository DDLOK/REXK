local balance = 0

RegisterNetEvent('cash_ollie:sync')
AddEventHandler('cash_ollie:sync', function(v)
    balance = v
    SendNUIMessage({ action = 'cash', value = v })
end)

AddEventHandler('onClientResourceStart', function(r)
    if r == GetCurrentResourceName() then
        Wait(800)
        TriggerServerEvent('cash_ollie:request')
    end
end)

AddEventHandler('playerSpawned', function()
    Wait(500)
    TriggerServerEvent('cash_ollie:request')
end)

CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/balance', 'check your wallet', {})
    TriggerEvent('chat:addSuggestion', '/pay', 'send money to a player', { {name='id'}, {name='amount'} })
end)

exports('getCash', function() return balance end)
