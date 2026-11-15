-- =========================================================
-- char_ollie / client.lua - selector + applier
-- =========================================================

local selectorOpen = false
local activeCharIdx = nil

local function applyCharToPed(char)
    local ped = PlayerPedId()
    if char.model then
        local m = joaat(char.model)
        if IsModelInCdimage(m) and IsModelValid(m) then
            RequestModel(m)
            local t = GetGameTimer()
            while not HasModelLoaded(m) do Wait(0); if GetGameTimer() - t > 3000 then break end end
            SetPlayerModel(PlayerId(), m)
            SetModelAsNoLongerNeeded(m)
            Wait(100)
            ped = PlayerPedId()
            SetPedDefaultComponentVariation(ped)
        end
    end
    if char.components then
        for compStr, v in pairs(char.components) do
            local comp = tonumber(compStr)
            local draw = tonumber(v[1]) or 0
            local tex  = tonumber(v[2]) or 0
            if comp then SetPedComponentVariation(ped, comp, draw, tex, 0) end
        end
    end
    if char.props then
        for propStr, v in pairs(char.props) do
            local prop = tonumber(propStr)
            local draw = tonumber(v[1])
            local tex  = tonumber(v[2]) or 0
            if prop then
                if draw and draw >= 0 then SetPedPropIndex(ped, prop, draw, tex, true)
                else ClearPedProp(ped, prop) end
            end
        end
    end
end

local function openSelector()
    if selectorOpen then return end
    selectorOpen = true
    TriggerServerEvent('char_ollie:request')
    SendNUIMessage({ action = 'openChar' })
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
end

local function closeSelector()
    selectorOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeChar' })
end

AddEventHandler('char_ollie:openSelector', openSelector)

RegisterNetEvent('char_ollie:list')
AddEventHandler('char_ollie:list', function(data)
    SendNUIMessage({ action = 'charList', data = data })
end)

RegisterNetEvent('char_ollie:applied')
AddEventHandler('char_ollie:applied', function(char)
    activeCharIdx = char._idx
    closeSelector()
    applyCharToPed(char)
    -- release player + send home
    TriggerEvent('account_ollie:cameraStop')
    Wait(300)
    TriggerServerEvent('house_ollie:goHome')
end)

RegisterNUICallback('selectChar', function(d, cb)
    TriggerServerEvent('char_ollie:selectChar', tonumber(d.idx))
    cb({ ok = true })
end)

RegisterNUICallback('createChar', function(d, cb)
    local char = {
        name = d.name or 'Unnamed',
        model = d.gender == 'female' and 'mp_f_freemode_01' or 'mp_m_freemode_01',
        components = {},
        props = {},
    }
    TriggerServerEvent('char_ollie:saveChar', tonumber(d.idx), char)
    cb({ ok = true })
end)

RegisterNUICallback('deleteChar', function(d, cb)
    TriggerServerEvent('char_ollie:deleteChar', tonumber(d.idx))
    cb({ ok = true })
end)

RegisterNUICallback('closeChar', function(_, cb)
    cb({ ok = true })
end)

-- /chars to reopen selector any time
RegisterCommand('chars', openSelector, false)
CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/chars', 'open character selector', {})
end)
