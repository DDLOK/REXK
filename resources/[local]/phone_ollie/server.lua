RegisterNetEvent('phone_ollie:applyJob')
AddEventHandler('phone_ollie:applyJob', function(job)
    local src = source
    TriggerEvent('jobs_ollie:apply', job); -- call the jobs server handler
    local ok, r = pcall(function() return exports.jobs_ollie:setJob(src, job) end)
    if ok and r then
        TriggerClientEvent('chat:addMessage', src, { color = {120,200,255}, args = { 'PHONE', 'job applied' } })
    end
end)

RegisterNetEvent('phone_ollie:pay')
AddEventHandler('phone_ollie:pay', function(targetId, amount)
    local src = source
    amount = tonumber(amount) or 0
    targetId = tonumber(targetId) or 0
    if amount <= 0 or targetId <= 0 or targetId == src then return end
    if GetPlayerPed(targetId) == 0 then
        TriggerClientEvent('chat:addMessage', src, { color = {255,80,80}, args = { 'PHONE', 'target offline' } })
        return
    end
    local ok = exports.cash_ollie:removeCash(src, amount)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = {255,80,80}, args = { 'PHONE', 'insufficient funds' } })
        return
    end
    exports.cash_ollie:addCash(targetId, amount)
    TriggerClientEvent('chat:addMessage', src,      { color = {100,255,150}, args = { 'PHONE', ('sent $%d to %s'):format(amount, GetPlayerName(targetId)) } })
    TriggerClientEvent('chat:addMessage', targetId, { color = {100,255,150}, args = { 'PHONE', ('received $%d from %s'):format(amount, GetPlayerName(src)) } })
end)

RegisterNetEvent('phone_ollie:requestContacts')
AddEventHandler('phone_ollie:requestContacts', function()
    local src = source
    local list = {}
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        table.insert(list, { id = pid, name = GetPlayerName(pid) or ('player ' .. pid), self = (pid == src) })
    end
    TriggerClientEvent('phone_ollie:contacts', src, list)
end)

print('^2[phone_ollie]^7 loaded')
