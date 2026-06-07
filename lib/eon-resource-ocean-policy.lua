local biomes = require("lib.eon-biome-registry")

local eon_resource_ocean_policy = {}

local aquilo_masks = biomes.get("aquilo").masks

---@param expression string
---@return boolean
local function should_wrap_probability_expression(expression)
    return type(expression) == "string"
        and expression ~= ""
        and not string.find(expression, aquilo_masks.off_ammonia_ocean .. "(", 1, true)
end

---@class EonResourceOceanMaskNauvisConfig
---@field nauvis_settings table|nil
---@field mask_off_ammonia_ocean fun(expression:string):string

---@param config EonResourceOceanMaskNauvisConfig
---@return nil
function eon_resource_ocean_policy.mask_nauvis_resource_probabilities(config)
    local nauvis_settings = config.nauvis_settings
    if not nauvis_settings then
        return
    end

    local mask_off_ammonia_ocean = config.mask_off_ammonia_ocean

    for resource_name, resource in pairs(data.raw.resource or {}) do
        if nauvis_settings[resource_name] and resource.autoplace then
            local expression = resource.autoplace.probability_expression

            if type(expression) == "string" and should_wrap_probability_expression(expression) then
                resource.autoplace.probability_expression = mask_off_ammonia_ocean(expression)
            end
        end
    end
end

return eon_resource_ocean_policy
