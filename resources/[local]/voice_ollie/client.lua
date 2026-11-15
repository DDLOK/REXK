-- =========================================================
-- voice_ollie - mumble proximity voice, cycled by /voice
-- =========================================================

local MODES = {
    { name = 'WHISPER', dist = 2.0,  color = {100, 180, 255} },
    { name = 'TALK',    dist = 8.0,  color = {120, 255, 150} },
    { name = 'SHOUT',   dist = 18.0, color = {255, 180, 80 } },
}
local idx = 2

local function apply()
    local m = MODES[idx]
    MumbleSetAudioInputDistance(m.dist + 0.0)
    MumbleSetAudioOutputDistance(m.dist + 0.0)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(('~b~voice: ~w~%s (%.0fm)'):format(m.name, m.dist))
    DrawNotification(false, true)
end

CreateThread(function()
    NetworkSetVoiceChannel(0)
    NetworkSetTalkerProximity(8.0)
    MumbleSetVoiceChannel(1)
    MumbleSetAudioInputDistance(8.0)
    MumbleSetAudioOutputDistance(8.0)
end)

RegisterCommand('voice', function()
    idx = (idx % #MODES) + 1
    apply()
end, false)
RegisterKeyMapping('voice', 'Voice: whisper / talk / shout', 'keyboard', 'z')

-- HUD indicator
local lastTalk = 0
CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsPlayerTalking(PlayerId()) then
            lastTalk = GetGameTimer()
        end
        local active = (GetGameTimer() - lastTalk < 150)
        local m = MODES[idx]
        SetTextFont(4)
        SetTextScale(0.0, 0.32)
        SetTextColour(m.color[1], m.color[2], m.color[3], active and 255 or 120)
        SetTextOutline()
        SetTextDropshadow(2, 0, 0, 0, 180)
        SetTextEntry('STRING')
        AddTextComponentString(('[Z] %s%s'):format(m.name, active and '  ●' or ''))
        DrawText(0.01, 0.945)
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/voice', 'cycle voice range: whisper / talk / shout (Z)', {})
end)
