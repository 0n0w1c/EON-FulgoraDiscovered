local enemies = {}

enemies.data_stage = {
    vanilla_nauvis = {
        { type = "unit-spawner", name = "biter-spawner",        expression = "biter_spawner" },
        { type = "unit-spawner", name = "spitter-spawner",      expression = "spitter_spawner" },
        { type = "turret",       name = "small-worm-turret",    expression = "small_worm_turret" },
        { type = "turret",       name = "medium-worm-turret",   expression = "medium_worm_turret" },
        { type = "turret",       name = "big-worm-turret",      expression = "big_worm_turret" },
        { type = "turret",       name = "behemoth-worm-turret", expression = "behemoth_worm_turret" },
    },

    armoured_nauvis = {
        mod = "ArmouredBiters",
        entries = {
            { type = "unit-spawner", name = "armoured-biter-spawner", expression = "armoured_biter_spawner" },
        },
    },

    explosive_vulcanus = {
        mod = "Explosive_biters",
        autoplace_control = "hot_enemy_base",
        entries = {
            { type = "unit-spawner", name = "explosive-biter-spawner",         expression = "explosive_biter_spawner" },
            { type = "turret",       name = "small-explosive-worm-turret",     expression = "small_explosive_worm_turret" },
            { type = "turret",       name = "medium-explosive-worm-turret",    expression = "medium_explosive_worm_turret" },
            { type = "turret",       name = "big-explosive-worm-turret",       expression = "big_explosive_worm_turret" },
            { type = "turret",       name = "behemoth-explosive-worm-turret",  expression = "behemoth_explosive_worm_turret" },
            { type = "turret",       name = "leviathan-explosive-worm-turret", expression = "leviathan_explosive_worm_turret" },
            { type = "turret",       name = "mother-explosive-worm-turret",    expression = "mother_explosive_worm_turret" },
        },
    },

    cold_aquilo = {
        mod = "Cold_biters",
        autoplace_control = "frost_enemy_base",
        entries = {
            { type = "unit-spawner", name = "cb-cold-spawner",            expression = "eon_cb_cold_spawner" },
            { type = "turret",       name = "small-cold-worm-turret",     expression = "eon_small_cold_worm_turret" },
            { type = "turret",       name = "medium-cold-worm-turret",    expression = "eon_medium_cold_worm_turret" },
            { type = "turret",       name = "big-cold-worm-turret",       expression = "eon_big_cold_worm_turret" },
            { type = "turret",       name = "behemoth-cold-worm-turret",  expression = "eon_behemoth_cold_worm_turret" },
            { type = "turret",       name = "leviathan-cold-worm-turret", expression = "eon_leviathan_cold_worm_turret" },
            { type = "turret",       name = "mother-cold-worm-turret",    expression = "eon_mother_cold_worm_turret" },
        },
    },

    electric_fulgora = {
        mod = "Electric_flying_enemies",
        entries = {
            { type = "unit-spawner", name = "flying-electric-unit-spawner", expression = "eon_flying_electric_unit_spawner_off_aquilo" },
            { type = "unit-spawner", name = "walker-electric-unit-spawner", expression = "eon_walker_electric_unit_spawner_off_aquilo" },
        },
    },
}

enemies.final_fixes = {
    resistance_patch_types = { "unit-spawner", "turret", "unit" },
    base_autoplace_types = { "unit-spawner", "turret" },

    cold_biter_patterns = {
        ["unit-spawner"] = {
            exact = { "cb-cold-spawner" },
            contains = { "cold%-spawner", "frost%-spawner" },
        },
        turret = {
            contains = { "cold%-worm%-turret", "frost%-worm%-turret" },
        },
        unit = {
            contains = { "cold%-biter", "cold%-spitter", "frost%-biter", "frost%-spitter" },
        },
    },

    fulgoran_base_patterns = {
        ["unit-spawner"] = {
            exact = { "flying-electric-unit-spawner", "walker-electric-unit-spawner" },
            contains = { "electric%-unit%-spawner" },
        },
        turret = {
            contains = { "electric%-unit%-spawner" },
        },
    },
}

local function list_contains(list, name)
    for _, candidate in ipairs(list or {}) do
        if candidate == name then return true end
    end
    return false
end

local function matches_pattern_group(pattern_group, prototype_name)
    if type(prototype_name) ~= "string" or type(pattern_group) ~= "table" then return false end

    if list_contains(pattern_group.exact, prototype_name) then return true end

    for _, pattern in ipairs(pattern_group.contains or {}) do
        if string.find(prototype_name, pattern, 1, false) ~= nil then
            return true
        end
    end

    return false
end

function enemies.is_cold_biter_prototype(prototype_type, prototype_name)
    return matches_pattern_group(enemies.final_fixes.cold_biter_patterns[prototype_type], prototype_name)
end

function enemies.is_fulgoran_enemy_base_prototype(prototype_type, prototype_name)
    return matches_pattern_group(enemies.final_fixes.fulgoran_base_patterns[prototype_type], prototype_name)
end

enemies.runtime = {
    surface_names = {
        nauvis = { nauvis = true },
        nauvis_and_fulgora = { nauvis = true, fulgora = true },
    },

    expansion_scar_decoratives = {
        "enemy-decal",
        "enemy-decal-transparent",
        "worms-decal",
    },

    explosive_biter_existing_surface_autoplace_entities = {
        "explosive-biter-spawner",
        "small-explosive-worm-turret",
        "medium-explosive-worm-turret",
        "big-explosive-worm-turret",
        "behemoth-explosive-worm-turret",
        "leviathan-explosive-worm-turret",
        "mother-explosive-worm-turret",
    },
}

function enemies.surface_names_for_mode(aquilo_on_fulgora)
    return aquilo_on_fulgora
        and enemies.runtime.surface_names.nauvis_and_fulgora
        or enemies.runtime.surface_names.nauvis
end

enemies.base_variant_by_name = {
    ["biter-spawner"] = { tier = "spawner", family = "vanilla" },
    ["spitter-spawner"] = { tier = "spawner", family = "vanilla" },
    ["small-worm-turret"] = { tier = "small-worm", family = "vanilla" },
    ["medium-worm-turret"] = { tier = "medium-worm", family = "vanilla" },
    ["big-worm-turret"] = { tier = "big-worm", family = "vanilla" },
    ["behemoth-worm-turret"] = { tier = "behemoth-worm", family = "vanilla" },

    ["armoured-biter-spawner"] = { tier = "spawner", family = "armoured" },
    ["small-armoured-worm-turret"] = { tier = "small-worm", family = "armoured" },
    ["medium-armoured-worm-turret"] = { tier = "medium-worm", family = "armoured" },
    ["big-armoured-worm-turret"] = { tier = "big-worm", family = "armoured" },
    ["behemoth-armoured-worm-turret"] = { tier = "behemoth-worm", family = "armoured" },

    ["explosive-biter-spawner"] = { tier = "spawner", family = "hot" },
    ["small-explosive-worm-turret"] = { tier = "small-worm", family = "hot" },
    ["medium-explosive-worm-turret"] = { tier = "medium-worm", family = "hot" },
    ["big-explosive-worm-turret"] = { tier = "big-worm", family = "hot" },
    ["behemoth-explosive-worm-turret"] = { tier = "behemoth-worm", family = "hot" },
    ["leviathan-explosive-worm-turret"] = { tier = "behemoth-worm", family = "hot" },
    ["mother-explosive-worm-turret"] = { tier = "behemoth-worm", family = "hot" },

    ["cb-cold-spawner"] = { tier = "spawner", family = "cold" },
    ["small-cold-worm-turret"] = { tier = "small-worm", family = "cold" },
    ["medium-cold-worm-turret"] = { tier = "medium-worm", family = "cold" },
    ["big-cold-worm-turret"] = { tier = "big-worm", family = "cold" },
    ["behemoth-cold-worm-turret"] = { tier = "behemoth-worm", family = "cold" },
    ["leviathan-cold-worm-turret"] = { tier = "behemoth-worm", family = "cold" },
    ["mother-cold-worm-turret"] = { tier = "behemoth-worm", family = "cold" },

    ["gleba-spawner"] = { tier = "spawner", family = "gleba" },
    ["gleba-spawner-small"] = { tier = "spawner", family = "gleba" },

    ["flying-electric-unit-spawner"] = { tier = "spawner", family = "fulgora" },
    ["walker-electric-unit-spawner"] = { tier = "spawner", family = "fulgora" },
}

enemies.base_replacements = {
    vanilla = {
        ["spawner"] = { "biter-spawner", "spitter-spawner" },
        ["small-worm"] = { "small-worm-turret" },
        ["medium-worm"] = { "medium-worm-turret" },
        ["big-worm"] = { "big-worm-turret" },
        ["behemoth-worm"] = { "behemoth-worm-turret" },
    },
    armoured = {
        ["spawner"] = { "armoured-biter-spawner" },
        ["small-worm"] = { "small-armoured-worm-turret" },
        ["medium-worm"] = { "medium-armoured-worm-turret" },
        ["big-worm"] = { "big-armoured-worm-turret" },
        ["behemoth-worm"] = { "behemoth-armoured-worm-turret" },
    },
    hot = {
        ["spawner"] = { "explosive-biter-spawner" },
        ["small-worm"] = { "small-explosive-worm-turret" },
        ["medium-worm"] = { "medium-explosive-worm-turret" },
        ["big-worm"] = { "big-explosive-worm-turret" },
        ["behemoth-worm"] = {
            "behemoth-explosive-worm-turret",
            "leviathan-explosive-worm-turret",
            "mother-explosive-worm-turret"
        },
    },
    cold = {
        ["spawner"] = { "cb-cold-spawner" },
        ["small-worm"] = { "small-cold-worm-turret" },
        ["medium-worm"] = { "medium-cold-worm-turret" },
        ["big-worm"] = { "big-cold-worm-turret" },
        ["behemoth-worm"] = {
            "behemoth-cold-worm-turret",
            "leviathan-cold-worm-turret",
            "mother-cold-worm-turret"
        },
    },
    gleba = {
        ["spawner"] = { "gleba-spawner", "gleba-spawner-small" },
        ["small-worm"] = { "gleba-spawner-small", "gleba-spawner" },
        ["medium-worm"] = { "gleba-spawner", "gleba-spawner-small" },
        ["big-worm"] = { "gleba-spawner", "gleba-spawner-small" },
        ["behemoth-worm"] = { "gleba-spawner", "gleba-spawner-small" },
    },
    fulgora = {
        ["spawner"] = { "flying-electric-unit-spawner", "walker-electric-unit-spawner" },
        ["small-worm"] = { "flying-electric-unit-spawner", "walker-electric-unit-spawner" },
        ["medium-worm"] = { "walker-electric-unit-spawner", "flying-electric-unit-spawner" },
        ["big-worm"] = { "walker-electric-unit-spawner", "flying-electric-unit-spawner" },
        ["behemoth-worm"] = { "walker-electric-unit-spawner", "flying-electric-unit-spawner" },
    },
}

enemies.unit_replacements = {
    vanilla = {
        biter = {
            small = { "small-biter" },
            medium = { "medium-biter" },
            big = { "big-biter" },
            behemoth = { "behemoth-biter" },
            leviathan = { "behemoth-biter" },
            mother = { "behemoth-biter" },
        },
        spitter = {
            small = { "small-spitter" },
            medium = { "medium-spitter" },
            big = { "big-spitter" },
            behemoth = { "behemoth-spitter" },
            leviathan = { "behemoth-spitter" },
            mother = { "behemoth-spitter" },
        },
    },
    armoured = {
        biter = {
            small = { "small-armoured-biter" },
            medium = { "medium-armoured-biter" },
            big = { "big-armoured-biter" },
            behemoth = { "behemoth-armoured-biter" },
            leviathan = { "leviathan-armoured-biter", "behemoth-armoured-biter" },
            mother = { "leviathan-armoured-biter", "behemoth-armoured-biter" },
        },
        spitter = {
            small = { "small-armoured-biter" },
            medium = { "medium-armoured-biter" },
            big = { "big-armoured-biter" },
            behemoth = { "behemoth-armoured-biter" },
            leviathan = { "leviathan-armoured-biter", "behemoth-armoured-biter" },
            mother = { "leviathan-armoured-biter", "behemoth-armoured-biter" },
        },
    },
    hot = {
        biter = {
            small = { "small-explosive-biter" },
            medium = { "medium-explosive-biter" },
            big = { "big-explosive-biter" },
            behemoth = { "behemoth-explosive-biter" },
            leviathan = { "explosive-leviathan-biter", "behemoth-explosive-biter" },
            mother = { "explosive-leviathan-biter", "behemoth-explosive-biter" },
        },
        spitter = {
            small = { "small-explosive-spitter" },
            medium = { "medium-explosive-spitter" },
            big = { "big-explosive-spitter" },
            behemoth = { "behemoth-explosive-spitter" },
            leviathan = { "leviathan-explosive-spitter", "behemoth-explosive-spitter" },
            mother = { "mother-explosive-spitter", "leviathan-explosive-spitter", "behemoth-explosive-spitter" },
        },
    },
    cold = {
        biter = {
            small = { "small-cold-biter" },
            medium = { "medium-cold-biter" },
            big = { "big-cold-biter" },
            behemoth = { "behemoth-cold-biter" },
            leviathan = { "leviathan-cold-biter", "behemoth-cold-biter" },
            mother = { "leviathan-cold-biter", "behemoth-cold-biter" },
        },
        spitter = {
            small = { "small-cold-spitter" },
            medium = { "medium-cold-spitter" },
            big = { "big-cold-spitter" },
            behemoth = { "behemoth-cold-spitter" },
            leviathan = { "leviathan-cold-spitter", "behemoth-cold-spitter" },
            mother = { "mother-cold-spitter", "leviathan-cold-spitter", "behemoth-cold-spitter" },
        },
    },
    gleba = {
        biter = {
            small = { "small-wriggler-pentapod" },
            medium = { "medium-wriggler-pentapod", "small-wriggler-pentapod" },
            big = { "big-wriggler-pentapod", "medium-wriggler-pentapod" },
            behemoth = { "big-wriggler-pentapod" },
            leviathan = { "big-wriggler-pentapod" },
            mother = { "big-wriggler-pentapod" },
        },
        spitter = {
            small = { "small-wriggler-pentapod" },
            medium = { "medium-wriggler-pentapod", "small-wriggler-pentapod" },
            big = { "big-wriggler-pentapod", "medium-wriggler-pentapod" },
            behemoth = { "big-wriggler-pentapod" },
            leviathan = { "big-wriggler-pentapod" },
            mother = { "big-wriggler-pentapod" },
        },
    },
    fulgora = {
        biter = {
            small = { "walking-electric-unit-1", "flying-electric-unit-1" },
            medium = { "walking-electric-unit-2", "flying-electric-unit-2" },
            big = { "walking-electric-unit-3", "flying-electric-unit-3" },
            behemoth = { "walking-electric-unit-4", "flying-electric-unit-4" },
            leviathan = { "walking-electric-unit-5", "flying-electric-unit-5" },
            mother = { "walking-electric-unit-5", "flying-electric-unit-5" },
        },
        spitter = {
            small = { "flying-electric-unit-1", "walking-electric-unit-1" },
            medium = { "flying-electric-unit-2", "walking-electric-unit-2" },
            big = { "flying-electric-unit-3", "walking-electric-unit-3" },
            behemoth = { "flying-electric-unit-4", "walking-electric-unit-4" },
            leviathan = { "flying-electric-unit-5", "walking-electric-unit-5" },
            mother = { "flying-electric-unit-5", "walking-electric-unit-5" },
        },
    },
}

return enemies
