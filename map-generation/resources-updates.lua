--------------------------------------------------------------------------------
-- Fixes map generation for resources
--------------------------------------------------------------------------------
local terrain = require("map-generation.terrain")

local guarded_resources_enabled = settings.startup["eon-fd-guarded-resources"]
    and settings.startup["eon-fd-guarded-resources"].value

local data_util =
{
    table = {}
}

function data_util.spritesheets_to_pictures(spritesheets)
    local pictures = {}
    for _, spritesheet in pairs(spritesheets) do
        for i = 1, spritesheet.frame_count or 1, 1 do
            table.insert(pictures, data_util.sprite_load(spritesheet.path,
                {
                    frame_index = i - 1,
                    scale = spritesheet.scale or 0.5,
                    dice_y = spritesheet.dice_y
                })
            )
        end
    end
    return pictures
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

data.raw.planet["nauvis"].map_gen_settings.property_expression_names["entity:sulfuric-acid-geyser:probability"] =
"vulcanus_sulfuric_acid_geyser_probability"
data.raw.planet["nauvis"].map_gen_settings.property_expression_names["entity:sulfuric-acid-geyser:richness"] =
"vulcanus_sulfuric_acid_geyser_richness"

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
data.raw.resource["calcite"].autoplace.has_starting_area_placement = false
data.raw["noise-expression"]["vulcanus_starting_calcite"].expression = "-inf"

if guarded_resources_enabled then
    data.raw.resource["calcite"].autoplace.probability_expression =
    "eon_mask_off_ammonia_ocean(eon_mask_vulcano_terrain(vulcanus_calcite_probability))"
    data.raw.resource["calcite"].autoplace.richness_expression = "vulcanus_calcite_richness"
else
    data.raw["noise-expression"]["vulcanus_calcite_probability"].expression =
    "eon_mask_off_ammonia_ocean((control:calcite:size > 0) * (1000 * ((0.5 + vulcanus_calcite_region) * random_penalty_between(0.9, 1, 1) - 1)))"
    terrain.mask_resource_territory("calcite", "resource")
end

data.raw.resource["sulfuric-acid-geyser"].autoplace.has_starting_area_placement = false
data.raw["noise-expression"]["vulcanus_starting_sulfur"].expression = "-inf"

if guarded_resources_enabled then
    data.raw["noise-expression"]["vulcanus_sulfuric_acid_geyser_probability"].expression =
    "(control:sulfuric_acid_geyser:size > 0) * (0.003 * control:sulfuric_acid_geyser:frequency * ((vulcanus_sulfuric_acid_region_patchy > 0) + 2 * eon_updated_volcanic_folds))"
else
    data.raw["noise-expression"]["vulcanus_sulfuric_acid_geyser_probability"].expression =
    "(control:sulfuric_acid_geyser:size > 0) * (0.005 * ((vulcanus_sulfuric_acid_region_patchy > 0) + 2 * eon_updated_volcanic_folds))"
end

data.raw.resource["tungsten-ore"].autoplace.has_starting_area_placement = false
data.raw["noise-expression"]["vulcanus_starting_tungsten"].expression = "-inf"

if guarded_resources_enabled then
    data.raw.resource["tungsten-ore"].autoplace.probability_expression =
    "eon_mask_off_ammonia_ocean(eon_mask_vulcano_terrain(1000 * vulcanus_tungsten_ore_probability))"
    data.raw.resource["tungsten-ore"].autoplace.richness_expression = "vulcanus_tungsten_ore_richness"

    data.raw["noise-expression"]["vulcanus_tungsten_ore_region"].expression =
    "max(vulcanus_starting_tungsten, min(1 - vulcanus_starting_circle, vulcanus_place_non_metal_spots(789, 15, 2, vulcanus_tungsten_ore_size * min(1.2, vulcanus_ore_dist) * 25, control:tungsten_ore:frequency, vulcanus_mountains_resource_favorability)))"
else
    data.raw["noise-expression"]["vulcanus_tungsten_ore_probability"].expression =
    "eon_mask_off_ammonia_ocean((control:tungsten_ore:size > 0) * (1000 * ((0.7 + vulcanus_tungsten_ore_region) * random_penalty_between(0.9, 1, 1) - 1)))"
    terrain.mask_resource_territory("tungsten-ore", "resource")
end
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

data.raw.resource["calcite"].autoplace.probability_expression =
"eon_mask_off_ammonia_ocean(eon_mask_vulcano_terrain(vulcanus_calcite_probability * (1 - clamp(vulcanus_sulfuric_acid_region_patchy, 0, 1))))"

data.raw.resource["tungsten-ore"].autoplace.probability_expression =
"eon_mask_off_ammonia_ocean(eon_mask_vulcano_terrain(vulcanus_tungsten_ore_probability * (1 - clamp(vulcanus_sulfuric_acid_region_patchy, 0, 1))))"

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
                if not string.find(expression, "eon_mask_off_ammonia_ocean%(", 1, false) then
                    resource.autoplace.probability_expression = "eon_mask_off_ammonia_ocean(" .. expression .. ")"
                end
            end
        end
    end
end
