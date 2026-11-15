-- =========================================================
-- house_ollie / interiors.lua
-- MP apartment interiors (built into GTA V, no custom assets)
-- Each house index maps to an interior + entrance door
-- =========================================================

-- MP apartment interior spawn points (safe, built-in GTA Online interiors)
-- Reference: GTA Online MP apartments load via `apartment1_int`, `apa_v_mp_h_01_a` etc.
INTERIORS = {
    -- Modern 1 (bright/open)
    { name = 'Modern Apt 1',  ipl = 'apa_v_mp_h_01_a', coords = vector3(-786.8663,  315.7642, 217.6385), heading = 180.0 },
    -- Modern 2
    { name = 'Modern Apt 2',  ipl = 'apa_v_mp_h_01_b', coords = vector3(-774.0126,  341.8309, 211.3971), heading = 180.0 },
    -- Modern 3 (vinewood hills)
    { name = 'Modern Apt 3',  ipl = 'apa_v_mp_h_01_c', coords = vector3(-764.1642,  322.3509, 217.6384), heading = 180.0 },
    -- Mody (purple)
    { name = 'Mody Apt',      ipl = 'apa_v_mp_h_02_a', coords = vector3(-787.0749,  331.1221, 217.6385), heading = 180.0 },
    -- Mody 2
    { name = 'Mody Apt 2',    ipl = 'apa_v_mp_h_02_b', coords = vector3(-774.0126,  341.8309, 211.3971), heading = 180.0 },
    -- Mody 3
    { name = 'Mody Apt 3',    ipl = 'apa_v_mp_h_02_c', coords = vector3(-764.1642,  322.3509, 217.6384), heading = 180.0 },
    -- Vibrant
    { name = 'Vibrant Apt',   ipl = 'apa_v_mp_h_03_a', coords = vector3(-787.0749,  331.1221, 217.6385), heading = 180.0 },
    -- Sharp
    { name = 'Sharp Apt',     ipl = 'apa_v_mp_h_04_a', coords = vector3(-787.0749,  331.1221, 217.6385), heading = 180.0 },
    -- Monochrome
    { name = 'Mono Apt',      ipl = 'apa_v_mp_h_05_a', coords = vector3(-787.0749,  331.1221, 217.6385), heading = 180.0 },
    -- Seductive (rich finish)
    { name = 'Seductive Apt', ipl = 'apa_v_mp_h_06_a', coords = vector3(-787.0749,  331.1221, 217.6385), heading = 180.0 },
}

-- NOTE: real MP apartments share a stilt interior pool. For simplicity we use the first
-- interior coords for all; GTA maintains separate interior instances per IPL load.
