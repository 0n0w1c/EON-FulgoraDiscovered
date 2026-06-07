local data_util = require("data-util")
local biomes = require("lib.eon-biome-registry")

local eon_terrain_mask_api = {}

local aquilo_masks = biomes.get("aquilo").masks
local fulgora_masks = biomes.get("fulgora").masks
local gleba_masks = biomes.get("gleba").masks
local nauvis_masks = biomes.get("nauvis").masks
local vulcanus_masks = biomes.get("vulcanus").masks

---@param terrain table
---@param config table
---@return nil
function eon_terrain_mask_api.apply(terrain, config)
    local aquilo_resource_tile_mask = config.aquilo_resource_tile_mask
    local aquilo_decorative_mask = config.aquilo_decorative_mask
    local aquilo_snow_decorative_mask = config.aquilo_snow_decorative_mask

    local function set_masked_probability(prototype_name, prototype_type, mask_name)
        data.raw[prototype_type][prototype_name].autoplace.probability_expression = mask_name .. "(" ..
            data_util.generate_eon_name(prototype_name) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_nauvis_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = nauvis_masks.territory .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_nauvis_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = nauvis_masks.off_territory .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param prototype_name string Prototype name to restrict to guarded native-resource territory.
    ---@param prototype_type string Prototype table name, usually "resource".
    ---@return nil
    function terrain.mask_resource_territory(prototype_name, prototype_type)
        data.raw[prototype_type][prototype_name].autoplace.probability_expression = nauvis_masks.resource_territory ..
            "(" ..
            data_util.generate_eon_name(prototype_name) .. ")"
    end

    ---@param prototype_name string Prototype name to restrict to Aquilo territory.
    ---@param prototype_type string Prototype table name; resources also avoid invalid Aquilo resource tiles.
    ---@return nil
    function terrain.mask_aquilo_territory(prototype_name, prototype_type)
        local mask = prototype_type == "resource" and aquilo_resource_tile_mask or aquilo_masks.territory
        data.raw[prototype_type][prototype_name].autoplace.probability_expression = mask .. "(" ..
            data_util.generate_eon_name(prototype_name) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_aquilo_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = aquilo_masks.off_territory .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_aquilo_territory_on_fulgora(decorative, decorative_type)
        set_masked_probability(decorative, decorative_type, aquilo_masks.territory_on_fulgora)
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_aquilo_territory_on_fulgora(decorative, decorative_type)
        set_masked_probability(decorative, decorative_type, aquilo_masks.off_territory_on_fulgora)
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_fulgora_territory(decorative, decorative_type)
        set_masked_probability(decorative, decorative_type, fulgora_masks.territory)
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_fulgora_territory(decorative, decorative_type)
        set_masked_probability(decorative, decorative_type, fulgora_masks.off_territory)
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_fulgora_aquilo_territory(decorative, decorative_type)
        terrain.mask_aquilo_territory_on_fulgora(decorative, decorative_type)
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_fulgora_aquilo_territory(decorative, decorative_type)
        terrain.mask_off_aquilo_territory_on_fulgora(decorative, decorative_type)
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_ammonia_ocean(decorative, decorative_type)
        set_masked_probability(decorative, decorative_type, aquilo_masks.ammonia_ocean)
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
        set_masked_probability(decorative, decorative_type, aquilo_masks.off_ammonia_ocean)
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_gleba_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = gleba_masks.territory .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_gleba_territory(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = gleba_masks.off_territory .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_vulcano_coverage(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = vulcanus_masks.coverage .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_vulcano_coverage(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = vulcanus_masks.off_coverage .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_vulcano_terrain(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = vulcanus_masks.terrain .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end

    ---@param decorative string
    ---@param decorative_type string
    ---@return nil
    function terrain.mask_off_vulcano_terrain(decorative, decorative_type)
        data.raw[decorative_type][decorative].autoplace.probability_expression = vulcanus_masks.off_terrain .. "(" ..
            data_util.generate_eon_name(decorative) .. ")"
    end
end

return eon_terrain_mask_api
