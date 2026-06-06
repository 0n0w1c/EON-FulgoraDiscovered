local eon_volcano_registry = {}

local function eon_vulcanus_coverage_expression(aquilo_on_fulgora)
    return aquilo_on_fulgora
        and "eon_vulcanus_region(0)"
        or
        "max(eon_updated_volcanic_folds, eon_lava_mountains_range, eon_lava_hot_mountains_range, eon_volcano_cracks_warm_range) > 0"
end

local function eon_vulcanus_terrain_expression(aquilo_on_fulgora)
    return aquilo_on_fulgora
        and "eon_vulcanus_region(0)"
        or "max(eon_vulcano_coverage, eon_updated_volcanic_folds_flat) > 0"
end

local eon_vulcanus_tree_on_nauvis_expression =
    "min(10 * (vulcanus_ashlands_biome - 0.75), " ..
    "4 * (-1.5 + 1.5 * vulcanus_moisture + 0.5 * (vulcanus_moisture > 0.9) - " ..
    "0.5 * vulcanus_aux + 0.5 * vulcanus_decorative_knockout))"

---@param aquilo_on_fulgora boolean
---@return table[]
function eon_volcano_registry.noise_prototypes(aquilo_on_fulgora)
    return {
        {
            type = "noise-expression",
            name = "eon_vulcanus_ashlands_start",
            expression = "4 * starting_spot_at_angle{angle = vulcanus_ashlands_angle,\z
                                             distance = 170 * eon_starting_radius,\z
                                             radius = 740 * eon_starting_radius,\z
                                             x_distortion = 0.1 * eon_starting_radius * (vulcanus_wobble_x + vulcanus_wobble_large_x + vulcanus_wobble_huge_x),\z
                                             y_distortion = 0.1 * eon_starting_radius * (vulcanus_wobble_y + vulcanus_wobble_large_y + vulcanus_wobble_huge_y)}"
        },
        {
            type = "noise-expression",
            name = "eon_vulcanus_basalts_start",
            expression = "2 * starting_spot_at_angle{angle = vulcanus_basalts_angle,\z
                                             distance = 180 * eon_starting_radius,\z
                                             radius = 760 * eon_starting_radius,\z
                                             x_distortion = 0.1 * eon_starting_radius * (vulcanus_wobble_x + vulcanus_wobble_large_x + vulcanus_wobble_huge_x),\z
                                             y_distortion = 0.1 * eon_starting_radius * (vulcanus_wobble_y + vulcanus_wobble_large_y + vulcanus_wobble_huge_y)}"
        },
        {
            type = "noise-expression",
            name = "eon_vulcanus_mountains_start",
            expression = "2 * starting_spot_at_angle{angle = vulcanus_mountains_angle,\z
                                             distance = 190 * eon_starting_radius,\z
                                             radius = 780 * eon_starting_radius,\z
                                             x_distortion = 0.05 * eon_starting_radius * (vulcanus_wobble_x + vulcanus_wobble_large_x + vulcanus_wobble_huge_x),\z
                                             y_distortion = 0.05 * eon_starting_radius * (vulcanus_wobble_y + vulcanus_wobble_large_y + vulcanus_wobble_huge_y)}"
        },
        {
            type = "noise-expression",
            name = "eon_mountain_volcano_spots",
            expression = "raw_spots - starting_protector",
            local_expressions =
            {
                starting_protector =
                "clamp(starting_spot_at_angle{ angle = vulcanus_mountains_angle + 180 * vulcanus_starting_direction,\z
                                                          distance = (400 * vulcanus_starting_area_radius) / 2,\z
                                                          radius = 800 * vulcanus_starting_area_radius,\z
                                                          x_distortion = vulcanus_wobble_x/2 + vulcanus_wobble_large_x/12 + vulcanus_wobble_huge_x/80,\z
                                                          y_distortion = vulcanus_wobble_y/2 + vulcanus_wobble_large_y/12 + vulcanus_wobble_huge_y/80}, 0, 1)",
                raw_spots =
                "spot_noise{x = x + vulcanus_wobble_x/2 + vulcanus_wobble_large_x/12 + vulcanus_wobble_huge_x/80,\z
                              y = y + vulcanus_wobble_y/2 + vulcanus_wobble_large_y/12 + vulcanus_wobble_huge_y/80,\z
                              seed0 = map_seed,\z
                              seed1 = 1,\z
                              candidate_spot_count = 1,\z
                              suggested_minimum_candidate_point_spacing = volcano_spot_spacing,\z
                              skip_span = 1,\z
                              skip_offset = 0,\z
                              region_size = 256*density_multiplier,\z
                              density_expression = volcano_area * control:vulcanus_volcanism:frequency,\z
                              spot_quantity_expression = volcano_spot_radius * volcano_spot_radius,\z
                              spot_radius_expression = volcano_spot_radius,\z
                              hard_region_target_quantity = 0,\z
                              spot_favorability_expression = volcano_area,\z
                              basement_value = 0,\z
                              maximum_spot_basement_radius = volcano_spot_radius}",
                volcano_area = "lerp(vulcanus_mountains_biome_full_pre_volcano, 0, vulcanus_starting_area)",
                volcano_spot_radius = "640 * sqrt(control:vulcanus_volcanism:size)",
                volcano_spot_spacing = "2400 / sqrt(control:vulcanus_volcanism:frequency)",
                density_multiplier = "4 / sqrt(control:vulcanus_volcanism:frequency)"
            }
        },
        {
            type = "noise-expression",
            name = "eon_mountain_lava_spots",
            expression =
            "clamp(vulcanus_threshold(eon_mountain_volcano_spots * 1.95 - 0.95, 0.4 * vulcanus_threshold(clamp(vulcanus_plasma(17453, 0.2, 0.4, 10, 20) / 20, 0, 1), 3.5)), 0, 1)"
        },
        {
            type = "noise-expression",
            name = "eon_lava_mountains_range",
            expression = "1100 * range_select_base(eon_mountain_lava_spots, 0.3, 1, 1, 0, 1) - eon_offset_vulcano"
        },
        {
            type = "noise-expression",
            name = "eon_lava_hot_mountains_range",
            expression = "1000 * range_select_base(eon_mountain_lava_spots, 0.15, 0.35, 1, 0, 1) - eon_offset_vulcano"
        },
        {
            type = "noise-expression",
            name = "eon_volcano_cracks_warm_range",
            expression = "900 * range_select_base(eon_mountain_lava_spots, 0.10, 0.17, 1, 0, 1) - eon_offset_vulcano"
        },
        {
            type = "noise-expression",
            name = "eon_crater_cliff",
            expression =
            "eon_mask_vulcano_coverage(0.5 * (vulcanus_rock_noise + 0.5 * aux - 0.5 * moisture) * (1 - max(vulcanus_basalts_biome,vulcanus_ashlands_biome)) * place_every_n(21,21,0,0))"
        },
        {
            type = "noise-expression",
            name = "eon_offset_vulcano",
            expression = "1.5"
        },
        {
            type = "noise-expression",
            name = "eon_updated_volcanic_folds",
            expression =
            "10 * range_select_base(eon_mountain_volcano_spots * 1.95 - 0.9, 0.16, 10, 1, 0, 1) - eon_offset_vulcano"
        },
        {
            type = "noise-expression",
            name = "eon_updated_volcanic_folds_flat",
            expression =
            "10 * range_select_base(eon_mountain_volcano_spots * 1.95 - 0.9, 0, 0.5, 1, 0, 1) - eon_offset_vulcano"
        },
        {
            type = "noise-expression",
            name = "eon_vulcano_coverage",
            expression = eon_vulcanus_coverage_expression(aquilo_on_fulgora)
        },
        {
            type = "noise-expression",
            name = "eon_vulcanus_terrain",
            expression = eon_vulcanus_terrain_expression(aquilo_on_fulgora)
        },
        {
            type = "noise-expression",
            name = "eon_vulcanus_tree_on_nauvis",
            expression = eon_vulcanus_tree_on_nauvis_expression
        },
        {
            type = "noise-function",
            name = "eon_vulcanus_region",
            parameters = { "threshold" },
            expression = "if(vulcanus_region_noise + north_offset > threshold, 1, 0)",
            local_expressions = {
                y_offset = "-y - 1000",
                north_offset = "y_offset / (1 + pow(2, 0.01 * y_offset)) + 0.1 * y_offset - 60",
                vulcanus_region_noise =
                "10 * (vulcanus_ashlands_biome_noise + vulcanus_basalts_biome_noise + vulcanus_mountains_biome_noise)"
            }
        },
        {
            type = "noise-function",
            name = "eon_mask_vulcano_coverage",
            parameters = { "expression" },
            expression = "if(eon_vulcano_coverage, expression, -inf)"
        },
        {
            type = "noise-function",
            name = "eon_mask_vulcano_terrain",
            parameters = { "expression" },
            expression = "if(eon_vulcanus_terrain, expression, -inf)"
        },
        {
            type = "noise-function",
            name = "eon_mask_off_vulcano_coverage",
            parameters = { "expression" },
            expression = "if(eon_vulcano_coverage, -inf, expression)"
        },
        {
            type = "noise-function",
            name = "eon_mask_off_vulcano_terrain",
            parameters = { "expression" },
            expression = "if(eon_vulcanus_terrain, -inf, expression)"
        },
    }
end

return eon_volcano_registry
