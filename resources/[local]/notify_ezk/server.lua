-- server-side export to trigger a notify on a specific client
exports('send', function(src, title, body, kind, duration)
    TriggerClientEvent('notify_ezk:toast', src, title, body, kind, duration)
end)
