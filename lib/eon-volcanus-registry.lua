local registry = {}

local function make_set(names)
    local set = {}
    for _, name in ipairs(names) do
        set[name] = true
    end
    return set
end

registry.all_tiles = {
    "volcanic-soil-dark",
    "volcanic-soil-light",
    "volcanic-ash-soil",
    "volcanic-ash-flats",
    "volcanic-ash-light",
    "volcanic-ash-dark",
    "volcanic-cracks",
    "volcanic-cracks-warm",
    "volcanic-folds",
    "volcanic-folds-flat",
    "lava",
    "lava-hot",
    "volcanic-folds-warm",
    "volcanic-pumice-stones",
    "volcanic-cracks-hot",
    "volcanic-jagged-ground",
    "volcanic-smooth-stone",
    "volcanic-smooth-stone-warm",
    "volcanic-ash-cracks",
}

registry.all_tile_set = make_set(registry.all_tiles)

registry.volcano_spot_tiles = {
    "volcanic-folds",
    "volcanic-folds-flat",
    "lava",
    "lava-hot",
}

registry.volcano_spot_tile_set = make_set(registry.volcano_spot_tiles)

registry.decorative_land_tiles = {
    "volcanic-ash-cracks",
    "volcanic-ash-dark",
    "volcanic-ash-flats",
    "volcanic-ash-light",
    "volcanic-ash-soil",
    "volcanic-cracks",
    "volcanic-cracks-hot",
    "volcanic-cracks-warm",
    "volcanic-folds",
    "volcanic-folds-flat",
    "volcanic-folds-warm",
    "volcanic-jagged-ground",
    "volcanic-pumice-stones",
    "volcanic-smooth-stone",
    "volcanic-smooth-stone-warm",
    "volcanic-soil-dark",
    "volcanic-soil-light",
}

registry.decorative_land_tile_set = make_set(registry.decorative_land_tiles)

registry.lava_fire_tiles = {
    "lava",
}

registry.lava_fire_tile_set = make_set(registry.lava_fire_tiles)

registry.northern_region_tile_probability_expressions = {
    ["volcanic-soil-dark"] = "volcanic_soil_dark_range",
    ["volcanic-soil-light"] = "volcanic_soil_light_range",
    ["volcanic-ash-soil"] = "volcanic_ash_soil_range",
    ["volcanic-ash-flats"] = "volcanic_ash_flats_range",
    ["volcanic-ash-light"] = "volcanic_ash_light_range",
    ["volcanic-ash-dark"] = "volcanic_ash_dark_range",
    ["volcanic-cracks"] = "volcanic_cracks_cold_range",
    ["volcanic-cracks-warm"] = "volcanic_cracks_warm_range",
    ["volcanic-folds"] = "volcanic_folds_range",
    ["volcanic-folds-flat"] = "volcanic_folds_flat_range",
    ["lava"] = "max(lava_basalts_range, lava_mountains_range)",
    ["lava-hot"] = "max(lava_hot_basalts_range, lava_hot_mountains_range)",
    ["volcanic-folds-warm"] = "volcanic_folds_warm_range",
    ["volcanic-pumice-stones"] = "volcanic_pumice_stones_range",
    ["volcanic-cracks-hot"] = "volcanic_cracks_hot_range",
    ["volcanic-jagged-ground"] = "volcanic_jagged_ground_range",
    ["volcanic-smooth-stone"] = "volcanic_smooth_stone_range",
    ["volcanic-smooth-stone-warm"] = "volcanic_smooth_stone_warm_range",
    ["volcanic-ash-cracks"] = "volcanic_ash_cracks_range",
}

registry.entity_autoplace_on_nauvis = {
    "crater-cliff",
    "vulcanus-chimney",
    "vulcanus-chimney-faded",
    "vulcanus-chimney-cold",
    "vulcanus-chimney-short",
    "vulcanus-chimney-truncated",
    "huge-volcanic-rock",
    "big-volcanic-rock",
    "ashland-lichen-tree",
    "ashland-lichen-tree-flaming",
}

registry.tree_names_off_aquilo = {
    "ashland-lichen-tree",
    "ashland-lichen-tree-flaming",
    "tree-volcanic-a",
}

registry.special_tree_probability_expressions = {
    ["ashland-lichen-tree"] = "eon_vulcanus_tree_on_nauvis",
    ["ashland-lichen-tree-flaming"] = "eon_vulcanus_tree_on_nauvis / 16",
}

registry.coverage_mask_autoplace_by_type = {
    ["simple-entity"] = {
        "vulcanus-chimney",
        "vulcanus-chimney-faded",
        "vulcanus-chimney-cold",
        "vulcanus-chimney-short",
        "vulcanus-chimney-truncated",
        "huge-volcanic-rock",
        "big-volcanic-rock",
    },
    tile = {
        "volcanic-ash-flats",
        "volcanic-ash-light",
        "volcanic-ash-dark",
        "volcanic-cracks",
        "volcanic-cracks-warm",
        "volcanic-folds-warm",
        "volcanic-pumice-stones",
        "volcanic-cracks-hot",
        "volcanic-jagged-ground",
        "volcanic-smooth-stone",
        "volcanic-smooth-stone-warm",
        "volcanic-ash-cracks",
    },
}

registry.terrain_mask_autoplace_by_type = {
    tree = {
        "ashland-lichen-tree",
        "ashland-lichen-tree-flaming",
    },
}

return registry
