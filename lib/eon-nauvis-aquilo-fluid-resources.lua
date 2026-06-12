local eon_resource_registry = require("lib.eon-resource-registry")
local eon_terrain_map_gen = require("lib.eon-terrain-map-gen")

local nauvis_aquilo_fluids = {}

local AQUILO_CORE_SNOW_DECAL_SEAM_DEPTH = 192
local AQUILO_CORE_SNOWY_DECAL_CORE_MIN = 0.22
local AQUILO_CORE_SNOWY_DECAL_SEAM_MIN = 0.18
local AQUILO_CORE_SNOW_DRIFT_CORE_MIN = 0.08
local AQUILO_CORE_SNOW_DRIFT_SEAM_MIN = 0.06

---@param base_expression string Native decorative probability expression.
---@param core_min number Minimum probability inside the authoritative deep core.
---@param seam_min number Minimum probability within the core-boundary seam.
---@return string probability_expression
local function aquilo_snow_decal_expression(base_expression, core_min, seam_min)
    return "if(eon_aquilo_core_mask, max(" .. base_expression .. ", " .. core_min .. "), " ..
        "if(abs(eon_aquilo_core_depth) < " .. AQUILO_CORE_SNOW_DECAL_SEAM_DEPTH ..
        ", max(" .. base_expression .. ", " .. seam_min .. "), " .. base_expression .. "))"
end

---@class EonNauvisAquiloFluidResourceConfig
---@field resource_name string
---@field expression_name string
---@field control string
---@field seed integer
---@field guarded_count integer
---@field skip_offset integer
---@field guarded_radius number
---@field unrestricted_patch_index integer
---@field unrestricted_seed integer
---@field probability_multiplier number
---@field richness number

---@class NauvisAquiloFluidsApplyArgs
---@field guarded_resources_enabled boolean
---@field snow_decorative_mask string
---@field mask_resource_tiles fun(expression:string, in_aquilo_only:boolean):string

---@param control string
---@param property string
---@return string
local function control_expression(control, property)
    return "control:" .. control .. ":" .. property
end

---@param config EonNauvisAquiloFluidResourceConfig
---@param property string
---@return string
local function fluid_expression_name(config, property)
    return "eon_nauvis_aquilo_" .. config.expression_name .. "_" .. property
end

---@param config EonNauvisAquiloFluidResourceConfig
---@param guarded_resources_enabled boolean
---@return string
local function fluid_spots_expression(config, guarded_resources_enabled)
    local frequency = control_expression(config.control, "frequency")
    local size = control_expression(config.control, "size")

    if guarded_resources_enabled then
        return "aquilo_spot_noise{seed = " .. config.seed ..
            ", count = " .. config.guarded_count ..
            ", skip_offset = " .. config.skip_offset ..
            ", region_size = 600 + 400 / " .. frequency ..
            ", density = 1" ..
            ", radius = aquilo_spot_size * " .. config.guarded_radius .. " * sqrt(" .. size .. ")" ..
            ", favorability = 1}"
    end

    return "resource_autoplace_all_patches{base_density = 8.2" ..
        ", base_spots_per_km2 = 1.8" ..
        ", candidate_spot_count = 21" ..
        ", frequency_multiplier = " .. frequency ..
        ", has_starting_area_placement = 0" ..
        ", random_spot_size_minimum = 1" ..
        ", random_spot_size_maximum = 1" ..
        ", regular_blob_amplitude_multiplier = 0.125" ..
        ", regular_patch_set_count = default_regular_resource_patch_set_count" ..
        ", regular_patch_set_index = " .. config.unrestricted_patch_index ..
        ", regular_rq_factor = 0.1" ..
        ", seed1 = " .. config.unrestricted_seed ..
        ", size_multiplier = " .. size ..
        ", starting_blob_amplitude_multiplier = 0.125" ..
        ", starting_patch_set_count = default_starting_resource_patch_set_count" ..
        ", starting_patch_set_index = 0" ..
        ", starting_rq_factor = 0.14285714285714}"
end

---@param config EonNauvisAquiloFluidResourceConfig
---@param spots_name string
---@param guarded_resources_enabled boolean
---@param mask_resource_tiles fun(expression:string, in_aquilo_only:boolean):string
---@return string
local function fluid_probability_expression(config, spots_name, guarded_resources_enabled, mask_resource_tiles)
    local size = control_expression(config.control, "size")

    if guarded_resources_enabled then
        return mask_resource_tiles(
            "(" .. size .. " > 0) * max(0, " .. spots_name .. ") * " .. config.probability_multiplier,
            true
        )
    end

    return mask_resource_tiles(
        "(" .. size .. " > 0) * (clamp(" .. spots_name ..
        ", 0, 1) * random_penalty{x = x, y = y, source = 1, amplitude = 1 / 0.020833333333333})",
        false
    )
end

---@param config EonNauvisAquiloFluidResourceConfig
---@param spots_name string
---@param guarded_resources_enabled boolean
---@return string
local function fluid_richness_expression(config, spots_name, guarded_resources_enabled)
    local size = control_expression(config.control, "size")
    local richness = control_expression(config.control, "richness")

    if guarded_resources_enabled then
        return "max(0, " .. spots_name .. ") * " .. config.richness .. " * " .. richness
    end

    return "(" .. size .. " > 0) * (" .. richness .. " * (" .. spots_name ..
        " / 0.020833333333333 + 220000) * max((1000 + distance) / 2600, 1))"
end

---@param resource_name string
---@param probability_name string
---@param richness_name string
---@return nil
local function assign_fluid_resource(resource_name, probability_name, richness_name)
    local resource = data.raw.resource[resource_name]
    if not resource or not resource.autoplace then return end

    resource.autoplace.probability_expression = probability_name
    resource.autoplace.richness_expression = richness_name
    eon_terrain_map_gen.set_entity_property_expression("nauvis", resource_name, "probability", probability_name)
    eon_terrain_map_gen.set_entity_property_expression("nauvis", resource_name, "richness", richness_name)
end

---@param name string
---@param expression_name string
---@return nil
local function assign_snow_decorative(name, expression_name)
    local decorative = data.raw["optimized-decorative"] and data.raw["optimized-decorative"][name]
    if not decorative or not decorative.autoplace then return end

    decorative.autoplace.tile_restriction = nil
    decorative.autoplace.probability_expression = expression_name
    eon_terrain_map_gen.set_decorative_probability_expression("nauvis", name, expression_name)
end

---@param args NauvisAquiloFluidsApplyArgs
---@return nil
function nauvis_aquilo_fluids.apply(args)
    ---@type boolean
    local guarded_resources_enabled = args.guarded_resources_enabled

    ---@type fun(expression:string, in_aquilo_only:boolean):string
    local mask_resource_tiles = args.mask_resource_tiles

    ---@type string
    local snow_decorative_mask = args.snow_decorative_mask

    ---@type EonNauvisAquiloFluidResourceConfig[]
    local fluid_resource_configs = eon_resource_registry.nauvis_aquilo_fluid_resource_configs

    local fluid_resource_spots = "max(eon_nauvis_aquilo_lithium_brine_spots, eon_nauvis_aquilo_fluorine_vent_spots)"

    ---@type table[]
    local fluid_resource_expressions = {}

    for _, config in ipairs(fluid_resource_configs) do
        local spots_name = fluid_expression_name(config, "spots")
        local probability_name = fluid_expression_name(config, "probability")
        local richness_name = fluid_expression_name(config, "richness")

        table.insert(fluid_resource_expressions, {
            type = "noise-expression",
            name = spots_name,
            expression = fluid_spots_expression(config, guarded_resources_enabled),
        })

        table.insert(fluid_resource_expressions, {
            type = "noise-expression",
            name = probability_name,
            expression = fluid_probability_expression(config, spots_name, guarded_resources_enabled, mask_resource_tiles),
        })

        table.insert(fluid_resource_expressions, {
            type = "noise-expression",
            name = richness_name,
            expression = fluid_richness_expression(config, spots_name, guarded_resources_enabled),
        })

        assign_fluid_resource(config.resource_name, probability_name, richness_name)
    end

    table.insert(fluid_resource_expressions, {
        type = "noise-expression",
        name = "eon_nauvis_aquilo_fluid_resource_snow_decal",
        expression = mask_resource_tiles(
            "min(0.055, 0.9 * clamp(" .. fluid_resource_spots .. " - 0.16, 0, 1))",
            guarded_resources_enabled
        ),
    })

    table.insert(fluid_resource_expressions, {
        type = "noise-expression",
        name = "eon_nauvis_aquilo_fluid_resource_snow_drift",
        expression = mask_resource_tiles(
            "min(0.018, 0.35 * clamp(" .. fluid_resource_spots .. " - 0.24, 0, 1))",
            guarded_resources_enabled
        ),
    })

    data:extend(fluid_resource_expressions)

    local snowy_decal_expression_name = "eon_nauvis_aquilo_fluid_resource_snowy_decal_probability"
    local snow_drift_decal_expression_name = "eon_nauvis_aquilo_fluid_resource_snow_drift_decal_probability"

    data:extend({
        {
            type = "noise-expression",
            name = snowy_decal_expression_name,
            expression = "max(" ..
                snow_decorative_mask ..
                "(" ..
                aquilo_snow_decal_expression("eon_aqulio_snowy_decal", AQUILO_CORE_SNOWY_DECAL_CORE_MIN,
                    AQUILO_CORE_SNOWY_DECAL_SEAM_MIN) .. "), eon_nauvis_aquilo_fluid_resource_snow_decal)"
        },
        {
            type = "noise-expression",
            name = snow_drift_decal_expression_name,
            expression = "max(" ..
                snow_decorative_mask ..
                "(" ..
                aquilo_snow_decal_expression("eon_snow_drift_decal", AQUILO_CORE_SNOW_DRIFT_CORE_MIN,
                    AQUILO_CORE_SNOW_DRIFT_SEAM_MIN) .. "), eon_nauvis_aquilo_fluid_resource_snow_drift)"
        }
    })

    assign_snow_decorative("aqulio-snowy-decal", snowy_decal_expression_name)
    assign_snow_decorative("snow-drift-decal", snow_drift_decal_expression_name)
end

return nauvis_aquilo_fluids
