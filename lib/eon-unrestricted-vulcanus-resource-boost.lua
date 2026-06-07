local eon_autoplace_policy = require("lib.eon-autoplace-policy")
local biomes = require("lib.eon-biome-registry")

local vulcanus_masks = biomes.get("vulcanus").masks
local eon_aquilo_resource_tiles = require("lib.eon-aquilo-resource-tile-policy")

---@class EonUnrestrictedVulcanusResourceBoostConfig
---@field nauvis_settings table<string, table>|nil
---@field resource_configs table<string, table>

local unrestricted_vulcanus_resource_boost = {}

local expression_for_autoplace = eon_autoplace_policy.autoplace_probability_expression
local richness_expression_for_autoplace = eon_autoplace_policy.autoplace_richness_expression
local nauvis_style_vulcanus_patches_expression = eon_autoplace_policy.resource_autoplace_all_patches_expression
local nauvis_style_vulcanus_probability_expression = eon_autoplace_policy.resource_probability_from_patches_expression
local nauvis_style_vulcanus_richness_expression = eon_autoplace_policy.resource_richness_from_patches_expression

---@param name string
---@param expression string
---@return nil
local function set_or_extend_noise_expression(name, expression)
    local existing = data.raw["noise-expression"] and data.raw["noise-expression"][name]

    if existing then
        existing.expression = expression
    else
        data:extend({
            {
                type = "noise-expression",
                name = name,
                expression = expression
            }
        })
    end
end

---@param entity_name string
---@param property_name string
---@param expression_name string
---@return nil
local function set_nauvis_entity_property_expression(entity_name, property_name, expression_name)
    eon_autoplace_policy.set_planet_entity_property_expression("nauvis", entity_name, property_name, expression_name)
end

---@param resource_name string
---@param property_name string
---@return string
local function unrestricted_vulcanus_expression_name(resource_name, property_name)
    return eon_autoplace_policy.prototype_property_expression_name(
        "eon_unrestricted_vulcanus",
        resource_name,
        property_name
    )
end

---@param expression string
---@param additive_expression string
---@return string
local function add_expression_on_vulcanus_terrain(expression, additive_expression)
    return eon_autoplace_policy.max_with_masked_expression(expression, vulcanus_masks.terrain, additive_expression)
end

---@param resource_name string
---@param resource table
---@param config table
---@return nil
local function boost_resource(resource_name, resource, config)
    if not resource.autoplace then return end

    local patches_name = unrestricted_vulcanus_expression_name(resource_name, "patches")
    set_or_extend_noise_expression(patches_name, nauvis_style_vulcanus_patches_expression(config))

    local probability_expression = expression_for_autoplace(resource)
    if probability_expression and probability_expression ~= "" then
        local probability_name = unrestricted_vulcanus_expression_name(resource_name, "probability")
        local boosted_probability_expression = add_expression_on_vulcanus_terrain(
            probability_expression,
            nauvis_style_vulcanus_probability_expression(config, patches_name)
        )

        set_or_extend_noise_expression(
            probability_name,
            eon_aquilo_resource_tiles.mask_off_invalid_aquilo_resource_tiles(boosted_probability_expression)
        )
        resource.autoplace.probability_expression = probability_name
        set_nauvis_entity_property_expression(resource_name, "probability", probability_name)
    end

    local richness_expression = richness_expression_for_autoplace(resource)
    if richness_expression and richness_expression ~= "" then
        local richness_name = unrestricted_vulcanus_expression_name(resource_name, "richness")
        local boosted_richness_expression = add_expression_on_vulcanus_terrain(
            richness_expression,
            nauvis_style_vulcanus_richness_expression(config, patches_name)
        )

        set_or_extend_noise_expression(richness_name, boosted_richness_expression)
        resource.autoplace.richness_expression = richness_name
        set_nauvis_entity_property_expression(resource_name, "richness", richness_name)
    end
end

---@param config EonUnrestrictedVulcanusResourceBoostConfig
---@return nil
function unrestricted_vulcanus_resource_boost.apply(config)
    local nauvis_settings = config.nauvis_settings
    local resource_configs = config.resource_configs or {}

    if not nauvis_settings then return end

    for resource_name, resource in pairs(data.raw.resource or {}) do
        if nauvis_settings[resource_name]
            and resource_configs[resource_name] ~= nil
        then
            boost_resource(resource_name, resource, resource_configs[resource_name])
        end
    end
end

return unrestricted_vulcanus_resource_boost
