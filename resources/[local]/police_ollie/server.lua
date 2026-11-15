local function isCop(src)
    local ok, j = pcall(function() return exports.jobs_ollie:getJob(src) end)
    local ok2, d = pcall(function() return exports.jobs_ollie:isOnDuty(src) end)
    return ok and ok2 and j == 'police' and d == true
end

local function reply(src, color, author, msg)
    TriggerClientEvent('chat:addMessage', src, { color = color, args = { author, msg } })
end

RegisterNetEvent('police_ollie:cuff')
AddEventHandler('police_ollie:cuff', function(targetId)
    local src = source
    if not isCop(src) then reply(src, {255,80,80}, 'PD', 'not an on-duty officer') return end
    if GetPlayerPed(targetId) == 0 then return end
    TriggerClientEvent('police_ollie:applyCuff', targetId, true)
    reply(src, {100,200,255}, 'PD', 'cuffed ' .. GetPlayerName(targetId))
    TriggerClientEvent('chat:addMessage', targetId, { color = {255,100,100}, args = { 'PD', 'you have been cuffed' } })
end)

RegisterNetEvent('police_ollie:uncuff')
AddEventHandler('police_ollie:uncuff', function(targetId)
    local src = source
    if not isCop(src) then reply(src, {255,80,80}, 'PD', 'not an on-duty officer') return end
    if GetPlayerPed(targetId) == 0 then return end
    TriggerClientEvent('police_ollie:applyCuff', targetId, false)
    reply(src, {100,200,255}, 'PD', 'uncuffed ' .. GetPlayerName(targetId))
end)

print('^2[police_ollie]^7 loaded')
