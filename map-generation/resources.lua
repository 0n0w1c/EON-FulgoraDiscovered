local resource_autoplace = require("resource-autoplace")
local base_sounds = require("__base__.prototypes.entity.sounds")
local simulations = require("__space-age__.prototypes.factoriopedia-simulations")


local eon_unrestricted_fulgora_aquilo_resources = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value == true
    and not (settings.startup["eon-fd-guarded-resources"]
        and settings.startup["eon-fd-guarded-resources"].value == true)

local eon_calcite_autoplace_density = eon_unrestricted_fulgora_aquilo_resources and 1.4 or 0.8
local eon_calcite_autoplace_spots = eon_unrestricted_fulgora_aquilo_resources and 2.4 or 1.5
local eon_calcite_autoplace_size_min = eon_unrestricted_fulgora_aquilo_resources and 3 or 2
local eon_calcite_autoplace_size_max = eon_unrestricted_fulgora_aquilo_resources and 6 or 4

local eon_tungsten_autoplace_density = eon_unrestricted_fulgora_aquilo_resources and 0.75 or 0.4
local eon_tungsten_autoplace_spots = eon_unrestricted_fulgora_aquilo_resources and 2.1 or 1.25
local eon_tungsten_autoplace_size_min = eon_unrestricted_fulgora_aquilo_resources and 3 or 2
local eon_tungsten_autoplace_size_max = eon_unrestricted_fulgora_aquilo_resources and 6 or 4

local stone_driving_sound = {
    sound = {
        filename = "__base__/sound/driving/vehicle-surface-stone.ogg",
        volume = 0.8,
        advanced_volume_control = { fades = { fade_in = { curve_type = "cosine", from = { control = 0.5, volume_percentage = 0.0 }, to = { 1.5, 100.0 } } } }
    },
    fade_ticks = 6
}

data.raw["autoplace-control"]["calcite"] = nil
data.raw["resource"]["calcite"] = nil
data.raw["autoplace-control"]["tungsten_ore"] = nil
data.raw["resource"]["tungsten-ore"] = nil

data:extend({
    {
        type = "autoplace-control",
        name = "calcite",
        localised_name = { "", "[entity=calcite] ", { "entity-name.calcite" } },
        richness = true,
        order = "b-c",
        category = "resource"
    },
    {
        type = "resource",
        name = "calcite",
        icon = "__space-age__/graphics/icons/calcite.png",
        flags = { "placeable-neutral" },
        order = "b",
        tree_removal_probability = 0.7,
        tree_removal_max_distance = 32 * 32,
        walking_sound = base_sounds.ore,
        driving_sound = stone_driving_sound,
        minable = {
            mining_particle = "calcite-particle",
            mining_time = 1,
            result = "calcite",
        },
        category = "hard-solid",
        collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        autoplace = resource_autoplace.resource_autoplace_settings {
            name = "calcite",
            order = "c-calcite",
            base_density = eon_calcite_autoplace_density,
            base_spots_per_km2 = eon_calcite_autoplace_spots,
            has_starting_area_placement = false,
            random_spot_size_minimum = eon_calcite_autoplace_size_min,
            random_spot_size_maximum = eon_calcite_autoplace_size_max,
            regular_rq_factor_multiplier = 1
        },
        stage_counts = { 15000, 9500, 5500, 2900, 1300, 400, 150, 80 },
        stages = {
            sheet =
            {
                filename = "__space-age__/graphics/entity/calcite/calcite.png",
                priority = "extra-high",
                width = 128,
                height = 128,
                frame_count = 8,
                variation_count = 8,
                scale = 0.5
            }
        },
        effect_animation_period = 5,
        effect_animation_period_deviation = 1,
        effect_darkness_multiplier = 3.6,
        min_effect_alpha = 0.2,
        max_effect_alpha = 0.3,
        mining_visualisation_tint = { r = 0.99, g = 1.0, b = 0.92, a = 1.000 },
        map_color = { 0.8, 0.7, 0.7 },
        factoriopedia_simulation = simulations.factoriopedia_calcite,
    },
    {
        type = "autoplace-control",
        name = "tungsten_ore",
        localised_name = { "", "[entity=tungsten-ore] ", { "entity-name.tungsten-ore" } },
        richness = true,
        order = "b-c",
        category = "resource"
    },
    {
        type = "resource",
        name = "tungsten-ore",
        icon = "__space-age__/graphics/icons/tungsten-ore.png",
        flags = { "placeable-neutral" },
        order = "b",
        tree_removal_probability = 0.7,
        tree_removal_max_distance = 32 * 32,
        walking_sound = base_sounds.ore,
        driving_sound = stone_driving_sound,
        minable = {
            mining_particle = "tungsten-ore-particle",
            mining_time = 5,
            result = "tungsten-ore",
        },
        category = "hard-solid",
        collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        autoplace = resource_autoplace.resource_autoplace_settings {
            name = "tungsten_ore",
            order = "c-tungsten",
            base_density = eon_tungsten_autoplace_density,
            base_spots_per_km2 = eon_tungsten_autoplace_spots,
            has_starting_area_placement = false,
            random_spot_size_minimum = eon_tungsten_autoplace_size_min,
            random_spot_size_maximum = eon_tungsten_autoplace_size_max,
            regular_rq_factor_multiplier = 1
        },
        stage_counts = { 15000, 9500, 5500, 2900, 1300, 400, 150, 80 },
        stages = {
            sheet =
            {
                filename = "__space-age__/graphics/entity/tungsten-ore/tungsten-ore.png",
                priority = "extra-high",
                width = 128,
                height = 128,
                frame_count = 8,
                variation_count = 8,
                scale = 0.5
            }
        },
        effect_animation_period = 5,
        effect_animation_period_deviation = 1,
        effect_darkness_multiplier = 3.6,
        min_effect_alpha = 0.2,
        max_effect_alpha = 0.3,
        mining_visualisation_tint = { r = 150 / 256, g = 150 / 256, b = 180 / 256, a = 1.000 },
        map_color = { r = 98 / 256, g = 86 / 256, b = 150 / 256, a = 1.000 },
        factoriopedia_simulation = simulations.factoriopedia_tungsten_ore,
    },

})

data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["calcite"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["tungsten_ore"] = {}
