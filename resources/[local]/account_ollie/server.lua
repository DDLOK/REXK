-- =========================================================
-- account_ollie / server.lua
-- /register <user> <pass>  /login <user> <pass>  /logout
-- auto-login if identifier matches last session
-- =========================================================

local FILE  = 'accounts.json'
local sessions = {} -- [src] = { username, admin }

local function load()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
    if not raw or raw == '' then return {} end
    local ok, d = pcall(json.decode, raw)
    return (ok and d) or {}
end
local function save(t)
    SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(t), -1)
end

-- seed admins
local accounts = load()
for _, a in ipairs(SEEDED_ADMINS) do
    if not accounts[a.username] then
        accounts[a.username] = { password = a.password, admin = true, ids = {} }
    else
        accounts[a.username].admin = true
    end
end
save(accounts)

local function reply(src, color, author, msg)
    TriggerClientEvent('chat:addMessage', src, { color = color, args = { author, msg } })
end

local function pickId(src)
    for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
        if id:find('^license:') then return id end
    end
    return (GetPlayerIdentifiers(src) or {})[1]
end

local function pushState(src)
    local s = sessions[src] or {}
    TriggerClientEvent('account_ollie:state', src, {
        logged = s.username ~= nil,
        username = s.username,
        admin = s.admin or false,
    })
end

local function tryAutoLogin(src)
    local id = pickId(src)
    if not id then return false end
    accounts = load()
    for user, data in pairs(accounts) do
        if data.ids then
            for _, oldId in ipairs(data.ids) do
                if oldId == id then
                    sessions[src] = { username = user, admin = data.admin == true }
                    reply(src, {120,220,255}, 'ACCOUNT', 'welcome back, ' .. user)
                    pushState(src)
                    return true
                end
            end
        end
    end
    return false
end

AddEventHandler('playerJoining', function()
    local src = source
    Wait(500)
    if not tryAutoLogin(src) then
        reply(src, {255,200,100}, 'ACCOUNT', 'no session - use /login <user> <pass> or /register <user> <pass>')
    end
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)

RegisterNetEvent('account_ollie:requestState')
AddEventHandler('account_ollie:requestState', function()
    pushState(source)
end)

RegisterCommand('register', function(src, args)
    if src == 0 then return end
    local user = args[1]
    local pass = args[2]
    if not user or not pass then
        reply(src, {255,80,80}, 'ACCOUNT', 'usage: /register <username> <password>')
        return
    end
    accounts = load()
    if accounts[user] then
        reply(src, {255,80,80}, 'ACCOUNT', 'username taken')
        return
    end
    accounts[user] = { password = pass, admin = false, ids = { pickId(src) } }
    save(accounts)
    sessions[src] = { username = user, admin = false }
    reply(src, {120,255,120}, 'ACCOUNT', 'registered + logged in as ' .. user)
    pushState(src)
end, false)

RegisterCommand('login', function(src, args)
    if src == 0 then return end
    local user = args[1]
    local pass = args[2]
    if not user or not pass then
        reply(src, {255,80,80}, 'ACCOUNT', 'usage: /login <username> <password>')
        return
    end
    accounts = load()
    local a = accounts[user]
    if not a or a.password ~= pass then
        reply(src, {255,80,80}, 'ACCOUNT', 'wrong credentials')
        return
    end
    a.ids = a.ids or {}
    local id = pickId(src)
    local has = false
    for _, v in ipairs(a.ids) do if v == id then has = true break end end
    if not has and id then table.insert(a.ids, id) end
    save(accounts)
    sessions[src] = { username = user, admin = a.admin == true }
    reply(src, {120,255,120}, 'ACCOUNT', 'logged in as ' .. user .. (a.admin and ' [ADMIN]' or ''))
    pushState(src)
end, false)

RegisterCommand('logout', function(src)
    sessions[src] = nil
    reply(src, {200,200,200}, 'ACCOUNT', 'logged out')
    pushState(src)
end, false)

RegisterCommand('me-account', function(src)
    local s = sessions[src]
    if not s then reply(src, {255,80,80}, 'ACCOUNT', 'not logged in') return end
    reply(src, {120,220,255}, 'ACCOUNT', ('%s%s'):format(s.username, s.admin and ' [ADMIN]' or ''))
end, false)

-- EXPORTS
exports('isLoggedIn', function(src) return sessions[src] ~= nil end)
exports('isAdmin',    function(src) return sessions[src] and sessions[src].admin == true end)
exports('getUsername', function(src) return sessions[src] and sessions[src].username or nil end)

print('^2[account_ollie]^7 loaded - seeded admins: reno, kane Ghost')
