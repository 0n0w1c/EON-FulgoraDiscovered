local eon_autoplace_masks = require("lib.eon-autoplace-masks")
local eon_gleba_registry = require("lib.eon-gleba-registry")
local biomes = require("lib.eon-biome-registry")

local gleba_masks = biomes.get("gleba").masks

local eon_gleba_terrain_setup = {}

local GLEBA_PLANT_FREQUENCY_EXPRESSION = "0.5 + 0.5 * sqrt(control:gleba_plants:frequency)"

---@class EonGlebaTerrainSetupConfig
---@field gleba_mask_threshold number Noise threshold used to classify the normal Gleba region.
---@field gleba_region_expression string Body of the `eon_gleba_region` noise function.
---@field gleba_south_bias_y_offset number Vertical offset applied before the southern-region bias.
---@field gleba_south_core_y_offset number Vertical offset of the guaranteed noisy southern core.

---@param first_seed integer Seed for the broad plant-distribution noise.
---@param second_seed integer Seed for the finer plant-distribution noise.
---@param first_input_scale string Noise expression controlling the broad feature scale.
---@return string probability_expression
local function plant_noise_expression(first_seed, second_seed, first_input_scale)
    return gleba_masks.territory ..
        "(abs(multioctave_noise{x = x, y = y, persistence = 0.8, seed0 = map_seed, seed1 = " ..
        first_seed .. ", octaves = 3, input_scale = " .. first_input_scale .. " } " ..
        "* multioctave_noise{x = x, y = y, persistence = 0.8, seed0 = map_seed, seed1 = " ..
        second_seed .. ", octaves = 3, input_scale = 1/6 * eon_gleba_plant_frequency }))"
end

---@param config EonGlebaTerrainSetupConfig
---@return nil
function eon_gleba_terrain_setup.apply(config)
    local eon_gleba_mask_threshold = config.gleba_mask_threshold
    local eon_gleba_region_expression = config.gleba_region_expression
    local eon_gleba_south_bias_y_offset = config.gleba_south_bias_y_offset
    local eon_gleba_south_core_y_offset = config.gleba_south_core_y_offset

    eon_gleba_registry.register_on_nauvis()

    eon_autoplace_masks.apply_group("mask_gleba_territory", eon_gleba_registry.territory_mask_autoplace_by_type)

    data.raw["autoplace-control"]["gleba_plants"].can_be_disabled = true
    data.raw["autoplace-control"]["gleba_water"].can_be_disabled = true

    data.raw["noise-expression"]["gleba_plants_noise"].expression =
        plant_noise_expression(700000, 200000, "1/20")
    data.raw["noise-expression"]["gleba_plants_noise_b"].expression =
        plant_noise_expression(750000, 250000, "1/20 * eon_gleba_plant_frequency")

    eon_gleba_registry.apply_agriculture_probability_expressions()

    data:extend({
        {
            type = "noise-expression",
            name = "eon_gleba_mask",
            expression = "eon_gleba_region(" .. eon_gleba_mask_threshold .. ")"
        },
        {
            type = "noise-expression",
            name = "eon_gleba_plant_frequency",
            expression = GLEBA_PLANT_FREQUENCY_EXPRESSION
        },
        {
            type = "noise-expression",
            name = "eon_jellynut_spots",
            expression =
            "clamp(eon_gleba_agriculture_spots(1, 64 * sqrt(control:gleba_water:size), control:gleba_water:frequency) * 5000 * control:gleba_water:frequency, -inf, 2)"
        },
        {
            type = "noise-expression",
            name = "eon_yumako_spots",
            expression =
            "clamp(eon_gleba_agriculture_spots(2, 64 * sqrt(control:gleba_water:size), control:gleba_water:frequency) * 5000 * control:gleba_water:frequency, -inf, 2)"
        },
        {
            type = "noise-expression",
            name = "eon_jellynut_soil",
            expression =
            "eon_gleba_agriculture_spots(1, 32 * sqrt(control:gleba_plants:size), eon_gleba_plant_frequency) * 6 * eon_gleba_plant_frequency"
        },
        {
            type = "noise-expression",
            name = "eon_yumako_soil",
            expression =
            "eon_gleba_agriculture_spots(2, 32 * sqrt(control:gleba_plants:size), eon_gleba_plant_frequency) * 6 * eon_gleba_plant_frequency"
        },

        {
            type = "noise-function",
            name = "eon_gleba_region",
            parameters = { "threshold" },
            expression = eon_gleba_region_expression,
            local_expressions = {
                gleba_noise = "quick_multioctave_noise{x = x,\z
                                                 y = y,\z
                                                 seed0 = map_seed,\z
                                                 seed1 = 5,\z
                                                 octaves = 4,\z
                                                 input_scale = 1 / 32,\z
                                                 output_scale = 1/2,\z
                                                 octave_output_scale_multiplier = 3,\z
                                                 octave_input_scale_multiplier = 1/3}",
                gleba_intermediate_noise = "quick_multioctave_noise{x = x,\z
                                                              y = y,\z
                                                              seed0 = map_seed,\z
                                                              seed1 = 6,\z
                                                              octaves = 4,\z
                                                              input_scale = 1 / 32,\z
                                                              output_scale = 2,\z
                                                              octave_output_scale_multiplier = 3,\z
                                                              octave_input_scale_multiplier = 1/3}",
                gleba_small_noise = "quick_multioctave_noise{x = x,\z
                                                              y = y,\z
                                                              seed0 = map_seed,\z
                                                              seed1 = 7,\z
                                                              octaves = 4,\z
                                                              input_scale = 1 / 4,\z
                                                              output_scale = 1,\z
                                                              octave_output_scale_multiplier = 3,\z
                                                              octave_input_scale_multiplier = 1/3}",
                y_offset = "y - " .. eon_gleba_south_bias_y_offset,
                south_offset = "y_offset / (1 + pow(2, 0.01 * y_offset)) + 0.1 * y_offset - 60",
                gleba_core_boundary_noise = "quick_multioctave_noise{x = x,\z
                                                                    y = y,\z
                                                                    seed0 = map_seed,\z
                                                                    seed1 = 8,\z
                                                                    octaves = 3,\z
                                                                    input_scale = 1/256,\z
                                                                    output_scale = 350,\z
                                                                    octave_output_scale_multiplier = 0.5,\z
                                                                    octave_input_scale_multiplier = 2}",
                south_core = "y_offset > " .. eon_gleba_south_core_y_offset .. " + gleba_core_boundary_noise"
            }
        },
        {
            type = "noise-function",
            name = "eon_gleba_agriculture_spots",
            parameters = { "seed", "spot_radius_expression", "spot_frequency_expression" },
            expression = gleba_masks.territory .. "(spot_noise{x = x + wobble_noise_x * 15,\z
                                                          y = y + wobble_noise_y * 15,\z
                                                          seed0 = map_seed,\z
                                                          seed1 = seed,\z
                                                          candidate_spot_count = 4,\z
                                                          suggested_minimum_candidate_point_spacing = 128,\z
                                                          skip_span = 1,\z
                                                          skip_offset = 0,\z
                                                          region_size = 1024 / max(0.125, spot_frequency_expression),\z
                                                          density_expression = 80,\z
                                                          spot_quantity_expression = 1000,\z
                                                          spot_radius_expression = spot_radius_expression,\z
                                                          hard_region_target_quantity = 0,\z
                                                          spot_favorability_expression = 60,\z
                                                          basement_value = -0.5,\z
                                                          maximum_spot_basement_radius = max(32, 128 * sqrt(control:gleba_water:size))})",
            local_expressions =
            {
                wobble_noise_x =
                "multioctave_noise{x = x, y = y, persistence = 0.5, seed0 = map_seed, seed1 = 3000000, octaves = 2, input_scale = 1/20}",
                wobble_noise_y =
                "multioctave_noise{x = x, y = y, persistence = 0.5, seed0 = map_seed, seed1 = 4000000, octaves = 2, input_scale = 1/20}"
            }
        },
        {
            type = "noise-function",
            name = gleba_masks.territory,
            parameters = { "expression" },
            expression = "if(eon_gleba_mask, expression, -inf)"
        },
        {
            type = "noise-function",
            name = gleba_masks.off_territory,
            parameters = { "expression" },
            expression = "if(eon_gleba_mask, -inf, expression)"
        },
    })
end

return eon_gleba_terrain_setup
