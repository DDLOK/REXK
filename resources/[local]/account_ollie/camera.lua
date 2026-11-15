-- =========================================================
-- account_ollie / camera.lua
-- cinematic camera during login (player watches the city, not sky)
-- =========================================================

local LOGIN_CAMS = {
    { pos = vector3( 1250.0,  -395.0,  93.0),  look = vector3(0.0, 0.0, 0.0) },   -- maze bank over DT
    { pos = vector3( -806.0,  -2200.0, 120.0), look = vector3(0.0, 0.0, 0.0) },   -- over LSIA toward city
    { pos = vector3(  770.0,   1800.0, 450.0), look = vector3(0.0, 0.0, 0.0) },   -- high over vinewood hills
    { pos = vector3( -420.0,   6200.0, 95.0),  look = vector3(0.0, 0.0, 0.0) },   -- paleto bay
    { pos = vector3(  450.0,   5600.0, 850.0), look = vector3(0.0, 0.0, 0.0) },   -- chiliad top
    { pos = vector3(-1600.0,  -1050.0, 60.0),  look = vector3(0.0, 0.0, 0.0) },   -- vespucci beach
}

local cam
local camActive = false

local function makeCam(point)
    if cam and DoesCamExist(cam) then DestroyCam(cam, true) end
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, point.pos.x, point.pos.y, point.pos.z)
    PointCamAtCoord(cam, point.pos.x + math.random(-300, 300) + 0.0, point.pos.y + math.random(-300, 300) + 0.0, 20.0)
    SetCamFov(cam, 60.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
end

local function slowSpin(point)
    if cam and DoesCamExist(cam) then
        local t = GetGameTimer() / 1000.0
        local rot = t * 2.5
        local lx = point.pos.x + math.cos(math.rad(rot)) * 100.0
        local ly = point.pos.y + math.sin(math.rad(rot)) * 100.0
        PointCamAtCoord(cam, lx, ly, 20.0)
    end
end

local function startLoginCam()
    if camActive then return end
    camActive = true
    CreateThread(function()
        local idx = 1
        local started = GetGameTimer()
        makeCam(LOGIN_CAMS[idx])
        while camActive and not LoggedIn do
            Wait(0)
            slowSpin(LOGIN_CAMS[idx])
            if GetGameTimer() - started > 8000 then
                idx = (idx % #LOGIN_CAMS) + 1
                DoScreenFadeOut(500); Wait(520)
                makeCam(LOGIN_CAMS[idx])
                DoScreenFadeIn(500)
                started = GetGameTimer()
            end
        end
        -- release
        RenderScriptCams(false, false, 0, true, true)
        if cam and DoesCamExist(cam) then DestroyCam(cam, true); cam = nil end
    end)
end

local function stopLoginCam()
    camActive = false
end

-- hooks: start when NUI opens, stop when logged in
AddEventHandler('account_ollie:cameraStart', startLoginCam)
AddEventHandler('account_ollie:cameraStop', stopLoginCam)
