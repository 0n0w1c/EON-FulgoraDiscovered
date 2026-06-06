local eon_autoplace_policy = require("lib.eon-autoplace-policy")

---@class EonDirectResourceExpressionEntry
---@field resource_name string
---@field probability string
---@field richness string|nil

local direct_resource_expression_policy = {}

---@param entity_name string
---@param property_name string
---@param expression_name string
---@return nil
local function set_nauvis_entity_property_expression(entity_name, property_name, expression_name)
    eon_autoplace_policy.set_planet_entity_property_expression("nauvis", entity_name, property_name, expression_name)
end

---@param entry EonDirectResourceExpressionEntry
---@return nil
function direct_resource_expression_policy.apply_entry(entry)
    set_nauvis_entity_property_expression(entry.resource_name, "probability", entry.probability)

    local resource = data.raw.resource and data.raw.resource[entry.resource_name]
    if resource and resource.autoplace then
        resource.autoplace.probability_expression = entry.probability
    end

    if entry.richness then
        set_nauvis_entity_property_expression(entry.resource_name, "richness", entry.richness)
        if resource and resource.autoplace then
            resource.autoplace.richness_expression = entry.richness
        end
    end
end

---@param entries EonDirectResourceExpressionEntry[]
---@return nil
function direct_resource_expression_policy.apply_entries(entries)
    for _, entry in ipairs(entries or {}) do
        direct_resource_expression_policy.apply_entry(entry)
    end
end

return direct_resource_expression_policy
