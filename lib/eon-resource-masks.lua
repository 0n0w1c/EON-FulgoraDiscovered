local biomes = require("lib.eon-biome-registry")
local eon_resource_masks = {}

---Build resource mask helpers from startup-setting-derived resource mode values.
---@param mode_values table
---@return table
function eon_resource_masks.from_mode_values(mode_values)
    local aquilo_masks = biomes.get("aquilo").masks
    local vulcanus_masks = biomes.get("vulcanus").masks
    local eon_vulcanus_resource_off_aquilo_mask = mode_values.vulcanus_resource_off_aquilo_mask
    local eon_vulcanus_resource_off_ammonia_ocean_mask = mode_values.vulcanus_resource_off_ammonia_ocean_mask

    ---@param expression string
    ---@return string
    local function mask_off_ammonia_ocean(expression)
        return eon_vulcanus_resource_off_ammonia_ocean_mask .. "(" .. expression .. ")"
    end

    ---@param expression string
    ---@return string
    local function mask_off_aquilo_territory(expression)
        return eon_vulcanus_resource_off_aquilo_mask .. "(" .. expression .. ")"
    end

    ---@param expression string Resource probability expression to preserve outside Aquilo and block on invalid Aquilo resource tiles.
    ---@return string
    local function mask_off_aquilo_resource_tiles(expression)
        return aquilo_masks.off_resource_tiles .. "(" .. expression .. ")"
    end

    ---@param expression string
    ---@return string
    local function mask_vulcanus_terrain(expression)
        return vulcanus_masks.terrain .. "(" .. expression .. ")"
    end

    ---@param expression string
    ---@return string
    local function mask_vulcanus_resource_terrain(expression)
        return mask_off_aquilo_territory(mask_off_ammonia_ocean(mask_vulcanus_terrain(expression)))
    end

    ---@param expression string
    ---@return string
    local function mask_vulcanus_coverage(expression)
        return vulcanus_masks.coverage .. "(" .. expression .. ")"
    end

    return {
        mask_off_ammonia_ocean = mask_off_ammonia_ocean,
        mask_off_aquilo_territory = mask_off_aquilo_territory,
        mask_off_aquilo_resource_tiles = mask_off_aquilo_resource_tiles,
        mask_vulcanus_terrain = mask_vulcanus_terrain,
        mask_vulcanus_resource_terrain = mask_vulcanus_resource_terrain,
        mask_vulcanus_coverage = mask_vulcanus_coverage,
    }
end

return eon_resource_masks
