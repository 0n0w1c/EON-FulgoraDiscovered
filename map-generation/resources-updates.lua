--------------------------------------------------------------------------------
-- Fixes map generation for resources
--------------------------------------------------------------------------------
local terrain = require("map-generation.terrain")
local resource_autoplace = require("resource-autoplace")

local guarded_resources_enabled = settings.startup["eon-fd-guarded-resources"]
    and settings.startup["eon-fd-guarded-resources"].value

local function mask_off_ammonia_ocean(expression)
    return "eon_mask_off_ammonia_ocean(" .. expression .. ")"
end

local function mask_vulcanus_terrain(expression)
    return "eon_mask_vulcano_terrain(" .. expression .. ")"
end

local function mask_vulcanus_coverage(expression)
    return "eon_mask_vulcano_coverage(" .. expression .. ")"
end

local function mask_resource_territory_expression(expression)
    return "eon_mask_resource_territory(" .. expression .. ")"
end

local function set_resource_probability(resource_name, expression)
    data.raw.resource[resource_name].autoplace.probability_expression = expression
end

local function set_guarded_resource_probability(resource_name, expression)
    set_resource_probability(resource_name, mask_off_ammonia_ocean(mask_vulcanus_coverage(expression)))
end

local function configure_guarded_resource(config)
    if guarded_resources_enabled then
        config.guarded()
    else
        config.normal()
    end
end

--------------------------------------------------------------------------------
-- MARK: Fix Nauvis resources
--------------------------------------------------------------------------------

terrain.mask_resource_territory("iron-ore", "resource")
terrain.mask_resource_territory("copper-ore", "resource")
terrain.mask_resource_territory("stone", "resource")
terrain.mask_resource_territory("coal", "resource")
terrain.mask_resource_territory("uranium-ore", "resource")
terrain.mask_resource_territory("crude-oil", "resource")

--------------------------------------------------------------------------------
-- MARK: Remove Aquilo resources
--------------------------------------------------------------------------------

data.raw["noise-expression"]["aquilo_crude_oil_spots"].expression = "0"
data.raw.planet["aquilo"].map_gen_settings.autoplace_controls = {}

--------------------------------------------------------------------------------
-- MARK: Gleba
--------------------------------------------------------------------------------

data.raw["autoplace-control"]["gleba_plants"].localised_description = nil

--------------------------------------------------------------------------------
-- MARK: Add Vulcanus resources to Nauvis
--------------------------------------------------------------------------------

table.insert(data.raw["simple-entity"]["big-volcanic-rock"].minable.results,
    { type = "item", name = "calcite", amount_min = 2, amount_max = 8 })
table.insert(data.raw["simple-entity"]["huge-volcanic-rock"].minable.results,
    { type = "item", name = "calcite", amount_min = 3, amount_max = 15 })

data.raw["autoplace-control"]["vulcanus_volcanism"].order = "z-volcanism"
data.raw["autoplace-control"]["vulcanus_volcanism"].category = "resource"
data.raw["autoplace-control"]["vulcanus_volcanism"].localised_description = nil

data.raw["autoplace-control"]["sulfuric_acid_geyser"].order = "b-z"

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["calcite"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["sulfuric-acid-geyser"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["tungsten-ore"] = {}

data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["sulfuric_acid_geyser"] = {}

if guarded_resources_enabled then
    data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["calcite"] = {}
    data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["tungsten_ore"] = {}
end

-- START: Fix Resource spawning
data.raw["noise-expression"]["vulcanus_starting_calcite"].expression = "-inf"

configure_guarded_resource {
    guarded = function()
        set_guarded_resource_probability("calcite", "vulcanus_calcite_probability")
        data.raw.resource["calcite"].autoplace.richness_expression = "vulcanus_calcite_richness"
    end,
    normal = function()
        data.raw["noise-expression"]["vulcanus_calcite_probability"].expression =
            mask_off_ammonia_ocean("(control:calcite:size > 0) * (1000 * ((0.5 + vulcanus_calcite_region) * random_penalty_between(0.9, 1, 1) - 1))")
        terrain.mask_resource_territory("calcite", "resource")
    end
}

data.raw["noise-expression"]["vulcanus_starting_sulfur"].expression = "-inf"

local nauvis_property_expression_names = data.raw.planet["nauvis"].map_gen_settings.property_expression_names

configure_guarded_resource {
    guarded = function()
        nauvis_property_expression_names["entity:sulfuric-acid-geyser:probability"] =
            "vulcanus_sulfuric_acid_geyser_probability"
        nauvis_property_expression_names["entity:sulfuric-acid-geyser:richness"] =
            "vulcanus_sulfuric_acid_geyser_richness"

        data.raw["noise-expression"]["vulcanus_sulfuric_acid_geyser_probability"].expression =
            mask_off_ammonia_ocean(mask_vulcanus_coverage("(control:sulfuric_acid_geyser:size > 0) * (0.015 * control:sulfuric_acid_geyser:frequency * ((vulcanus_sulfuric_acid_region_patchy > 0) + 2 * eon_updated_volcanic_folds))"))
    end,
    normal = function()
        nauvis_property_expression_names["entity:sulfuric-acid-geyser:probability"] = nil
        nauvis_property_expression_names["entity:sulfuric-acid-geyser:richness"] = nil

        data.raw.resource["sulfuric-acid-geyser"].autoplace = resource_autoplace.resource_autoplace_settings {
            name = "sulfuric_acid_geyser",
            order = "c",
            base_density = 8.2,
            base_spots_per_km2 = 5.4,
            random_probability = 1 / 48,
            random_spot_size_minimum = 1,
            random_spot_size_maximum = 1,
            additional_richness = 220000,
            regular_rq_factor_multiplier = 1
        }
        set_resource_probability(
            "sulfuric-acid-geyser",
            mask_off_ammonia_ocean(mask_resource_territory_expression(data.raw.resource["sulfuric-acid-geyser"].autoplace.probability_expression))
        )
    end
}

data.raw["noise-expression"]["vulcanus_starting_tungsten"].expression = "-inf"

configure_guarded_resource {
    guarded = function()
        set_guarded_resource_probability("tungsten-ore", "1000 * vulcanus_tungsten_ore_probability")
        data.raw.resource["tungsten-ore"].autoplace.richness_expression = "vulcanus_tungsten_ore_richness"

        data.raw["noise-expression"]["vulcanus_tungsten_ore_region"].expression =
            "max(vulcanus_starting_tungsten, min(1 - vulcanus_starting_circle, vulcanus_place_non_metal_spots(789, 15, 2, vulcanus_tungsten_ore_size * min(1.2, vulcanus_ore_dist) * 25, control:tungsten_ore:frequency, vulcanus_mountains_resource_favorability)))"
    end,
    normal = function()
        data.raw["noise-expression"]["vulcanus_tungsten_ore_probability"].expression =
            mask_off_ammonia_ocean("(control:tungsten_ore:size > 0) * (1000 * ((0.7 + vulcanus_tungsten_ore_region) * random_penalty_between(0.9, 1, 1) - 1))")
        terrain.mask_resource_territory("tungsten-ore", "resource")
    end
}
-- END: Fix Resource spawning

if guarded_resources_enabled then
    local allowed = {
        ["calcite"] = true,
        ["tungsten-ore"] = true,
        ["sulfuric-acid-geyser"] = true
    }

    local nauvis_settings = data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings
    if not nauvis_settings then return end

    for resource_name, resource in pairs(data.raw.resource) do
        if not allowed[resource_name] and nauvis_settings[resource_name] then
            resource.autoplace = resource.autoplace or {}

            local old = resource.autoplace.probability_expression
            if old then
                resource.autoplace.probability_expression =
                    "(" .. old .. ") * (1 - eon_vulcanus_terrain)"
            else
                resource.autoplace.probability_expression =
                "(1 - eon_vulcanus_terrain)"
            end
        end
    end
end

if guarded_resources_enabled then
    set_guarded_resource_probability(
        "calcite",
        "vulcanus_calcite_probability * (1 - clamp(vulcanus_sulfuric_acid_region_patchy, 0, 1))"
    )

    set_guarded_resource_probability(
        "tungsten-ore",
        "vulcanus_tungsten_ore_probability * (1 - clamp(vulcanus_sulfuric_acid_region_patchy, 0, 1))"
    )
end

local nauvis_settings = data.raw.planet["nauvis"]
    and data.raw.planet["nauvis"].map_gen_settings
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings

if nauvis_settings then
    for resource_name, resource in pairs(data.raw.resource) do
        if nauvis_settings[resource_name]
            and resource.autoplace
            and type(resource.autoplace.probability_expression) == "string"
            and resource.autoplace.probability_expression ~= ""
        then
            local expression = resource.autoplace.probability_expression

            if type(expression) == "string" and expression ~= "" then
                if not string.find(expression, "eon_mask_off_ammonia_ocean(", 1, true) then
                    resource.autoplace.probability_expression = mask_off_ammonia_ocean(expression)
                end
            end
        end
    end
end
