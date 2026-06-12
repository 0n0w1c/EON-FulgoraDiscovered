local eon_mode = require("lib.eon-mode")
local eon_volcano_registry = require("lib.eon-volcano-registry")
local eon_terrain_expressions = require("lib.eon-terrain-expressions")
local eon_terrain_mask_api = require("lib.eon-terrain-mask-api")
local eon_nauvis_cliff_settings = require("lib.eon-nauvis-cliff-settings")
local eon_nauvis_aquilo_fluids = require("lib.eon-nauvis-aquilo-fluid-resources")
local eon_fulgora_aquilo_resources = require("lib.eon-fulgora-aquilo-resources")
local eon_vulcanus_terrain_setup = require("lib.eon-vulcanus-terrain-setup")
local eon_gleba_terrain_setup = require("lib.eon-gleba-terrain-setup")
local eon_aquilo_terrain_setup = require("lib.eon-aquilo-terrain-setup")
local eon_aquilo_map_gen_setup = require("lib.eon-aquilo-map-gen-setup")
local eon_aquilo_terrain_mask_setup = require("lib.eon-aquilo-terrain-mask-setup")
local eon_nauvis_terrain_setup = require("lib.eon-nauvis-terrain-setup")
local biomes = require("lib.eon-biome-registry")

local eon_terrain_setup = {}

---@param terrain table Terrain masking API populated during data-stage setup.
---@return nil
function eon_terrain_setup.apply(terrain)
    local eon_aquilo_on_fulgora = eon_mode.aquilo_on_fulgora
    local eon_aquilo_planet_name = eon_mode.aquilo_surface
    local eon_guarded_resources_enabled = eon_mode.guarded_resources

    local eon_aquilo_resource_tile_mask = biomes.get("aquilo").masks.resource_tiles
    local eon_mask_resource_tiles = eon_aquilo_terrain_mask_setup.mask_resource_tiles

    local eon_terrain_expression_values = eon_terrain_expressions.values(eon_aquilo_on_fulgora)

    local eon_aquilo_north_bias_y_offset = eon_terrain_expression_values.aquilo_north_bias_y_offset
    local eon_aquilo_core_boundary_relative_y = eon_terrain_expression_values.aquilo_core_boundary_relative_y
    local eon_aquilo_fulgora_core_inset = eon_terrain_expression_values.aquilo_fulgora_core_inset
    local eon_aquilo_exclusion_mask = eon_terrain_expression_values.aquilo_exclusion_mask
    local eon_ammonia_ocean_tile_expression = eon_terrain_expression_values.ammonia_ocean_tile_expression
    local eon_aquilo_decorative_mask = eon_terrain_expression_values.aquilo_decorative_mask
    local eon_vulcanus_off_aquilo_mask = eon_terrain_expression_values.vulcanus_off_aquilo_mask
    local eon_aquilo_snow_decorative_mask = eon_terrain_expression_values.aquilo_snow_decorative_mask
    local eon_nauvis_territory_expression = eon_terrain_expression_values.nauvis_territory_expression
    local eon_nauvis_cliffiness_expression = eon_terrain_expression_values.nauvis_cliffiness_expression
    local eon_fulgora_cliffiness_expression = eon_terrain_expression_values.fulgora_cliffiness_expression
    local eon_gleba_region_expression = eon_terrain_expression_values.gleba_region_expression
    local eon_gleba_mask_threshold = eon_terrain_expression_values.gleba_mask_threshold
    local eon_gleba_south_bias_y_offset = eon_terrain_expression_values.gleba_south_bias_y_offset
    local eon_gleba_south_core_y_offset = eon_terrain_expression_values.gleba_south_core_y_offset
    local eon_gleba_continuous_cliffiness_expression =
        eon_terrain_expression_values.gleba_continuous_cliffiness_expression
    local eon_vulcanus_cliffiness_expression = eon_terrain_expression_values.vulcanus_cliffiness_expression
    local eon_blended_cliffiness_expression = eon_terrain_expression_values.blended_cliffiness_expression
    local eon_blended_cliff_elevation_expression = eon_terrain_expression_values.blended_cliff_elevation_expression

    eon_terrain_mask_api.apply(terrain, {
        aquilo_resource_tile_mask = eon_aquilo_resource_tile_mask,
        aquilo_decorative_mask = eon_aquilo_decorative_mask,
        aquilo_snow_decorative_mask = eon_aquilo_snow_decorative_mask,
    })

    eon_nauvis_terrain_setup.apply({
        nauvis_territory_expression = eon_nauvis_territory_expression,
        nauvis_cliffiness_expression = eon_nauvis_cliffiness_expression,
        gleba_continuous_cliffiness_expression = eon_gleba_continuous_cliffiness_expression,
        vulcanus_cliffiness_expression = eon_vulcanus_cliffiness_expression,
        blended_cliffiness_expression = eon_blended_cliffiness_expression,
        blended_cliff_elevation_expression = eon_blended_cliff_elevation_expression,
        mask_native_tiles_off_aquilo = not eon_aquilo_on_fulgora,
    })
    eon_nauvis_cliff_settings.apply_blended_cliff_settings()

    eon_aquilo_map_gen_setup.apply({
        aquilo_on_fulgora = eon_aquilo_on_fulgora,
        aquilo_planet_name = eon_aquilo_planet_name,
    })

    if eon_aquilo_on_fulgora then
        eon_fulgora_aquilo_resources.apply({
            mask_resource_tiles = eon_mask_resource_tiles,
        })
    end

    eon_aquilo_terrain_mask_setup.apply({
        aquilo_on_fulgora = eon_aquilo_on_fulgora,
        guarded_resources_enabled = eon_guarded_resources_enabled,
    })

    if not eon_aquilo_on_fulgora then
        eon_nauvis_aquilo_fluids.apply({
            guarded_resources_enabled = eon_guarded_resources_enabled,
            snow_decorative_mask = eon_aquilo_snow_decorative_mask,
            mask_resource_tiles = eon_mask_resource_tiles,
        })
    end

    eon_aquilo_terrain_setup.apply({
        aquilo_on_fulgora = eon_aquilo_on_fulgora,
        ammonia_ocean_tile_expression = eon_ammonia_ocean_tile_expression,
        aquilo_exclusion_mask = eon_aquilo_exclusion_mask,
        aquilo_north_bias_y_offset = eon_aquilo_north_bias_y_offset,
        aquilo_core_boundary_relative_y = eon_aquilo_core_boundary_relative_y,
        aquilo_fulgora_core_inset = eon_aquilo_fulgora_core_inset,
        fulgora_cliffiness_expression = eon_fulgora_cliffiness_expression,
    })

    eon_gleba_terrain_setup.apply({
        gleba_mask_threshold = eon_gleba_mask_threshold,
        gleba_region_expression = eon_gleba_region_expression,
        gleba_south_bias_y_offset = eon_gleba_south_bias_y_offset,
        gleba_south_core_y_offset = eon_gleba_south_core_y_offset,
    })

    eon_vulcanus_terrain_setup.apply({
        aquilo_on_fulgora = eon_aquilo_on_fulgora,
        vulcanus_off_aquilo_mask = eon_vulcanus_off_aquilo_mask,
    })

    data:extend(eon_volcano_registry.noise_prototypes(eon_aquilo_on_fulgora))
end

return eon_terrain_setup
