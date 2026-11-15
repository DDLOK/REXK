local phoneOpen = false

local function open()
    if phoneOpen then return end
    phoneOpen = true
    SetNuiFocus(true, true)
    TriggerServerEvent('phone_ollie:requestContacts')
    SendNUIMessage({ action = 'open' })
end

local function close()
    phoneOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('phone', open, false)
RegisterKeyMapping('phone', 'Open Phone', 'keyboard', 'F1')

RegisterNUICallback('close', function(_, cb) close(); cb({}) end)

RegisterNUICallback('applyJob', function(d, cb)
    TriggerServerEvent('phone_ollie:applyJob', d.job)
    cb({ ok = true })
end)

RegisterNUICallback('pay', function(d, cb)
    TriggerServerEvent('phone_ollie:pay', d.targetId, d.amount)
    cb({ ok = true })
end)

RegisterNUICallback('setWaypoint', function(d, cb)
    local x = tonumber(d.x) or 0
    local y = tonumber(d.y) or 0
    SetNewWaypoint(x, y)
    cb({ ok = true })
end)

RegisterNUICallback('requestContacts', function(_, cb)
    TriggerServerEvent('phone_ollie:requestContacts')
    cb({ ok = true })
end)

RegisterNUICallback('duty', function(_, cb)
    ExecuteCommand('duty')
    cb({ ok = true })
end)

RegisterNetEvent('phone_ollie:contacts')
AddEventHandler('phone_ollie:contacts', function(list)
    SendNUIMessage({ action = 'contacts', list = list })
end)

RegisterNetEvent('jobs_ollie:catalog')
AddEventHandler('jobs_ollie:catalog', function(c)
    SendNUIMessage({ action = 'jobCatalog', catalog = c })
end)

RegisterNetEvent('jobs_ollie:sync')
AddEventHandler('jobs_ollie:sync', function(s)
    SendNUIMessage({ action = 'job', job = s.job, label = s.data.label, onDuty = s.onDuty })
end)

RegisterNetEvent('cash_ollie:sync')
AddEventHandler('cash_ollie:sync', function(v)
    SendNUIMessage({ action = 'cash', value = v })
end)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/phone', 'open your phone (F1)', {})
end)
