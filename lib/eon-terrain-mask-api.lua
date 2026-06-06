local data_util = require("data-util")

local eon_terrain_mask_api = {}

---@param terrain table
---@param config table
---@return nil
function eon_terrain_mask_api.apply(terrain, config)
    local aquilo_resource_tile_mask = config.aquilo_resource_tile_mask
    local aquilo_decorative_mask = config.aquilo_decorative_mask
    local aquilo_snow_decorative_mask = config.aquilo_snow_decorative_mask

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_nauvis_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_nauvis_territory(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_nauvis_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_nauvis_territory(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param prototype_name string Prototype name to restrict to guarded native-resource territory.
    ---@param prototype_type string Prototype table name, usually "resource".
    ---@return nil
    function terrain.mask_resource_territory(prototype_name, prototype_type)
        data.raw[prototype_type][prototype_name].autoplace.probability_expression = "eon_mask_resource_territory(" ..
            data_util.generate_eon_name(prototype_name) .. ")"
    end

    ---@param prototype_name string Prototype name to restrict to Aquilo territory.
    ---@param prototype_type string Prototype table name; resources also avoid invalid Aquilo resource tiles.
    ---@return nil
    function terrain.mask_aquilo_territory(prototype_name, prototype_type)
        local mask = prototype_type == "resource" and aquilo_resource_tile_mask or "eon_mask_aquilo_territory"
        data.raw[prototype_type][prototype_name].autoplace.probability_expression = mask .. "(" ..
            data_util.generate_eon_name(prototype_name) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_aquilo_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_aquilo_territory(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_fulgora_aquilo_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_fulgora_aquilo_territory(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_fulgora_aquilo_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_fulgora_aquilo_territory(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_ammonia_ocean(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_ammonia_ocean(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_aquilo_decorative_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = aquilo_decorative_mask .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_aquilo_snow_decorative_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = aquilo_snow_decorative_mask .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_ammonia_ocean(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_ammonia_ocean(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_gleba_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_gleba_territory(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_gleba_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_gleba_territory(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_vulcano_coverage(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_vulcano_coverage(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_vulcano_coverage(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_vulcano_coverage(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_vulcano_terrain(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_vulcano_terrain(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_vulcano_terrain(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_vulcano_terrain(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end
end

return eon_terrain_mask_api
