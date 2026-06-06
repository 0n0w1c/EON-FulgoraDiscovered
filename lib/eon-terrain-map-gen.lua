local eon_autoplace_policy = require("lib.eon-autoplace-policy")

local terrain_map_gen = {}

---@param planet_name string
---@param property_key string
---@param expression_name string
---@return nil
function terrain_map_gen.set_property_expression(planet_name, property_key, expression_name)
    local planet = data.raw.planet[planet_name]
    if not planet or not planet.map_gen_settings then return end

    planet.map_gen_settings.property_expression_names = planet.map_gen_settings.property_expression_names or {}
    planet.map_gen_settings.property_expression_names[property_key] = expression_name
end

---@param planet_name string
---@param entity_name string
---@param property_name string
---@param expression_name string
---@return nil
function terrain_map_gen.set_entity_property_expression(planet_name, entity_name, property_name, expression_name)
    terrain_map_gen.set_property_expression(planet_name, "entity:" .. entity_name .. ":" .. property_name,
        expression_name)
end

---@param planet_name string
---@param decorative_name string
---@param expression_name string
---@return nil
function terrain_map_gen.set_decorative_probability_expression(planet_name, decorative_name, expression_name)
    terrain_map_gen.set_property_expression(planet_name, "decorative:" .. decorative_name .. ":probability",
        expression_name)
end

---@param map_gen any
---@param controls string[]|table
---@return nil
function terrain_map_gen.enable_autoplace_controls(map_gen, controls)
    eon_autoplace_policy.set_map_gen_autoplace_controls(map_gen, controls)
end

---@param map_gen any
---@param controls string[]|table
---@return nil
function terrain_map_gen.disable_autoplace_controls(map_gen, controls)
    eon_autoplace_policy.set_map_gen_autoplace_controls(map_gen, controls, false)
end

---@param planet_name string
---@param resource_name string
---@param property_name string
---@param expression any
---@return nil
function terrain_map_gen.set_resource_property_expression_if_string(
    planet_name,
    resource_name,
    property_name,
    expression
)
    if type(expression) ~= "string" then return end

    terrain_map_gen.set_entity_property_expression(
        planet_name,
        resource_name,
        property_name,
        expression
    )
end

return terrain_map_gen
