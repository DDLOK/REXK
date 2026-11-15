-- =========================================================
-- data.lua - lookup tables for the menu
-- =========================================================

Data = {}

Data.teleports = {
    { name = 'Airport (LSX)',       coords = vector3(-1037.0,  -2737.7,  20.2) },
    { name = 'Mount Chiliad',       coords = vector3( 450.0,    5566.0, 781.1) },
    { name = 'Fort Zancudo',        coords = vector3(-2360.0,   3249.0,  32.8) },
    { name = 'Vinewood Sign',       coords = vector3( 711.4,    1200.7, 325.1) },
    { name = 'Maze Bank Rooftop',   coords = vector3(-75.0,    -818.6,  326.2) },
    { name = 'Casino',              coords = vector3( 925.0,   46.0,     81.1) },
    { name = 'Vespucci Beach',      coords = vector3(-1223.0, -1491.0,   4.3) },
    { name = 'LSPD Mission Row',    coords = vector3( 428.5,  -981.1,   30.7) },
    { name = 'Pillbox Hospital',    coords = vector3( 307.7,  -599.6,   43.3) },
    { name = 'Michael\'s House',    coords = vector3(-852.4,  160.0,    65.5) },
    { name = 'Franklin\'s House',   coords = vector3(  7.9,   548.0,   175.4) },
    { name = 'Trevor\'s Trailer',   coords = vector3( 1972.0, 3817.0,   33.4) },
    { name = 'LS Customs',          coords = vector3(-337.5, -136.3,   39.0) },
    { name = 'Ammunation Downtown', coords = vector3( 21.6,  -1106.7,  29.8) },
    { name = 'Sandy Shores',        coords = vector3( 1960.0, 3740.0,   32.3) },
    { name = 'Paleto Bay',          coords = vector3(-275.0,  6635.0,   7.4) },
}

Data.vehicles = {
    ['Super'] = {
        'adder', 'zentorno', 't20', 'osiris', 'reaper', 'nero', 'vagner',
        'xa21', 'tempesta', 'autarch', 'krieger', 'emerus', 'deveste',
    },
    ['Sports'] = {
        'elegy2', 'sultan', 'kuruma', 'jester', 'massacro', 'alpha',
        'comet2', 'feltzer2', 'carbonizzare', 'rapidgt', 'furoregt',
    },
    ['Sedans'] = {
        'sentinel', 'tailgater', 'fugitive', 'oracle2', 'cognoscenti',
        'warrener', 'premier', 'washington',
    },
    ['Off-road'] = {
        'kalahari', 'bodhi2', 'rebel', 'sandking', 'dubsta3',
        'trophytruck', 'brawler', 'everon', 'riata',
    },
    ['Military'] = {
        'rhino', 'khanjali', 'insurgent3', 'nightshark', 'apc',
        'halftrack', 'barrage', 'crusader', 'thruster',
    },
    ['Aircraft'] = {
        'lazer', 'hydra', 'savage', 'buzzard', 'besra',
        'cargobob', 'maverick', 'swift', 'volatus', 'akula',
    },
    ['Boats'] = {
        'dinghy', 'jetmax', 'marquis', 'seashark', 'speeder',
        'submersible', 'tropic', 'squalo',
    },
    ['Motorcycles'] = {
        'akuma', 'bati', 'carbonrs', 'hakuchou', 'shotaro',
        'vortex', 'defiler', 'faggio2', 'bf400',
    },
}

Data.weapons = {
    ['Melee']   = { 'WEAPON_KNIFE','WEAPON_BAT','WEAPON_CROWBAR','WEAPON_HAMMER','WEAPON_MACHETE','WEAPON_SWITCHBLADE' },
    ['Pistol']  = { 'WEAPON_PISTOL','WEAPON_COMBATPISTOL','WEAPON_APPISTOL','WEAPON_PISTOL50','WEAPON_HEAVYPISTOL','WEAPON_MARKSMANPISTOL','WEAPON_REVOLVER' },
    ['SMG']     = { 'WEAPON_MICROSMG','WEAPON_SMG','WEAPON_ASSAULTSMG','WEAPON_COMBATPDW','WEAPON_MACHINEPISTOL','WEAPON_MINISMG' },
    ['Shotgun'] = { 'WEAPON_PUMPSHOTGUN','WEAPON_SAWNOFFSHOTGUN','WEAPON_ASSAULTSHOTGUN','WEAPON_BULLPUPSHOTGUN','WEAPON_HEAVYSHOTGUN','WEAPON_DBSHOTGUN' },
    ['Rifle']   = { 'WEAPON_ASSAULTRIFLE','WEAPON_CARBINERIFLE','WEAPON_ADVANCEDRIFLE','WEAPON_SPECIALCARBINE','WEAPON_BULLPUPRIFLE','WEAPON_COMPACTRIFLE','WEAPON_MILITARYRIFLE' },
    ['Sniper']  = { 'WEAPON_SNIPERRIFLE','WEAPON_HEAVYSNIPER','WEAPON_MARKSMANRIFLE' },
    ['Heavy']   = { 'WEAPON_RPG','WEAPON_GRENADELAUNCHER','WEAPON_MINIGUN','WEAPON_FIREWORK','WEAPON_RAILGUN','WEAPON_HOMINGLAUNCHER' },
    ['Throw']   = { 'WEAPON_GRENADE','WEAPON_STICKYBOMB','WEAPON_MOLOTOV','WEAPON_SMOKEGRENADE','WEAPON_PROXMINE','WEAPON_BZGAS' },
}

Data.weathers = {
    'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'SMOG', 'FOGGY',
    'OVERCAST', 'RAIN', 'THUNDER', 'CLEARING', 'NEUTRAL',
    'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'HALLOWEEN',
}
