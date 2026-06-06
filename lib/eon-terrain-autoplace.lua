local eon_autoplace_policy = require("lib.eon-autoplace-policy")

local terrain_autoplace = {}

---@param expression string|nil
---@param wrapper string
---@return boolean
function terrain_autoplace.expression_has_wrapper(expression, wrapper)
    return type(expression) == "string"
        and string.find(expression, wrapper .. "%(", 1, false) ~= nil
end

---@param prototype table?
---@param wrapper string
---@return nil
function terrain_autoplace.wrap_probability_expression(prototype, wrapper)
    if not prototype or not prototype.autoplace then return end
    local expression = prototype.autoplace.probability_expression
    if type(expression) == "string" and expression ~= "" then
        if not terrain_autoplace.expression_has_wrapper(expression, wrapper) then
            prototype.autoplace.probability_expression = wrapper .. "(" .. expression .. ")"
        end
    end
end

---@param prototype_type string
---@param prototype_name string
---@param wrapper string
---@return nil
function terrain_autoplace.wrap_current_probability_expression(prototype_type, prototype_name, wrapper)
    local prototypes = data.raw[prototype_type]
    local prototype = prototypes and prototypes[prototype_name]
    terrain_autoplace.wrap_probability_expression(prototype, wrapper)
end

---@param entity_name string
---@return table? prototype Prototype with an autoplace probability expression, when one exists.
function terrain_autoplace.entity_prototype(entity_name)
    for _, prototype_type in pairs({ "resource", "simple-entity", "lightning-attractor" }) do
        local prototypes = data.raw[prototype_type]
        local prototype = prototypes and prototypes[entity_name]
        if prototype and prototype.autoplace then
            return prototype
        end
    end

    return nil
end

---@param prototype_type any
---@param prototype_name string
---@param tile_names string[]
---@return nil
function terrain_autoplace.restrict_to_tiles(prototype_type, prototype_name, tile_names)
    eon_autoplace_policy.restrict_to_tiles(prototype_type, prototype_name, tile_names)
end

---@param prototype_type any
---@param prototype_name string
---@param tile_names string[]
---@return nil
function terrain_autoplace.extend_tile_restriction(prototype_type, prototype_name, tile_names)
    eon_autoplace_policy.extend_tile_restriction(prototype_type, prototype_name, tile_names)
end

return terrain_autoplace
