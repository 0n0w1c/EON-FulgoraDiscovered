local eon_resource_masks = {}

---Build resource mask helpers from startup-setting-derived resource mode values.
---@param mode_values table
---@return table
function eon_resource_masks.from_mode_values(mode_values)
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
        return "eon_mask_off_aquilo_resource_tiles(" .. expression .. ")"
    end

    ---@param expression string
    ---@return string
    local function mask_vulcanus_terrain(expression)
        return "eon_mask_vulcano_terrain(" .. expression .. ")"
    end

    ---@param expression string
    ---@return string
    local function mask_vulcanus_resource_terrain(expression)
        return mask_off_aquilo_territory(mask_off_ammonia_ocean(mask_vulcanus_terrain(expression)))
    end

    ---@param expression string
    ---@return string
    local function mask_vulcanus_coverage(expression)
        return "eon_mask_vulcano_coverage(" .. expression .. ")"
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
