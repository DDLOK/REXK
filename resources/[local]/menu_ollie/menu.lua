-- =========================================================
-- menu.lua - minimal native menu lib, no external deps
-- scrollable, nested, number-selector + action items
-- =========================================================

Menu = {}

local stack = {}       -- menu stack: { {items=…, index=1, title='…'}, … }
local open  = false
local lastInput = 0

local W, H   = 0.22, 0.045    -- panel width, row height (screen fraction)
local X, Y   = 0.02, 0.10     -- panel origin
local TITLE_H = 0.07
local VISIBLE = 10            -- max rows shown at once

local function col(r,g,b,a) return r/255, g/255, b/255, (a or 255)/255 end

local function drawRect(x, y, w, h, r, g, b, a)
    DrawRect(x + w/2, y + h/2, w, h, r, g, b, a)
end

local function drawText(txt, x, y, scale, r, g, b, a, font, center)
    SetTextFont(font or 4)
    SetTextScale(0.0, scale or 0.35)
    SetTextColour(r or 255, g or 255, b or 255, a or 255)
    SetTextDropshadow(2, 0, 0, 0, 180)
    SetTextOutline()
    if center then SetTextCentre(true) end
    SetTextEntry('STRING')
    AddTextComponentString(tostring(txt))
    DrawText(x, y)
end

function Menu.open(items, title)
    stack = {{ items = items, index = 1, title = title or 'MENU' }}
    open = true
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

function Menu.push(items, title)
    table.insert(stack, { items = items, index = 1, title = title })
    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

function Menu.pop()
    if #stack > 1 then
        table.remove(stack)
        PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    else
        Menu.close()
    end
end

function Menu.close()
    open = false
    stack = {}
    PlaySoundFrontend(-1, 'CANCEL', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

function Menu.isOpen() return open end

function Menu.refreshTop(items, title)
    if #stack == 0 then return end
    stack[#stack].items = items
    if title then stack[#stack].title = title end
    if stack[#stack].index > #items then stack[#stack].index = #items end
    if stack[#stack].index < 1 then stack[#stack].index = 1 end
end

local function controlJust(c)
    return IsControlJustReleased(0, c)
end

local function tick()
    if not open or #stack == 0 then return end
    local top = stack[#stack]
    local items = top.items

    -- block some game controls while open
    DisableControlAction(0, 1, true)   -- look lr
    DisableControlAction(0, 2, true)   -- look ud
    DisableControlAction(0, 142, true) -- attack2
    DisableControlAction(0, 18, true)  -- enter
    DisableControlAction(0, 322, true) -- esc (handled)
    DisableControlAction(0, 106, true) -- veh look
    HideHudComponentThisFrame(19)      -- weapon wheel

    -- input
    if GetGameTimer() - lastInput > 120 then
        if controlJust(172) or IsDisabledControlJustReleased(0, 172) then -- up
            top.index = top.index - 1
            if top.index < 1 then top.index = #items end
            PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            lastInput = GetGameTimer()
        elseif controlJust(173) or IsDisabledControlJustReleased(0, 173) then -- down
            top.index = top.index + 1
            if top.index > #items then top.index = 1 end
            PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            lastInput = GetGameTimer()
        elseif controlJust(174) or IsDisabledControlJustReleased(0, 174) then -- left
            local item = items[top.index]
            if item and item.values then
                item.cur = (item.cur or 1) - 1
                if item.cur < 1 then item.cur = #item.values end
                if item.onChange then item.onChange(item.values[item.cur], item.cur) end
                PlaySoundFrontend(-1, 'NAV_LEFT_RIGHT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
            lastInput = GetGameTimer()
        elseif controlJust(175) or IsDisabledControlJustReleased(0, 175) then -- right
            local item = items[top.index]
            if item and item.values then
                item.cur = (item.cur or 1) + 1
                if item.cur > #item.values then item.cur = 1 end
                if item.onChange then item.onChange(item.values[item.cur], item.cur) end
                PlaySoundFrontend(-1, 'NAV_LEFT_RIGHT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
            lastInput = GetGameTimer()
        elseif controlJust(201) or IsDisabledControlJustReleased(0, 201) then -- enter
            local item = items[top.index]
            if item and item.onSelect then
                item.onSelect()
                PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
            lastInput = GetGameTimer()
        elseif controlJust(202) or IsDisabledControlJustReleased(0, 202) then -- back
            Menu.pop()
            lastInput = GetGameTimer()
        end
    end

    -- draw panel
    local title = top.title or 'MENU'
    local n     = #items

    -- title bar
    drawRect(X, Y, W, TITLE_H, col(20, 20, 20, 230))
    drawRect(X, Y, W, 0.004,   col(255, 60, 160, 255))
    drawText(title, X + W/2, Y + 0.012, 0.6, 255, 255, 255, 255, 1, true)
    drawText(('%d / %d'):format(top.index, n), X + W/2, Y + 0.045, 0.3, 200, 200, 200, 255, 4, true)

    -- rows (windowed)
    local first = math.max(1, top.index - math.floor(VISIBLE/2))
    local last  = math.min(n, first + VISIBLE - 1)
    if last - first + 1 < VISIBLE then first = math.max(1, last - VISIBLE + 1) end

    local rowY = Y + TITLE_H
    for i = first, last do
        local item = items[i]
        local sel  = (i == top.index)
        local bgR, bgG, bgB, bgA = col(10, 10, 10, 200)
        if sel then bgR, bgG, bgB, bgA = col(255, 60, 160, 255) end
        drawRect(X, rowY, W, H, bgR, bgG, bgB, bgA)

        local txtR, txtG, txtB = 230, 230, 230
        if sel then txtR, txtG, txtB = 20, 20, 20 end

        drawText(item.label or '?', X + 0.008, rowY + 0.010, 0.33, txtR, txtG, txtB, 255, 4)

        if item.values then
            local cur = item.values[item.cur or 1] or ''
            drawText('< ' .. cur .. ' >', X + W - 0.008, rowY + 0.010, 0.33, txtR, txtG, txtB, 255, 4)
            -- right-align the right text
        elseif item.right then
            drawText(item.right, X + W - 0.008, rowY + 0.010, 0.33, txtR, txtG, txtB, 255, 4)
        elseif item.submenu then
            drawText('>', X + W - 0.012, rowY + 0.010, 0.4, txtR, txtG, txtB, 255, 4)
        end

        rowY = rowY + H + 0.001
    end

    -- footer hint
    drawRect(X, rowY, W, 0.028, col(0, 0, 0, 200))
    drawText('arrows move  -  enter select  -  back close', X + W/2, rowY + 0.004, 0.28, 200, 200, 200, 255, 4, true)
end

CreateThread(function()
    while true do
        Wait(0)
        tick()
    end
end)
