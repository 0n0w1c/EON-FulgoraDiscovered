local biomes = require("lib.eon-biome-registry")

local eon_terrain_expressions = {}

---@param aquilo_on_fulgora boolean
---@return table
function eon_terrain_expressions.values(aquilo_on_fulgora)
    local aquilo_masks = biomes.get("aquilo").masks
    local gleba_masks = biomes.get("gleba").masks
    local vulcanus_masks = biomes.get("vulcanus").masks

    local vulcanus_off_terrain = vulcanus_masks.off_terrain
    local aquilo_off_territory = aquilo_masks.off_territory
    local gleba_off_territory = gleba_masks.off_territory

    return {
        aquilo_north_bias_y_offset = aquilo_on_fulgora and 650 or -250,
        aquilo_exclusion_mask = aquilo_on_fulgora and "eon_identity" or vulcanus_off_terrain,
        ammonia_ocean_tile_mask = aquilo_masks.territory,
        ammonia_ocean_tile_expression = aquilo_on_fulgora and "eon_aquilo_ammonia_core" or "eon_aquilo_ammonia",
        aquilo_decorative_mask = aquilo_masks.decorative_territory,
        vulcanus_off_aquilo_mask = aquilo_on_fulgora and "eon_identity" or aquilo_off_territory,
        aquilo_snow_decorative_mask = aquilo_on_fulgora and "eon_identity" or aquilo_masks.snow_decorative_territory,
        nauvis_territory_expression = aquilo_on_fulgora
            and gleba_off_territory .. "(" .. vulcanus_off_terrain .. "(expression))"
            or aquilo_off_territory .. "(" .. gleba_off_territory .. "(" .. vulcanus_off_terrain .. "(expression)))",
        nauvis_cliffiness_expression = aquilo_on_fulgora
            and "(main_cliffiness >= cliff_cutoff) * 10"
            or aquilo_off_territory .. "((main_cliffiness >= cliff_cutoff) * 10)",
        fulgora_cliffiness_expression = aquilo_on_fulgora
            and aquilo_off_territory .. "(fulgora_cliffiness)"
            or "fulgora_cliffiness",
        gleba_region_expression =
            vulcanus_off_terrain ..
            "(if(gleba_noise + gleba_intermediate_noise + gleba_small_noise + moisture_nauvis + south_offset > threshold, 1, 0))",
        gleba_mask_threshold = -10,
        gleba_south_bias_y_offset = aquilo_on_fulgora and 1000 or 1500,
        gleba_continuous_cliffiness_expression = "clamp(quick_multioctave_noise{x = x,\z
                                                       y = y,\z
                                                       seed0 = map_seed,\z
                                                       seed1 = 456,\z
                                                       octaves = 2,\z
                                                       input_scale = 1/128,\z
                                                       output_scale = 1.5}, 0, 1)",
        vulcanus_cliffiness_expression = "clamp(quick_multioctave_noise{x = x,\z
                                                  y = y,\z
                                                  seed0 = map_seed,\z
                                                  seed1 = 123,\z
                                                  octaves = 4,\z
                                                  input_scale = 1/48,\z
                                                  output_scale = 1} * 1.4, 0, 1)",
        blended_cliffiness_expression = "if(eon_vulcanus_terrain,\z
                                          eon_vulcanus_cliffiness * 2,\z
                                          if(eon_gleba_mask,\z
                                             eon_gleba_continuous_cliffiness,\z
                                             cliffiness_nauvis * 0.8))",
        blended_cliff_elevation_expression = "if(eon_vulcanus_terrain,\z
                                               elevation * 1.5,\z
                                               if(eon_gleba_mask,\z
                                                  gleba_elevation * 0.2,\z
                                                  cliff_elevation_nauvis * 0.4))",
    }
end

return eon_terrain_expressions
