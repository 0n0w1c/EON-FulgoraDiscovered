local resources = {}

resources.guarded_nauvis_resources = {
    "iron-ore",
    "copper-ore",
    "stone",
    "coal",
    "uranium-ore",
    "crude-oil",
}

resources.by_biome = {
    nauvis = {
        solid = {
            "iron-ore",
            "copper-ore",
            "stone",
            "coal",
            "uranium-ore",
        },
        fluid = {
            "crude-oil",
        },
    },

    gleba = {
        stromatolite = {
            "iron-stromatolite",
            "copper-stromatolite",
        },
    },

    aquilo = {
        fluid = {
            "lithium-brine",
            "fluorine-vent",
        },
    },

    vulcanus = {
        solid = {
            "calcite",
            "tungsten-ore",
        },
        fluid = {
            "sulfuric-acid-geyser",
        },
    },
}

resources.nauvis_aquilo_fluid_resource_configs = {
    {
        resource_name = "lithium-brine",
        expression_name = "lithium_brine",
        control = "lithium_brine",
        seed = 567,
        guarded_count = 3,
        skip_offset = 1,
        guarded_radius = 1.2,
        unrestricted_patch_index = 11,
        unrestricted_seed = 567,
        probability_multiplier = 0.012,
        richness = 720000,
    },
    {
        resource_name = "fluorine-vent",
        expression_name = "fluorine_vent",
        control = "fluorine_vent",
        seed = 567,
        guarded_count = 2,
        skip_offset = 2,
        guarded_radius = 1.5,
        unrestricted_patch_index = 12,
        unrestricted_seed = 568,
        probability_multiplier = 0.008,
        richness = 520000,
    },
}

resources.use_current_expression_in_guarded_alignment = {
    ["calcite"] = true,
    ["sulfuric-acid-geyser"] = true,
    ["tungsten-ore"] = true,
}

resources.aquilo_nauvis_fluid_resources = {
    ["lithium-brine"] = true,
    ["fluorine-vent"] = true,
}

resources.eon_added_vulcanus_resources = {
    ["calcite"] = true,
    ["sulfuric-acid-geyser"] = true,
    ["tungsten-ore"] = true,
}

resources.unrestricted_vulcanus_resource_configs = {
    ["iron-ore"] = { control = "iron-ore", base_density = 10, base_spots_per_km2 = 3.6, candidate_spot_count = 32, regular_patch_set_index = 0, seed = 2100, random_spot_size_minimum = 0.25, random_spot_size_maximum = 2.4, size_multiplier = 1.25, richness = 1.0, regular_rq_factor = 0.11, starting_rq = 0.21428571428571 },
    ["copper-ore"] = { control = "copper-ore", base_density = 8, base_spots_per_km2 = 3.6, candidate_spot_count = 32, regular_patch_set_index = 1, seed = 2101, random_spot_size_minimum = 0.25, random_spot_size_maximum = 2.4, size_multiplier = 1.25, richness = 1.0, regular_rq_factor = 0.11, starting_rq = 0.17142857142857 },
    ["coal"] = { control = "coal", base_density = 8, base_spots_per_km2 = 3.4, candidate_spot_count = 30, regular_patch_set_index = 2, seed = 2102, random_spot_size_minimum = 0.25, random_spot_size_maximum = 2.4, size_multiplier = 1.2, richness = 1.0, regular_rq_factor = 0.1, starting_rq = 0.15714285714286 },
    ["stone"] = { control = "stone", base_density = 4, base_spots_per_km2 = 3.2, candidate_spot_count = 30, regular_patch_set_index = 3, seed = 2103, random_spot_size_minimum = 0.25, random_spot_size_maximum = 2.2, size_multiplier = 1.2, richness = 1.0, regular_rq_factor = 0.1, starting_rq = 0.15714285714286 },
    ["uranium-ore"] = { control = "uranium-ore", base_density = 0.9, base_spots_per_km2 = 1.35, candidate_spot_count = 22, regular_patch_set_index = 5, seed = 2105, random_spot_size_minimum = 2, random_spot_size_maximum = 4, size_multiplier = 0.85, richness = 0.1, regular_rq_factor = 0.1, starting_rq = 0.14285714285714 },
    ["crude-oil"] = { control = "crude-oil", base_density = 8.2, base_spots_per_km2 = 2.4, candidate_spot_count = 28, regular_patch_set_index = 4, seed = 2104, random_spot_size_minimum = 1, random_spot_size_maximum = 1, size_multiplier = 1.15, richness = 1.0, regular_rq_factor = 0.1, starting_rq = 0.14285714285714, fluid = true },
    ["calcite"] = { control = "calcite", base_density = 5, base_spots_per_km2 = 3.0, candidate_spot_count = 28, regular_patch_set_index = 6, seed = 2110, random_spot_size_minimum = 0.5, random_spot_size_maximum = 2.5, size_multiplier = 1.15, richness = 0.9, regular_rq_factor = 0.1, starting_rq = 0.14285714285714 },
    ["tungsten-ore"] = { control = "tungsten_ore", base_density = 1.2, base_spots_per_km2 = 1.8, candidate_spot_count = 24, regular_patch_set_index = 7, seed = 2111, random_spot_size_minimum = 1.5, random_spot_size_maximum = 3.5, size_multiplier = 0.95, richness = 0.45, regular_rq_factor = 0.1, starting_rq = 0.14285714285714 },
    ["sulfuric-acid-geyser"] = { control = "sulfuric_acid_geyser", base_density = 8.2, base_spots_per_km2 = 2.4, candidate_spot_count = 28, regular_patch_set_index = 5, seed = 2112, random_spot_size_minimum = 1, random_spot_size_maximum = 1, size_multiplier = 1.15, richness = 1.0, regular_rq_factor = 0.1, starting_rq = 0.14285714285714, fluid = true },
}

resources.vulcanus_resource_aligned_decoratives = {
    guarded = {
        { name = "calcite-stain",              expression = "(vulcanus_calcite_region > 0.02) * vulcanus_calcite_stain" },
        { name = "calcite-stain-small",        expression = "(vulcanus_calcite_region > -0.02) * vulcanus_calcite_stain_small" },
        { name = "sulfur-stain",               expression = "(vulcanus_sulfuric_acid_region_patchy > 0.15) * vulcanus_sulfuric_acid_stain" },
        { name = "sulfur-stain-small",         expression = "(vulcanus_sulfuric_acid_region_patchy > 0.08) * vulcanus_sulfuric_acid_stain_small" },
        { name = "sulfuric-acid-puddle",       expression = "(vulcanus_sulfuric_acid_region_patchy > 0.15) * vulcanus_sulfuric_acid_puddle" },
        { name = "sulfuric-acid-puddle-small", expression = "(vulcanus_sulfuric_acid_region_patchy > 0.08) * vulcanus_sulfuric_acid_puddle_small" },
        { name = "sulfur-rock-cluster",        expression = "(vulcanus_sulfuric_acid_region_patchy > 0.15) * vulcanus_sulfur_rock_cluster" },
        { name = "small-sulfur-rock",          expression = "(vulcanus_sulfuric_acid_region_patchy > 0.08) * vulcanus_small_sulfur_rock" },
        { name = "tiny-sulfur-rock",           expression = "(vulcanus_sulfuric_acid_region_patchy > 0.08) * vulcanus_sulfur_rock_tiny" },
    },

    unrestricted = {
        { name = "calcite-stain",              expression = "min(0.18, 4 * clamp(var('default-calcite-patches') - 0.01, 0, 1))" },
        { name = "calcite-stain-small",        expression = "min(0.22, 3 * clamp(var('default-calcite-patches') + 0.02, 0, 1))" },
        { name = "sulfur-stain",               expression = "min(0.18, 6 * clamp(eon_default_sulfuric_acid_geyser_patches - 0.01, 0, 1))" },
        { name = "sulfur-stain-small",         expression = "min(0.22, 4 * clamp(eon_default_sulfuric_acid_geyser_patches, 0, 1))" },
        { name = "sulfuric-acid-puddle",       expression = "min(0.12, 5 * clamp(eon_default_sulfuric_acid_geyser_patches - 0.015, 0, 1))" },
        { name = "sulfuric-acid-puddle-small", expression = "min(0.16, 4 * clamp(eon_default_sulfuric_acid_geyser_patches, 0, 1))" },
        { name = "sulfur-rock-cluster",        expression = "min(0.04, 1.5 * clamp(eon_default_sulfuric_acid_geyser_patches - 0.02, 0, 1))" },
        { name = "small-sulfur-rock",          expression = "min(0.06, 1.5 * clamp(eon_default_sulfuric_acid_geyser_patches - 0.005, 0, 1))" },
        { name = "tiny-sulfur-rock",           expression = "min(0.08, 1.2 * clamp(eon_default_sulfuric_acid_geyser_patches, 0, 1))" },
    },
}

resources.guarded_direct_resource_expressions = {
    {
        resource_name = "calcite",
        probability = "eon_nauvis_vulcanus_calcite_probability",
        richness = "eon_nauvis_vulcanus_calcite_richness",
    },
    {
        resource_name = "sulfuric-acid-geyser",
        probability = "eon_nauvis_vulcanus_sulfuric_acid_geyser_probability",
        richness = "eon_nauvis_vulcanus_sulfuric_acid_geyser_richness",
    },
}

resources.guarded_aquilo_nauvis_direct_resource_expressions = {
    {
        resource_name = "lithium-brine",
        probability = "eon_nauvis_aquilo_lithium_brine_probability",
        richness = "eon_nauvis_aquilo_lithium_brine_richness",
    },
    {
        resource_name = "fluorine-vent",
        probability = "eon_nauvis_aquilo_fluorine_vent_probability",
        richness = "eon_nauvis_aquilo_fluorine_vent_richness",
    },
}

resources.unrestricted_direct_resource_expressions = {
    {
        resource_name = "sulfuric-acid-geyser",
        probability = "eon_default_sulfuric_acid_geyser_probability",
        richness = "eon_default_sulfuric_acid_geyser_richness",
    },
}

resources.guarded_tungsten_policy = {
    resource_name = "tungsten-ore",
    probability = "1000 * vulcanus_tungsten_ore_probability",
    richness = "vulcanus_tungsten_ore_richness",
    region_expression =
    "max(vulcanus_starting_tungsten, min(1 - vulcanus_starting_circle, vulcanus_place_non_metal_spots(789, 15, 2, vulcanus_tungsten_ore_size * min(1.2, vulcanus_ore_dist) * 25, control:tungsten_ore:frequency, vulcanus_mountains_resource_favorability)))",
}

resources.by_name = {}
for biome_name, roles in pairs(resources.by_biome) do
    for role_name, names in pairs(roles) do
        for _, resource_name in ipairs(names) do
            resources.by_name[resource_name] = {
                biome = biome_name,
                role = role_name,
            }
        end
    end
end

---@param biome_name string
---@param role_name string|nil
---@return string[]
function resources.names_for_biome(biome_name, role_name)
    local biome = resources.by_biome[biome_name]
    if not biome then return {} end

    if role_name then
        return biome[role_name] or {}
    end

    local result = {}
    for _, names in pairs(biome) do
        for _, resource_name in ipairs(names) do
            result[#result + 1] = resource_name
        end
    end
    return result
end

---@param resource_name string
---@return table|nil
function resources.classify(resource_name)
    return resources.by_name[resource_name]
end

return resources
