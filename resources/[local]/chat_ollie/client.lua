-- =========================================================
-- chat_ollie / client.lua
-- fires welcome on first spawn, suggests commands in chat ui
-- =========================================================

local welcomed = false

AddEventHandler('playerSpawned', function()
    if welcomed then return end
    welcomed = true
    TriggerServerEvent('chat_ollie:welcome')
end)

-- chat:addSuggestion gives autocomplete hints under the T chatbox
Citizen.CreateThread(function()
    while GetResourceState('chat') ~= 'started' do Wait(100) end

    TriggerEvent('chat:addSuggestion', '/me',    'emote something',       {
        { name = 'action', help = 'what you do' }
    })
    TriggerEvent('chat:addSuggestion', '/ooc',   'out of character',      {
        { name = 'message', help = 'ooc text' }
    })
    TriggerEvent('chat:addSuggestion', '/pm',    'private message',       {
        { name = 'id',      help = 'server id' },
        { name = 'message', help = 'the message' }
    })
    TriggerEvent('chat:addSuggestion', '/clear', 'wipe chat (admin only)',{})
    TriggerEvent('chat:addSuggestion', '/help',  'list commands',         {})
end)
