local aquilo = require("lib.eon-aquilo-registry")
local gleba = require("lib.eon-gleba-registry")
local nauvis = require("lib.eon-nauvis-registry")
local vulcanus = require("lib.eon-volcanus-registry")
local water_tiles = require("lib.eon-water-tiles")

local registry = {}

local function make_set(names)
    local set = {}
    for _, name in ipairs(names or {}) do
        set[name] = true
    end
    return set
end

registry.make_set = make_set

registry.cliff_blocking = {
    aquilo_names = aquilo.tiles,
    aquilo_set = aquilo.tile_set,
    nauvis_set = nauvis.tile_set or make_set(nauvis.tiles),
    rules = {
        {
            cliff_name = "cliff-gleba",
            tile_names = gleba.masked_tile_set or make_set(gleba.masked_tiles),
        },
        {
            cliff_name = "cliff-vulcanus",
            tile_names = vulcanus.all_tile_set or make_set(vulcanus.all_tiles),
        },
    },
}

registry.water_exclusion = {
    groups = water_tiles.groups,
    sets = water_tiles.group_sets,
    all_names = water_tiles.names,
    all_set = water_tiles.set,
    default_land_autoplace_group = "all",
    fulgora_enemy_group = "fulgora_oil_ocean",
}

registry.absorption_groups = {
    water_like = {
        "wetland-yumako",
        "wetland-jellynut",
        "wetland-blue-slime",
        "wetland-light-green-slime",
        "wetland-green-slime",
        "wetland-light-dead-skin",
        "wetland-dead-skin",
        "wetland-pink-tentacle",
        "wetland-red-tentacle",
        "lava",
        "oil-ocean-shallow",
        "oil-ocean-shallow-2",
        "brash-ice",
        "ammoniacal-ocean",
    },
    deepwater_like = {
        "gleba-deep-lake",
        "lava-hot",
        "oil-ocean-deep",
        "oil-ocean-deep-2",
        "ammoniacal-ocean-2",
    },
    grass_like = {
        "natural-yumako-soil",
        "natural-jellynut-soil",
        "lowland-brown-blubber",
        "lowland-olive-blubber",
        "lowland-olive-blubber-2",
        "lowland-olive-blubber-3",
        "lowland-pale-green",
        "lowland-cream-cauliflower",
        "lowland-cream-cauliflower-2",
        "lowland-dead-skin",
        "lowland-dead-skin-2",
        "lowland-cream-red",
        "lowland-red-vein",
        "lowland-red-vein-2",
        "lowland-red-vein-3",
        "lowland-red-vein-4",
        "lowland-red-vein-dead",
        "lowland-red-infection",
        "midland-turquoise-bark",
        "midland-turquoise-bark-2",
        "midland-cracked-lichen",
        "midland-cracked-lichen-dull",
        "midland-cracked-lichen-dark",
        "midland-yellow-crust",
        "midland-yellow-crust-2",
        "midland-yellow-crust-3",
        "midland-yellow-crust-4",
        "highland-dark-rock",
        "highland-dark-rock-2",
        "highland-yellow-rock",
        "pit-rock",
    },
    sand_like = {
        "fulgoran-rock",
        "fulgoran-dust",
        "fulgoran-sand",
        "fulgoran-dunes",
        "fulgoran-walls",
        "fulgoran-paving",
        "fulgoran-conduit",
        "fulgoran-machinery",
        "volcanic-ash-flats",
        "volcanic-ash-light",
        "volcanic-ash-dark",
        "volcanic-cracks",
        "volcanic-cracks-warm",
        "volcanic-folds",
        "volcanic-folds-flat",
        "volcanic-folds-warm",
        "volcanic-pumice-stones",
        "volcanic-cracks-hot",
        "volcanic-jagged-ground",
        "volcanic-smooth-stone",
        "volcanic-smooth-stone-warm",
        "volcanic-ash-cracks",
        "snow-flat",
        "snow-crests",
        "snow-lumpy",
        "snow-patchy",
        "ice-rough",
        "ice-smooth",
    },
}

registry.tree_pollution = {
    nauvis_source_candidates = {
        "tree-01",
        "tree-02",
        "tree-03",
        "tree-04",
        "tree-05",
        "tree-06",
        "tree-07",
        "tree-08",
        "tree-09",
    },
    copy_targets = {
        "cuttlepop",
        "slipstack",
        "funneltrunk",
        "hairyclubnub",
        "teflilly",
        "lickmaw",
        "stingfrond",
        "boompuff",
        "sunnycomb",
        "water-cane",
        "ashland-lichen-tree",
        "ashland-lichen-tree-flaming",
    },
}

registry.enemy_autoplace = {
    commander_collision_layers = {
        "item",
        "meltable",
        "object",
        "player",
        "is_object",
        "is_lower_object",
    },
    gleba_wetland_spawner_tiles = {
        "wetland-yumako",
        "wetland-jellynut",
        "wetland-blue-slime",
        "wetland-light-green-slime",
        "wetland-green-slime",
        "wetland-light-dead-skin",
        "wetland-dead-skin",
        "wetland-pink-tentacle",
        "wetland-red-tentacle",
    },
}

registry.transitions = {
    aquilo_oil_ocean_cleanup_tiles = {
        "snow-flat",
        "snow-crests",
        "snow-lumpy",
        "snow-patchy",
        "ice-rough",
        "ice-smooth",
        "brash-ice",
    },
    lava_water_source_tiles = { "water", "deepwater" },
    lava_hot_crack_tiles = { "volcanic-cracks-hot", "volcanic-cracks-warm" },
}

return registry
