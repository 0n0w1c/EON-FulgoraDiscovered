local eon_fulgora_registry = require("lib.eon-fulgora-registry")

local eon_aquilo_terrain_setup = {}

function eon_aquilo_terrain_setup.apply(parameters)
    local eon_aquilo_on_fulgora = parameters.aquilo_on_fulgora
    local eon_ammonia_ocean_tile_mask = parameters.ammonia_ocean_tile_mask
    local eon_ammonia_ocean_tile_expression = parameters.ammonia_ocean_tile_expression
    local eon_aquilo_exclusion_mask = parameters.aquilo_exclusion_mask
    local eon_aquilo_north_bias_y_offset = parameters.aquilo_north_bias_y_offset
    local eon_fulgora_cliffiness_expression = parameters.fulgora_cliffiness_expression

data.raw.tile["ammoniacal-ocean"].autoplace.probability_expression =
    eon_ammonia_ocean_tile_mask .. "(" .. eon_ammonia_ocean_tile_expression .. " + 0.01 * (aux - 0.5))"
data.raw.tile["ammoniacal-ocean-2"].autoplace.probability_expression =
    eon_ammonia_ocean_tile_mask .. "(" .. eon_ammonia_ocean_tile_expression .. " - 0.01 * (aux - 0.5))"

data.raw.tile["snow-flat"].autoplace.probability_expression = "eon_mask_aquilo_territory(eon_aquilo_land)"
data.raw.tile["ice-rough"].autoplace.probability_expression =
"eon_mask_aquilo_territory(eon_aquilo_base(eon_aquilo_ammonia_depth + 1.5, 200))"
data.raw.tile["ice-smooth"].autoplace.probability_expression =
"eon_mask_aquilo_territory(max(eon_aquilo_base(eon_aquilo_ammonia_depth + 1, 200), eon_aquilo_fulgora_ammonia_transition))"
data.raw.tile["brash-ice"].autoplace.probability_expression = eon_aquilo_on_fulgora
    and "eon_mask_aquilo_territory(eon_aquilo_base(eon_aquilo_ammonia_depth + 0.5, 200))"
    or
    "eon_mask_aquilo_territory(max(eon_aquilo_base(eon_aquilo_ammonia_depth + 0.5, 200), eon_aquilo_nauvis_ammonia_ocean_edge))"

data:extend({
    {
        type = "autoplace-control",
        name = "ammonia_ocean",
        localised_description = nil,
        order = "c-z-cb",
        category = "terrain",
        hidden = false,
        can_be_disabled = false,
    },
})

eon_fulgora_registry.ensure_cliff_control()

data:extend({
    {
        type = "noise-expression",
        name = "eon_aquilo_mask",
        expression = "eon_aquilo_land > -1",
    },
    {
        type = "noise-expression",
        name = "eon_ammonia_mask",
        expression = "eon_aquilo_ammonia > -1",
    },
    {
        type = "noise-expression",
        name = "eon_fulgora_aquilo_boundary",
        expression =
        "100 + 45 * sin(x / 260) + 25 * sin(x / 95 + 1.7) + 15 * sin(x / 38 + 0.4) + 45 * multioctave_noise{x = x, y = 0, persistence = 0.62, seed0 = map_seed, seed1 = 912342, octaves = 5, input_scale = 1 / 512, output_scale = 1, offset_x = 0, offset_y = 0}",
    },
    {
        type = "noise-expression",
        name = "eon_fulgora_aquilo_territory_mask",
        expression = "y < eon_fulgora_aquilo_boundary",
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_land",
        expression = eon_aquilo_exclusion_mask .. "(eon_aquilo_base(eon_aquilo_max_elevation, 100))"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_max_elevation",
        expression = "-1"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_ammonia",
        expression = eon_aquilo_exclusion_mask .. "(eon_aquilo_base(eon_aquilo_ammonia_depth, 200))"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_ammonia_core",
        expression = eon_aquilo_exclusion_mask .. "(eon_aquilo_base(eon_aquilo_ammonia_depth - 2, 200))"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_brash_ice_region",
        expression = eon_aquilo_exclusion_mask .. "(eon_aquilo_base(eon_aquilo_ammonia_depth + 0.5, 200))"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_resource_placeable_land",
        expression =
        "if(eon_aquilo_land > 0, if(eon_aquilo_ammonia > -1, false, if(eon_aquilo_brash_ice_region > -1, false, true)), false)"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_nauvis_ammonia_ocean_edge",
        expression = eon_aquilo_on_fulgora
            and "-inf"
            or "if(eon_aquilo_ammonia > -1, if(eon_aquilo_ammonia_core > 0, -inf, 250), -inf)"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_fulgora_ammonia_transition",
        expression = "if(eon_aquilo_ammonia > -1, if(eon_aquilo_ammonia_core > 0, -inf, 250), -inf)"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_fulgora_ocean_edge",
        expression = eon_aquilo_on_fulgora
            and "eon_aquilo_base(eon_aquilo_ammonia_depth + 1, 200) > -1"
            or "false"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_fulgora_snow_decorative_territory",
        expression = eon_aquilo_on_fulgora
            and "eon_aquilo_base(eon_aquilo_max_elevation + 2, 200) > -1"
            or "false"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_ammonia_depth",
        expression = "eon_aquilo_max_elevation - 4"
    },
    {
        type = "noise-expression",
        name = "eon_elevation_aquilo",
        expression =
        "if(wlc_elevation > eon_factorio_base_aquilo_elevation, wlc_elevation, min(eon_factorio_base_aquilo_elevation, -1.1))",
        local_expressions =
        {
            elevation_magnitude = 20,
            wlc_amplitude = 2,
            ammonia_level = "2 * pow(log2(1 + (control:ammonia_ocean:size * 3)), 1.3)",
            wlc_elevation = "max(aquilo_main - ammonia_level * wlc_amplitude, starting_island, north_bias)",
            aquilo_main =
            "elevation_magnitude * (0.25 * eon_aquilo_detail + 3 * eon_aquilo_macro * starting_macro_multiplier)",
            starting_island = "aquilo_main + elevation_magnitude * (2.5 - distance * segmentation_multiplier / 200)",
            starting_macro_multiplier = "clamp(distance * eon_aquilo_segmentation_multiplier / 2000, 0, 1)",
            north_bias = "aquilo_main + elevation_magnitude * (2.4 + (y - " ..
                eon_aquilo_north_bias_y_offset .. ") * segmentation_multiplier / 380)",
        }
    },
    {
        type = "noise-expression",
        name = "eon_factorio_base_aquilo_elevation",
        expression = "lerp(blended, maxed, 0.4)",
        local_expressions = {
            maxed               = "max(formation_clumped, formation_broken)",
            blended             = "lerp(formation_clumped, formation_broken, 0.4)",
            formation_clumped   = "-25\z
                          + 12 * max(aquilo_island_peaks, random_island_peaks)\z
                          + 15 * tri_crack",
            formation_broken    = "-20\z
                          + 8 * max(aquilo_island_peaks * 1.1, min(0., random_island_peaks - 0.2))\z
                          + 13 * (pow(voronoi_large * max(0, voronoi_large_cell * 1.2 - 0.2) + 0.5 * voronoi_small * max(0, aux + 0.1), 0.5))",
            random_island_peaks = "abs(amplitude_corrected_multioctave_noise{x = x,\z
                                                                  y = y,\z
                                                                  seed0 = map_seed,\z
                                                                  seed1 = 1000,\z
                                                                  input_scale = segmentation_mult / 1.2,\z
                                                                  offset_x = -10000,\z
                                                                  octaves = 6,\z
                                                                  persistence = 0.8,\z
                                                                  amplitude = 1})",
            voronoi_large       = "voronoi_facet_noise{   x = x + aquilo_wobble_x * 2,\z
                                              y = y + aquilo_wobble_y * 2,\z
                                              seed0 = map_seed,\z
                                              seed1 = 'aquilo-cracks',\z
                                              grid_size = 24,\z
                                              distance_type = 'euclidean',\z
                                              jitter = 1}",
            voronoi_large_cell  = "voronoi_cell_id{  x = x + aquilo_wobble_x * 2,\z
                                              y = y + aquilo_wobble_y * 2,\z
                                              seed0 = map_seed,\z
                                              seed1 = 'aquilo-cracks',\z
                                              grid_size = 24,\z
                                              distance_type = 'euclidean',\z
                                              jitter = 1}",
            voronoi_small       = "voronoi_facet_noise{   x = x + aquilo_wobble_x * 2,\z
                                              y = y + aquilo_wobble_y * 2,\z
                                              seed0 = map_seed,\z
                                              seed1 = 'aquilo-cracks',\z
                                              grid_size = 10,\z
                                              distance_type = 'euclidean',\z
                                              jitter = 1}",
            tri_crack           = "min(aquilo_simple_billows{seed1 = 2000, octaves = 3, input_scale = segmentation_mult / 1.5},\z
                       aquilo_simple_billows{seed1 = 3000, octaves = 3, input_scale = segmentation_mult / 1.2},\z
                       aquilo_simple_billows{seed1 = 4000, octaves = 3, input_scale = segmentation_mult})",
            segmentation_mult   = "eon_aquilo_segmentation_multiplier / 25",
        }
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_detail",
        expression = "variable_persistence_multioctave_noise{x = x,\z
                                                         y = y,\z
                                                         seed0 = map_seed + 1,\z
                                                         seed1 = 600,\z
                                                         input_scale = eon_aquilo_segmentation_multiplier / 14,\z
                                                         output_scale = 0.03,\z
                                                         offset_x = 10000 / eon_aquilo_segmentation_multiplier,\z
                                                         octaves = 5,\z
                                                         persistence = eon_aquilo_persistance}"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_segmentation_multiplier",
        expression = "0.5 * control:ammonia_ocean:frequency"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_persistance",
        expression = "clamp(amplitude_corrected_multioctave_noise{x = x,\z
                                                              y = y,\z
                                                              seed0 = map_seed + 1,\z
                                                              seed1 = 500,\z
                                                              octaves = 5,\z
                                                              input_scale = eon_aquilo_segmentation_multiplier / 2,\z
                                                              offset_x = 10000 / eon_aquilo_segmentation_multiplier,\z
                                                              persistence = 0.7,\z
                                                              amplitude = 0.5} + 0.55,\z
                        0.5, 0.65)"
    },
    {
        type = "noise-expression",
        name = "eon_aquilo_macro",
        expression = "multioctave_noise{x = x,\z
                                    y = y,\z
                                    persistence = 0.6,\z
                                    seed0 = map_seed + 1,\z
                                    seed1 = 1000,\z
                                    octaves = 2,\z
                                    input_scale = eon_aquilo_segmentation_multiplier / 1600}\z
                  * max(0, multioctave_noise{x = x,\z
                                    y = y,\z
                                    persistence = 0.6,\z
                                    seed0 = map_seed + 1,\z
                                    seed1 = 1100,\z
                                    octaves = 1,\z
                                    input_scale = eon_aquilo_segmentation_multiplier / 1600})",
    },
    {
        type = "noise-function",
        name = "eon_aquilo_base",
        parameters = { "max_elevation", "influence" },
        expression =
        "if(max_elevation >= eon_elevation_aquilo, influence * min(max_elevation - eon_elevation_aquilo, 1), -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_aquilo_territory",
        parameters = { "expression" },
        expression = "if(eon_aquilo_mask, expression, -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_off_aquilo_territory",
        parameters = { "expression" },
        expression = "if(eon_aquilo_mask, -inf, expression)"
    },
    {
        type = "noise-function",
        name = "eon_mask_aquilo_resource_tiles",
        parameters = { "expression" },
        expression = "if(eon_aquilo_resource_placeable_land, expression, -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_off_aquilo_resource_tiles",
        parameters = { "expression" },
        expression = "if(eon_aquilo_mask, if(eon_aquilo_resource_placeable_land, expression, -inf), expression)"
    },
    {
        type = "noise-function",
        name = "eon_mask_ammonia_ocean",
        parameters = { "expression" },
        expression = "if(eon_ammonia_mask, expression, -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_fulgora_aquilo_snow_decorative_territory",
        parameters = { "expression" },
        expression = "if(eon_aquilo_fulgora_snow_decorative_territory, expression, -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_fulgora_ammonia_ocean_core",
        parameters = { "expression" },
        expression = "if(eon_aquilo_ammonia_core > 0, expression, -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_off_ammonia_ocean",
        parameters = { "expression" },
        expression = "if(eon_ammonia_mask, -inf, expression)"
    },
    {
        type = "noise-function",
        name = "eon_mask_off_aquilo_ocean_edge",
        parameters = { "expression" },
        expression = "if(eon_aquilo_fulgora_ocean_edge, -inf, expression)"
    },
    {
        type = "noise-function",
        name = "eon_mask_off_fulgora_oil_ocean",
        parameters = { "expression" },
        expression =
        "if(max(50 * fulgora_oil_mask * water_base(fulgora_coastline, 1000), 100 * fulgora_oil_mask * water_base(fulgora_coastline - 50 - fulgora_coastline_drop / 2, 2000)) > 0, -inf, expression)"
    },
    {
        type = "noise-expression",
        name = "eon_fulgora_cliffiness_off_aquilo",
        expression = eon_fulgora_cliffiness_expression
    },
})

end

return eon_aquilo_terrain_setup
