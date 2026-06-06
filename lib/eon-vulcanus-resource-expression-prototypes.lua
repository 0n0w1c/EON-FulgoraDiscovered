---@class EonVulcanusResourceExpressionsNoiseConfig
---@field guarded_resources_enabled boolean
---@field mask_vulcanus_resource_terrain fun(expression:string):string
---@field mask_off_ammonia_ocean fun(expression:string):string
---@field mask_off_aquilo_resource_tiles fun(expression:string):string
---@field vulcanus_resource_richness_expression string

local vulcanus_resource_expressions = {}

---@param config EonVulcanusResourceExpressionsNoiseConfig
---@return table[]
function vulcanus_resource_expressions.noise_prototypes(config)
    local guarded_resources_enabled = config.guarded_resources_enabled == true

    ---@type fun(expression:string):string
    local mask_vulcanus_resource_terrain = config.mask_vulcanus_resource_terrain

    ---@type fun(expression:string):string
    local mask_off_ammonia_ocean = config.mask_off_ammonia_ocean

    ---@type fun(expression:string):string
    local mask_off_aquilo_resource_tiles = config.mask_off_aquilo_resource_tiles

    ---@type string
    local vulcanus_resource_richness_expression = config.vulcanus_resource_richness_expression

    local calcite_probability_base_expression =
    "(control:calcite:size > 0) * \z
    (1000 * ((1 + vulcanus_calcite_region) * random_penalty_between(0.9, 1, 1) - 1))"

    local calcite_probability_expression = guarded_resources_enabled
        and mask_vulcanus_resource_terrain(calcite_probability_base_expression)
        or mask_off_ammonia_ocean(calcite_probability_base_expression)

    local calcite_richness_expression = guarded_resources_enabled
        and string.format(vulcanus_resource_richness_expression, "vulcanus_calcite_richness")
        or "vulcanus_calcite_richness"

    local sulfuric_acid_geyser_probability_base_expression =
    "(control:sulfuric_acid_geyser:size > 0) * \z
    (0.025 * control:sulfuric_acid_geyser:frequency * \z
    ((vulcanus_sulfuric_acid_region_patchy > 0) + 2 * vulcanus_sulfuric_acid_region_patchy))"

    local sulfuric_acid_geyser_probability_expression = guarded_resources_enabled
        and mask_vulcanus_resource_terrain(sulfuric_acid_geyser_probability_base_expression)
        or mask_off_aquilo_resource_tiles(sulfuric_acid_geyser_probability_base_expression)

    local sulfuric_acid_geyser_richness_expression = guarded_resources_enabled
        and string.format(vulcanus_resource_richness_expression, "vulcanus_sulfuric_acid_geyser_richness")
        or "vulcanus_sulfuric_acid_geyser_richness"

    local default_sulfuric_acid_geyser_patches_expression =
    "resource_autoplace_all_patches{base_density = 8.2, base_spots_per_km2 = 1.8, \z
    candidate_spot_count = 21, frequency_multiplier = control:sulfuric_acid_geyser:frequency, \z
    has_starting_area_placement = 0, random_spot_size_minimum = 1, random_spot_size_maximum = 1, \z
    regular_blob_amplitude_multiplier = 0.125, \z
    regular_patch_set_count = default_regular_resource_patch_set_count, regular_patch_set_index = 5, \z
    regular_rq_factor = 0.1, seed1 = 177, size_multiplier = control:sulfuric_acid_geyser:size, \z
    starting_blob_amplitude_multiplier = 0.125, \z
    starting_patch_set_count = default_starting_resource_patch_set_count, starting_patch_set_index = 0, \z
    starting_rq_factor = 0.14285714285714}"

    local default_sulfuric_acid_geyser_probability_base_expression =
    "(control:sulfuric_acid_geyser:size > 0) * \z
    (clamp(eon_default_sulfuric_acid_geyser_patches, 0, 1) * random_penalty{x = x, y = y, source = 1, amplitude = 1 / 0.020833333333333})"

    local default_sulfuric_acid_geyser_probability_expression =
        mask_off_aquilo_resource_tiles(default_sulfuric_acid_geyser_probability_base_expression)

    local default_sulfuric_acid_geyser_richness_expression =
    "(control:sulfuric_acid_geyser:size > 0) * \z
    (control:sulfuric_acid_geyser:richness * \z
    (eon_default_sulfuric_acid_geyser_patches / 0.020833333333333 + 220000) * \z
    max((1000 + distance) / 2600, 1))"

    return {
        {
            type = "noise-expression",
            name = "eon_nauvis_vulcanus_calcite_probability",
            expression = calcite_probability_expression
        },
        {
            type = "noise-expression",
            name = "eon_nauvis_vulcanus_calcite_richness",
            expression = calcite_richness_expression
        },
        {
            type = "noise-expression",
            name = "eon_nauvis_vulcanus_sulfuric_acid_geyser_probability",
            expression = sulfuric_acid_geyser_probability_expression
        },
        {
            type = "noise-expression",
            name = "eon_nauvis_vulcanus_sulfuric_acid_geyser_richness",
            expression = sulfuric_acid_geyser_richness_expression
        },
        {
            type = "noise-expression",
            name = "eon_default_sulfuric_acid_geyser_patches",
            expression = default_sulfuric_acid_geyser_patches_expression
        },
        {
            type = "noise-expression",
            name = "eon_default_sulfuric_acid_geyser_probability",
            expression = default_sulfuric_acid_geyser_probability_expression
        },
        {
            type = "noise-expression",
            name = "eon_default_sulfuric_acid_geyser_richness",
            expression = default_sulfuric_acid_geyser_richness_expression
        }
    }
end

return vulcanus_resource_expressions
