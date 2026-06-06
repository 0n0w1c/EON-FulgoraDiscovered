local eon_autoplace_policy = require("lib.eon-autoplace-policy")
local eon_resource_registry = require("lib.eon-resource-registry")

---@class EonGuardedResourceBiomeAlignConfig
---@field aquilo_on_fulgora boolean

local guarded_resource_biome_policy = {}

---@param expression string
---@return string
local function mask_off_ammonia_ocean(expression)
    return "eon_mask_off_ammonia_ocean(" .. expression .. ")"
end

---@param planet_name string
---@return table<string, table>|nil
local function get_planet_entity_settings(planet_name)
    return eon_autoplace_policy.planet_autoplace_category_settings(planet_name, "entity", false)
end

local expression_for_autoplace = eon_autoplace_policy.autoplace_probability_expression
local richness_expression_for_autoplace = eon_autoplace_policy.autoplace_richness_expression
local mask_expression = eon_autoplace_policy.wrap_expression
local combine_masked_expressions = eon_autoplace_policy.combine_max_expressions
local add_masked_expression = eon_autoplace_policy.add_wrapped_expression

---@param planet_name string
---@param entity_name string
---@return string|nil
local function get_planet_richness_expression(planet_name, entity_name)
    return eon_autoplace_policy.get_planet_entity_property_expression(planet_name, entity_name, "richness")
end

---@param planet_name string
---@param entity_name string
---@return string|nil
local function get_planet_probability_expression(planet_name, entity_name)
    return eon_autoplace_policy.get_planet_entity_property_expression(planet_name, entity_name, "probability")
end

---@param entity_name string
---@param mask_name string
---@return nil
local function apply_simple_entity_biome_mask(entity_name, mask_name)
    local proto = data.raw["simple-entity"] and data.raw["simple-entity"][entity_name]
    eon_autoplace_policy.wrap_autoplace_probability(proto, mask_name, "1")
end

---@param resource_name string
---@param planet_name string
---@param default_expression string
---@return string
local function guarded_resource_expression_for_planet(resource_name, planet_name, default_expression)
    if not eon_resource_registry.use_current_expression_in_guarded_alignment[resource_name] then
        local planet_expression = get_planet_probability_expression(planet_name, resource_name)
        if planet_expression then return planet_expression end
    end

    return default_expression
end

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
---@param resource table
---@param aquilo_on_fulgora boolean
---@return nil
local function apply_guarded_resource_biome_mask(resource_name, resource, aquilo_on_fulgora)
    if not aquilo_on_fulgora and eon_resource_registry.aquilo_nauvis_fluid_resources[resource_name] then
        return
    end

    local nauvis_settings = get_planet_entity_settings("nauvis") or {}
    local gleba_settings = get_planet_entity_settings("gleba") or {}
    local vulcanus_settings = get_planet_entity_settings("vulcanus") or {}

    local default_expression = expression_for_autoplace(resource)
    if not default_expression then default_expression = "1" end

    local masked = {}

    if nauvis_settings[resource_name]
        and not eon_resource_registry.eon_added_vulcanus_resources[resource_name]
    then
        add_masked_expression(masked, default_expression, "eon_mask_nauvis_territory")
    end

    if gleba_settings[resource_name] then
        add_masked_expression(
            masked,
            guarded_resource_expression_for_planet(resource_name, "gleba", default_expression),
            "eon_mask_gleba_territory"
        )
    end

    if vulcanus_settings[resource_name] then
        add_masked_expression(
            masked,
            guarded_resource_expression_for_planet(resource_name, "vulcanus", default_expression),
            "eon_mask_vulcano_terrain"
        )
    end

    local probability_expression = combine_masked_expressions(masked)
    if probability_expression then
        resource.autoplace.probability_expression = probability_expression
    end

    if resource_name == "stone" and gleba_settings[resource_name] then
        local default_richness = richness_expression_for_autoplace(resource)
        local gleba_richness = get_planet_richness_expression("gleba", "stone")

        if probability_expression then
            set_or_extend_noise_expression(
                "eon_guarded_stone_probability",
                mask_off_ammonia_ocean(probability_expression)
            )
            set_nauvis_entity_property_expression("stone", "probability", "eon_guarded_stone_probability")
            resource.autoplace.probability_expression = "eon_guarded_stone_probability"
        end

        if default_richness and gleba_richness then
            local richness_expression = combine_masked_expressions({
                mask_expression(default_richness, "eon_mask_nauvis_territory"),
                mask_expression(gleba_richness, "eon_mask_gleba_territory")
            })

            if richness_expression then
                set_or_extend_noise_expression("eon_guarded_stone_richness", richness_expression)
                set_nauvis_entity_property_expression("stone", "richness", "eon_guarded_stone_richness")
                resource.autoplace.richness_expression = "eon_guarded_stone_richness"
            end
        elseif gleba_richness then
            local richness_expression = mask_expression(gleba_richness, "eon_mask_gleba_territory")

            set_or_extend_noise_expression("eon_guarded_stone_richness", richness_expression)
            set_nauvis_entity_property_expression("stone", "richness", "eon_guarded_stone_richness")
            resource.autoplace.richness_expression = "eon_guarded_stone_richness"
        end
    end

    if resource_name == "coal" and vulcanus_settings[resource_name] then
        local default_richness = richness_expression_for_autoplace(resource)
        local vulcanus_richness = get_planet_richness_expression("vulcanus", "coal")

        if probability_expression then
            set_or_extend_noise_expression(
                "eon_guarded_coal_probability",
                mask_off_ammonia_ocean(probability_expression)
            )
            set_nauvis_entity_property_expression("coal", "probability", "eon_guarded_coal_probability")
            resource.autoplace.probability_expression = "eon_guarded_coal_probability"
        end

        if default_richness and vulcanus_richness then
            local richness_expression = combine_masked_expressions({
                mask_expression(default_richness, "eon_mask_nauvis_territory"),
                mask_expression(vulcanus_richness, "eon_mask_vulcano_terrain")
            })

            if richness_expression then
                set_or_extend_noise_expression("eon_guarded_coal_richness", richness_expression)
                set_nauvis_entity_property_expression("coal", "richness", "eon_guarded_coal_richness")
                resource.autoplace.richness_expression = "eon_guarded_coal_richness"
            end
        elseif vulcanus_richness then
            local richness_expression = mask_expression(vulcanus_richness, "eon_mask_vulcano_terrain")

            set_or_extend_noise_expression("eon_guarded_coal_richness", richness_expression)
            set_nauvis_entity_property_expression("coal", "richness", "eon_guarded_coal_richness")
            resource.autoplace.richness_expression = "eon_guarded_coal_richness"
        end
    end
end

---@param config EonGuardedResourceBiomeAlignConfig
---@return nil
function guarded_resource_biome_policy.align(config)
    for resource_name, resource in pairs(data.raw.resource or {}) do
        if resource.autoplace then
            apply_guarded_resource_biome_mask(resource_name, resource, config.aquilo_on_fulgora)
        end
    end

    apply_simple_entity_biome_mask("iron-stromatolite", "eon_mask_gleba_territory")
    apply_simple_entity_biome_mask("copper-stromatolite", "eon_mask_gleba_territory")
end

return guarded_resource_biome_policy
