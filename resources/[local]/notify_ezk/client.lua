-- =========================================================
-- notify_ezk / client.lua - NUI toast queue
-- call: exports.notify_ezk:send(title, body, type, duration)
--       type: 'info' | 'success' | 'warning' | 'error' | 'cash'
-- =========================================================

local function notify(title, body, kind, duration)
    SendNUIMessage({
        action = 'notify',
        title = tostring(title or ''),
        body = tostring(body or ''),
        kind = kind or 'info',
        duration = duration or 4000,
    })
end

exports('send', notify)
exports('info',    function(t, b, d) notify(t, b, 'info', d) end)
exports('success', function(t, b, d) notify(t, b, 'success', d) end)
exports('warn',    function(t, b, d) notify(t, b, 'warning', d) end)
exports('err',     function(t, b, d) notify(t, b, 'error', d) end)
exports('cash',    function(t, b, d) notify(t, b, 'cash', d) end)

RegisterNetEvent('notify_ezk:toast')
AddEventHandler('notify_ezk:toast', function(title, body, kind, duration)
    notify(title, body, kind, duration)
end)
