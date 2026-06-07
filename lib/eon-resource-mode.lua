local biomes = require("lib.eon-biome-registry")
---@class EonResourceModeConfig
---@field aquilo_on_fulgora boolean
---@field guarded_resources_enabled boolean

---@class EonResourceModeValues
---@field unrestricted_vulcanus_resource_mode boolean
---@field mask_vulcanus_resources_off_aquilo boolean
---@field vulcanus_resource_off_aquilo_mask string
---@field mask_vulcanus_resources_off_ammonia_ocean boolean
---@field vulcanus_resource_off_ammonia_ocean_mask string
---@field vulcanus_resource_richness_expression string
---@field vulcanus_tungsten_richness_expression string

local resource_mode = {}

---@param config EonResourceModeConfig
---@return EonResourceModeValues
function resource_mode.values(config)
    local aquilo_masks = biomes.get("aquilo").masks
    local eon_aquilo_on_fulgora = config.aquilo_on_fulgora == true
    local guarded_resources_enabled = config.guarded_resources_enabled == true

    local eon_unrestricted_vulcanus_resource_mode = eon_aquilo_on_fulgora
        and not guarded_resources_enabled

    local mask_vulcanus_resources_off_aquilo = guarded_resources_enabled and not eon_aquilo_on_fulgora

    local eon_vulcanus_resource_off_aquilo_mask = mask_vulcanus_resources_off_aquilo
        and aquilo_masks.off_territory
        or "eon_identity"

    local mask_vulcanus_resources_off_ammonia_ocean = guarded_resources_enabled and not eon_aquilo_on_fulgora

    local eon_vulcanus_resource_off_ammonia_ocean_mask = mask_vulcanus_resources_off_ammonia_ocean
        and aquilo_masks.off_ammonia_ocean
        or "eon_identity"

    local eon_vulcanus_resource_richness_expression = mask_vulcanus_resources_off_aquilo
        and "if(eon_aquilo_mask, 0, if(eon_vulcanus_terrain, %s, 0))"
        or "if(eon_vulcanus_terrain, %s, 0)"

    local eon_vulcanus_tungsten_richness_expression = mask_vulcanus_resources_off_aquilo
        and "if(eon_aquilo_mask, 0, %s)"
        or "%s"

    return {
        unrestricted_vulcanus_resource_mode = eon_unrestricted_vulcanus_resource_mode,
        mask_vulcanus_resources_off_aquilo = mask_vulcanus_resources_off_aquilo,
        vulcanus_resource_off_aquilo_mask = eon_vulcanus_resource_off_aquilo_mask,
        mask_vulcanus_resources_off_ammonia_ocean = mask_vulcanus_resources_off_ammonia_ocean,
        vulcanus_resource_off_ammonia_ocean_mask = eon_vulcanus_resource_off_ammonia_ocean_mask,
        vulcanus_resource_richness_expression = eon_vulcanus_resource_richness_expression,
        vulcanus_tungsten_richness_expression = eon_vulcanus_tungsten_richness_expression,
    }
end

return resource_mode
