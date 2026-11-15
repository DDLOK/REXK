JOBS = {
    unemployed = { label = 'Unemployed',     salary = 0,   color = {150,150,150} },
    police     = { label = 'Police Officer', salary = 400, color = {80,150,255}  },
    criminal   = { label = 'Criminal',       salary = 0,   color = {255,80,80}   },
    taxi       = { label = 'Taxi Driver',    salary = 200, color = {255,200,80}  },
    trucker    = { label = 'Trucker',        salary = 250, color = {180,120,80}  },
    mechanic   = { label = 'Mechanic',       salary = 300, color = {255,150,80}  },
    ems        = { label = 'EMS Paramedic',  salary = 400, color = {255,120,120} },
}

local FILE = 'jobs.json'
local sessions = {} -- [src] = { job, onDuty }

local function load()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
    if not raw or raw == '' then return {} end
    local ok, d = pcall(json.decode, raw)
    return (ok and d) or {}
end
local function save(t) SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(t), -1) end

local function reply(src, color, author, msg)
    TriggerClientEvent('chat:addMessage', src, { color = color, args = { author, msg } })
end

local function userOf(src)
    local ok, u = pcall(function() return exports.account_ollie:getUsername(src) end)
    return ok and u or nil
end

local function getJob(src)
    if sessions[src] then return sessions[src].job, sessions[src].onDuty end
    local u = userOf(src); if not u then return 'unemployed', false end
    local t = load()
    local j = t[u] or 'unemployed'
    sessions[src] = { job = j, onDuty = false }
    return j, false
end

local function setJob(src, job)
    if not JOBS[job] then return false end
    local u = userOf(src); if not u then return false end
    sessions[src] = { job = job, onDuty = false }
    local t = load(); t[u] = job; save(t)
    TriggerClientEvent('jobs_ollie:sync', src, { job = job, onDuty = false, data = JOBS[job] })
    return true
end

local function toggleDuty(src)
    if not sessions[src] then getJob(src) end
    if sessions[src].job == 'unemployed' then return nil end
    sessions[src].onDuty = not sessions[src].onDuty
    TriggerClientEvent('jobs_ollie:sync', src, {
        job = sessions[src].job, onDuty = sessions[src].onDuty, data = JOBS[sessions[src].job]
    })
    return sessions[src].onDuty
end

exports('getJob',      function(src) local j,d = getJob(src); return j end)
exports('isOnDuty',    function(src) local j,d = getJob(src); return d end)
exports('setJob',      setJob)

RegisterNetEvent('jobs_ollie:apply')
AddEventHandler('jobs_ollie:apply', function(job)
    local src = source
    if not JOBS[job] then return end
    setJob(src, job)
    reply(src, {120,200,255}, 'JOBS', 'now employed as ' .. JOBS[job].label)
end)

RegisterNetEvent('jobs_ollie:request')
AddEventHandler('jobs_ollie:request', function()
    local src = source
    local j = getJob(src)
    TriggerClientEvent('jobs_ollie:sync', src, { job = j, onDuty = sessions[src].onDuty, data = JOBS[j] })
    TriggerClientEvent('jobs_ollie:catalog', src, JOBS)
end)

RegisterCommand('duty', function(src)
    local r = toggleDuty(src)
    if r == nil then
        reply(src, {255,80,80}, 'JOBS', 'get a job first (/job apply <name> or F1 phone)')
    else
        reply(src, {120,200,255}, 'JOBS', r and 'on duty' or 'off duty')
    end
end, false)

RegisterCommand('job', function(src, args)
    local sub = args[1]
    if sub == 'list' then
        reply(src, {120,200,255}, 'JOBS', 'available:')
        for id, data in pairs(JOBS) do
            reply(src, {200,200,200}, '  ' .. id, data.label .. ' - $' .. data.salary .. '/tick')
        end
    elseif sub == 'apply' and args[2] then
        if setJob(src, args[2]) then
            reply(src, {120,200,255}, 'JOBS', 'applied: ' .. JOBS[args[2]].label)
        else
            reply(src, {255,80,80}, 'JOBS', 'unknown job')
        end
    else
        local j = getJob(src)
        reply(src, {120,200,255}, 'JOBS', 'you are: ' .. JOBS[j].label .. (sessions[src].onDuty and ' [ON DUTY]' or ''))
    end
end, false)

-- salary tick (every 10 min)
CreateThread(function()
    while true do
        Wait(10 * 60 * 1000)
        for src, s in pairs(sessions) do
            if s.onDuty and JOBS[s.job] and JOBS[s.job].salary > 0 then
                exports.cash_ollie:addCash(tonumber(src), JOBS[s.job].salary)
                TriggerClientEvent('chat:addMessage', tonumber(src), {
                    color = {100,255,150}, args = { 'PAYDAY', ('+$%d from %s'):format(JOBS[s.job].salary, JOBS[s.job].label) }
                })
            end
        end
    end
end)

AddEventHandler('playerDropped', function() sessions[source] = nil end)

print('^2[jobs_ollie]^7 loaded - 7 jobs - salary tick 10min')
