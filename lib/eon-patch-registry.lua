local registry = {}

registry.nuke = {
    biome_effect_id = "eon-atomic-rocket-biome-effect",
    crater_effect_id = "eon-atomic-rocket-nauvis-crater-effect",

    cloned_effect_entities = {
        ["eon-nuke-effects-fulgora"] = true,
        ["eon-nuke-effects-vulcanus-swapped"] = true,
    },

    effect_clones = {
        {
            source = "nuke-effects-vulcanus",
            clone = "eon-nuke-effects-fulgora",
            replacements = {
                ["lava-hot"] = "oil-ocean-deep",
                ["lava"] = "oil-ocean-shallow",
            },
        },
        {
            source = "nuke-effects-vulcanus",
            clone = "eon-nuke-effects-vulcanus-swapped",
            replacements = {
                ["lava-hot"] = "lava",
                ["lava"] = "lava-hot",
            },
            before_effects = {
                {
                    type = "set-tile",
                    tile_name = "volcanic-cracks-warm",
                    radius = 14,
                    apply_projection = true,
                    tile_collision_mask = {
                        layers = {
                            water_tile = true,
                        },
                    },
                },
            },
        },
    },

    nauvis_crater = {
        source = "nuke-effects-nauvis",
        clone = "eon-nuke-crater-nauvis",
        decorative = "nuclear-ground-patch",
        spawn_min_radius = 11.5,
        spawn_max_radius = 12.5,
        spawn_min = 30,
        spawn_max = 40,
    },
}

registry.autoplace_scale = {
    { type = "simple-entity", name = "vulcanus-chimney",           factor = 0.1 },
    { type = "simple-entity", name = "vulcanus-chimney-faded",     factor = 0.1 },
    { type = "simple-entity", name = "vulcanus-chimney-cold",      factor = 0.1 },
    { type = "simple-entity", name = "vulcanus-chimney-short",     factor = 0.1 },
    { type = "simple-entity", name = "vulcanus-chimney-truncated", factor = 0.1 },
    { type = "simple-entity", name = "huge-volcanic-rock",         factor = 0.4 },
    { type = "simple-entity", name = "big-volcanic-rock",          factor = 0.4 },
}

registry.pollution_conversion_prototype_types = {
    "unit",
    "spider-unit",
    "unit-spawner",
    "turret",
    "tree",
    "plant",
    "agricultural-tower",
    "assembling-machine",
    "furnace",
    "mining-drill",
    "boiler",
    "generator",
    "reactor",
    "rocket-silo",
    "lab",
}

registry.clear_collision_mask = {
    ["unit-spawner"] = {
        "gleba-spawner-small",
        "gleba-spawner",
    },
}

registry.harvest_emissions = {
    plant = {
        ["jellystem"] = { pollution = 15 },
        ["yumako-tree"] = { pollution = 15 },
    },
}

registry.energy_source_emissions_per_minute = {
    ["agricultural-tower"] = {
        ["agricultural-camp"] = { pollution = 4 },
        ["agricultural-tower"] = { pollution = 4 },
    },
}

registry.electric_flying_enemies = {
    spawners = {
        "flying-electric-unit-spawner",
        "walker-electric-unit-spawner",
    },
    default_spawner_absorption = { pollution = { absolute = 20, proportional = 0.01 } },
    unit_pollution_sources = {
        [1] = "small-biter",
        [2] = "medium-biter",
        [3] = "big-biter",
        [4] = "behemoth-biter",
        [5] = "behemoth-biter",
    },
    unit_fallback_pollution = { 4, 20, 80, 400, 400 },
    unit_name_patterns = {
        "flying-electric-unit-%d",
        "walking-electric-unit-%d",
    },
}

registry.tungsten_plate_mode = {
    demolisher_corpses = {
        "small-demolisher-corpse",
        "medium-demolisher-corpse",
        "big-demolisher-corpse",
    },
    source_item = "tungsten-ore",
    replacement_item = "tungsten-plate",
    foundry_ingredient = "tungsten-carbide",
    foundry_recipe = "foundry",
}

return registry
