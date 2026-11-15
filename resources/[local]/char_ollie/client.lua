-- =========================================================
-- char_ollie / client.lua - selector + applier + wardrobe editor
-- =========================================================

local selectorOpen = false
local wardrobeOpen = false
local editingIdx = nil
local editingChar = nil
local editorCam = nil
local camHeading = 0.0
local camZoom = 2.0

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
        for k, v in pairs(char.components) do
            local comp = tonumber(k)
            local draw = tonumber(v[1]) or 0
            local tex  = tonumber(v[2]) or 0
            if comp then SetPedComponentVariation(ped, comp, draw, tex, 0) end
        end
    end
    if char.props then
        for k, v in pairs(char.props) do
            local prop = tonumber(k)
            local draw = tonumber(v[1])
            local tex  = tonumber(v[2]) or 0
            if prop then
                if draw and draw >= 0 then SetPedPropIndex(ped, prop, draw, tex, true)
                else ClearPedProp(ped, prop) end
            end
        end
    end
    if char.colors then
        local c = char.colors
        if c.hair1 or c.hair2 then SetPedHairColor(ped, c.hair1 or 0, c.hair2 or 0) end
        if c.eye   then SetPedEyeColor(ped, c.eye) end
        if c.beard or c.hair1 then SetPedHeadOverlayColor(ped, 1, 1, c.beard or c.hair1 or 0, c.hair2 or c.beard or c.hair1 or 0) end
        if c.brow  then SetPedHeadOverlayColor(ped, 2, 1, c.brow, c.hair2 or c.brow) end
    end
end

local function openSelector()
    if wardrobeOpen then return end
    if selectorOpen then return end
    selectorOpen = true
    TriggerServerEvent('char_ollie:request')
    SendNUIMessage({ action = 'openChar' })
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
end

local function closeSelector()
    selectorOpen = false
    if not wardrobeOpen then SetNuiFocus(false, false) end
    SendNUIMessage({ action = 'closeChar' })
end

AddEventHandler('char_ollie:openSelector', openSelector)

-- K key opens selector any time (both logged in and not)
RegisterCommand('skins', openSelector, false)
RegisterCommand('chars', openSelector, false)
RegisterKeyMapping('skins', 'Open Character / Wardrobe', 'keyboard', 'K')

-- ============== WARDROBE EDITOR ==============
local function startEditorCam()
    local p = PlayerPedId()
    local pc = GetEntityCoords(p)
    editorCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(editorCam, pc.x + 2.0, pc.y, pc.z + 0.5)
    PointCamAtEntity(editorCam, p, 0.0, 0.0, 0.5, true)
    SetCamActive(editorCam, true)
    RenderScriptCams(true, false, 0, true, true)
    camHeading = GetEntityHeading(p) + 180.0
    camZoom = 2.0
end

local function updateEditorCam()
    if not editorCam or not DoesCamExist(editorCam) then return end
    local p = PlayerPedId()
    local pc = GetEntityCoords(p)
    local rad = math.rad(camHeading)
    local x = pc.x + math.cos(rad) * camZoom
    local y = pc.y + math.sin(rad) * camZoom
    SetCamCoord(editorCam, x, y, pc.z + 0.3)
    PointCamAtEntity(editorCam, p, 0.0, 0.0, 0.3, true)
end

local function stopEditorCam()
    RenderScriptCams(false, false, 0, true, true)
    if editorCam and DoesCamExist(editorCam) then DestroyCam(editorCam, true); editorCam = nil end
end

local function openWardrobe(idx, char)
    editingIdx = idx
    editingChar = char or { name = 'New Character', model = 'mp_m_freemode_01', components = {}, props = {} }
    -- apply current look so editor starts from saved state
    applyCharToPed(editingChar)
    wardrobeOpen = true
    SendNUIMessage({
        action = 'openWardrobe',
        name = editingChar.name,
        comps = editingChar.components or {},
        props = editingChar.props or {},
    })
    SetNuiFocus(true, true)
    SetCursorLocation(0.3, 0.5)
    startEditorCam()
end

local function closeWardrobe(save)
    SendNUIMessage({ action = 'closeWardrobe' })
    wardrobeOpen = false
    if not selectorOpen then SetNuiFocus(false, false) end
    stopEditorCam()
    editingChar = nil
end

-- camera deltas driven by NUI mouse (see wardrobe.js)
RegisterNUICallback('camDelta', function(d, cb)
    local dx = tonumber(d.dx) or 0
    camHeading = camHeading + (dx * 0.5)
    cb({ ok = true })
end)

RegisterNUICallback('camZoom', function(d, cb)
    local dy = tonumber(d.dy) or 0
    camZoom = math.max(1.0, math.min(5.0, camZoom + (dy * 0.003)))
    cb({ ok = true })
end)

-- editor camera update thread
CreateThread(function()
    while true do
        if wardrobeOpen and editorCam then
            updateEditorCam()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- NUI callbacks
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
    -- immediately enter wardrobe editor for the new char
    closeSelector()
    Wait(100)
    openWardrobe(tonumber(d.idx), char)
    cb({ ok = true })
end)

RegisterNUICallback('editChar', function(d, cb)
    local idx = tonumber(d.idx)
    -- editing existing — reuse data sent from selector
    closeSelector()
    Wait(100)
    openWardrobe(idx, d.char)
    cb({ ok = true })
end)

RegisterNUICallback('deleteChar', function(d, cb)
    TriggerServerEvent('char_ollie:deleteChar', tonumber(d.idx))
    cb({ ok = true })
end)

RegisterNUICallback('closeChar', function(_, cb) cb({ ok = true }) end)

-- wardrobe callbacks
RegisterNUICallback('liveChange', function(d, cb)
    local ped = PlayerPedId()
    local draw = tonumber(d.drawable) or 0
    local tex  = tonumber(d.texture) or 0
    if d.kind == 'comp' then
        local comp = tonumber(d.component)
        if comp then
            SetPedComponentVariation(ped, comp, draw, tex, 0)
            editingChar.components = editingChar.components or {}
            editingChar.components[tostring(comp)] = { draw, tex }
        end
    elseif d.kind == 'prop' then
        local comp = tonumber(d.component)
        if comp then
            if draw >= 0 then SetPedPropIndex(ped, comp, draw, tex, true)
            else ClearPedProp(ped, comp) end
            editingChar.props = editingChar.props or {}
            editingChar.props[tostring(comp)] = { draw, tex }
        end
    elseif d.kind == 'color' then
        editingChar.colors = editingChar.colors or {}
        editingChar.colors[tostring(d.component)] = draw
        local c = editingChar.colors
        if d.component == 'hair1' or d.component == 'hair2' then SetPedHairColor(ped, c.hair1 or 0, c.hair2 or 0) end
        if d.component == 'eye'   then SetPedEyeColor(ped, draw) end
        if d.component == 'beard' then SetPedHeadOverlayColor(ped, 1, 1, draw, draw) end
        if d.component == 'brow'  then SetPedHeadOverlayColor(ped, 2, 1, draw, draw) end
    end
    cb({ ok = true })
end)

RegisterNUICallback('wardrobeBack', function(_, cb)
    closeWardrobe(false)
    Wait(100)
    openSelector()
    cb({ ok = true })
end)

RegisterNUICallback('wardrobeReset', function(_, cb)
    editingChar.components = {}
    editingChar.props = {}
    SetPedDefaultComponentVariation(PlayerPedId())
    cb({ ok = true })
end)

RegisterNUICallback('wardrobeSave', function(d, cb)
    editingChar.components = d.comps or {}
    editingChar.props      = d.props  or {}
    editingChar.colors     = d.colors or {}
    TriggerServerEvent('char_ollie:saveChar', editingIdx, editingChar)
    closeWardrobe(true)
    pcall(function() exports.notify_ezk:success('SAVED', 'character ' .. editingChar.name .. ' saved') end)
    cb({ ok = true })
end)

RegisterNetEvent('char_ollie:list')
AddEventHandler('char_ollie:list', function(data)
    SendNUIMessage({ action = 'charList', data = data })
end)

RegisterNetEvent('char_ollie:applied')
AddEventHandler('char_ollie:applied', function(char)
    closeSelector()
    applyCharToPed(char)
    TriggerEvent('account_ollie:cameraStop')
    Wait(300)
    TriggerServerEvent('house_ollie:goHome')
end)

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/skins', 'open character / wardrobe (K)', {})
    TriggerEvent('chat:addSuggestion', '/chars', 'open character selector', {})
end)
