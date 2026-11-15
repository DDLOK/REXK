CurrentJob = 'unemployed'
OnDuty = false
JobData = { label = 'Unemployed', salary = 0, color = {150,150,150} }
JobCatalog = {}

RegisterNetEvent('jobs_ollie:sync')
AddEventHandler('jobs_ollie:sync', function(s)
    CurrentJob = s.job
    OnDuty     = s.onDuty
    JobData    = s.data
    SendNUIMessage({ action = 'job', job = s.job, label = s.data.label, onDuty = s.onDuty })
end)

RegisterNetEvent('jobs_ollie:catalog')
AddEventHandler('jobs_ollie:catalog', function(c)
    JobCatalog = c
    SendNUIMessage({ action = 'jobCatalog', catalog = c })
end)

AddEventHandler('onClientResourceStart', function(r)
    if r == GetCurrentResourceName() then
        Wait(1000)
        TriggerServerEvent('jobs_ollie:request')
    end
end)

CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/job',  'see or change your job',   { {name='list|apply', help='subcommand'}, {name='jobName', help='for apply'} })
    TriggerEvent('chat:addSuggestion', '/duty', 'toggle on/off duty',       {})
end)

exports('getJob',   function() return CurrentJob end)
exports('isOnDuty', function() return OnDuty end)
