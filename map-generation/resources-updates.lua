local terrain = require("map-generation.terrain")

local guarded_resources_enabled = settings.startup["eon-fd-guarded-resources"]
    and settings.startup["eon-fd-guarded-resources"].value

local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value == true

local mask_vulcanus_resources_off_aquilo = guarded_resources_enabled and not eon_aquilo_on_fulgora

local eon_vulcanus_resource_off_aquilo_mask = mask_vulcanus_resources_off_aquilo
    and "eon_mask_off_aquilo_territory"
    or "eon_identity"

local mask_vulcanus_resources_off_ammonia_ocean = guarded_resources_enabled and not eon_aquilo_on_fulgora

local eon_vulcanus_resource_off_ammonia_ocean_mask = mask_vulcanus_resources_off_ammonia_ocean
    and "eon_mask_off_ammonia_ocean"
    or "eon_identity"

local eon_vulcanus_resource_richness_expression = mask_vulcanus_resources_off_aquilo
    and "if(eon_aquilo_mask, 0, if(eon_vulcanus_terrain, %s, 0))"
    or "if(eon_vulcanus_terrain, %s, 0)"

local eon_vulcanus_tungsten_richness_expression = mask_vulcanus_resources_off_aquilo
    and "if(eon_aquilo_mask, 0, %s)"
    or "%s"

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

---@param resource_name string
---@param expression string
---@return nil
local function set_resource_probability(resource_name, expression)
    data.raw.resource[resource_name].autoplace.probability_expression = expression
end

---@param resource_name string
---@param expression string
---@return nil
local function set_guarded_resource_probability(resource_name, expression)
    set_resource_probability(resource_name,
        mask_off_aquilo_territory(mask_off_ammonia_ocean(mask_vulcanus_coverage(expression))))
end

---@param config {guarded: fun(), normal: fun()}
---@return nil
local function configure_guarded_resource(config)
    if guarded_resources_enabled then
        config.guarded()
    else
        config.normal()
    end
end


if guarded_resources_enabled then
    terrain.mask_resource_territory("iron-ore", "resource")
    terrain.mask_resource_territory("copper-ore", "resource")
    terrain.mask_resource_territory("stone", "resource")
    terrain.mask_resource_territory("coal", "resource")
    terrain.mask_resource_territory("uranium-ore", "resource")
    terrain.mask_resource_territory("crude-oil", "resource")
end


data.raw["noise-expression"]["aquilo_crude_oil_spots"].expression = "0"
data.raw.planet["aquilo"].map_gen_settings.autoplace_controls = {}


data.raw["autoplace-control"]["gleba_plants"].localised_description = nil

---@param planet_name string
---@return nil
local function enable_planet_resource_autoplace_controls(planet_name)
    local source_planet = data.raw.planet[planet_name]
    local nauvis = data.raw.planet["nauvis"]

    if not (source_planet and source_planet.map_gen_settings) then return end
    if not (nauvis and nauvis.map_gen_settings) then return end

    local source_controls = source_planet.map_gen_settings.autoplace_controls
    if not source_controls then return end

    nauvis.map_gen_settings.autoplace_controls = nauvis.map_gen_settings.autoplace_controls or {}

    for control_name, control_settings in pairs(source_controls) do
        local control = data.raw["autoplace-control"] and data.raw["autoplace-control"][control_name]
        if control and control.category == "resource" then
            control.localised_description = nil
            nauvis.map_gen_settings.autoplace_controls[control_name] = table.deepcopy(control_settings or {})
        end
    end
end

if guarded_resources_enabled then
    enable_planet_resource_autoplace_controls("nauvis")
    enable_planet_resource_autoplace_controls("gleba")
    enable_planet_resource_autoplace_controls("vulcanus")
end


table.insert(data.raw["simple-entity"]["big-volcanic-rock"].minable.results,
    { type = "item", name = "calcite", amount_min = 2, amount_max = 8 })
table.insert(data.raw["simple-entity"]["huge-volcanic-rock"].minable.results,
    { type = "item", name = "calcite", amount_min = 3, amount_max = 15 })

data.raw["autoplace-control"]["vulcanus_volcanism"].order = "c-z-ca"
data.raw["autoplace-control"]["vulcanus_volcanism"].category = "terrain"
data.raw["autoplace-control"]["vulcanus_volcanism"].localised_description = nil

data.raw["autoplace-control"]["sulfuric_acid_geyser"].order = "b-z"

data.raw["autoplace-control"]["scrap"].order = "e-ca"

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["calcite"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["sulfuric-acid-geyser"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["tungsten-ore"] = {}

data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["sulfuric_acid_geyser"] = {}

if guarded_resources_enabled then
    data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["calcite"] = {}
    data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["tungsten_ore"] = {}
end

data.raw["noise-expression"]["vulcanus_starting_calcite"].expression = "-inf"


---@param decorative_name string
---@param expression string
---@param unrestricted boolean
---@return nil
local function set_resource_aligned_decorative_probability(decorative_name, expression, unrestricted)
    local decorative = data.raw["optimized-decorative"] and data.raw["optimized-decorative"][decorative_name]
    if not (decorative and decorative.autoplace) then return end

    if unrestricted then
        decorative.autoplace.tile_restriction = nil
        decorative.autoplace.probability_expression = mask_off_ammonia_ocean(expression)
    else
        decorative.autoplace.probability_expression = mask_vulcanus_resource_terrain(expression)
    end
end

---@return nil
local function align_resource_decoratives_to_current_resources()
    if guarded_resources_enabled then
        set_resource_aligned_decorative_probability(
            "calcite-stain",
            "(vulcanus_calcite_region > 0.02) * vulcanus_calcite_stain",
            false
        )
        set_resource_aligned_decorative_probability(
            "calcite-stain-small",
            "(vulcanus_calcite_region > -0.02) * vulcanus_calcite_stain_small",
            false
        )

        set_resource_aligned_decorative_probability(
            "sulfur-stain",
            "(vulcanus_sulfuric_acid_region_patchy > 0.15) * vulcanus_sulfuric_acid_stain",
            false
        )
        set_resource_aligned_decorative_probability(
            "sulfur-stain-small",
            "(vulcanus_sulfuric_acid_region_patchy > 0.08) * vulcanus_sulfuric_acid_stain_small",
            false
        )
        set_resource_aligned_decorative_probability(
            "sulfuric-acid-puddle",
            "(vulcanus_sulfuric_acid_region_patchy > 0.15) * vulcanus_sulfuric_acid_puddle",
            false
        )
        set_resource_aligned_decorative_probability(
            "sulfuric-acid-puddle-small",
            "(vulcanus_sulfuric_acid_region_patchy > 0.08) * vulcanus_sulfuric_acid_puddle_small",
            false
        )
        set_resource_aligned_decorative_probability(
            "sulfur-rock-cluster",
            "(vulcanus_sulfuric_acid_region_patchy > 0.15) * vulcanus_sulfur_rock_cluster",
            false
        )
        set_resource_aligned_decorative_probability(
            "small-sulfur-rock",
            "(vulcanus_sulfuric_acid_region_patchy > 0.08) * vulcanus_small_sulfur_rock",
            false
        )
        set_resource_aligned_decorative_probability(
            "tiny-sulfur-rock",
            "(vulcanus_sulfuric_acid_region_patchy > 0.08) * vulcanus_sulfur_rock_tiny",
            false
        )

        return
    end

    set_resource_aligned_decorative_probability(
        "calcite-stain",
        "min(0.18, 4 * clamp(var('default-calcite-patches') - 0.01, 0, 1))",
        true
    )
    set_resource_aligned_decorative_probability(
        "calcite-stain-small",
        "min(0.22, 3 * clamp(var('default-calcite-patches') + 0.02, 0, 1))",
        true
    )

    set_resource_aligned_decorative_probability(
        "sulfur-stain",
        "min(0.18, 6 * clamp(eon_default_sulfuric_acid_geyser_patches - 0.01, 0, 1))",
        true
    )
    set_resource_aligned_decorative_probability(
        "sulfur-stain-small",
        "min(0.22, 4 * clamp(eon_default_sulfuric_acid_geyser_patches, 0, 1))",
        true
    )
    set_resource_aligned_decorative_probability(
        "sulfuric-acid-puddle",
        "min(0.12, 5 * clamp(eon_default_sulfuric_acid_geyser_patches - 0.015, 0, 1))",
        true
    )
    set_resource_aligned_decorative_probability(
        "sulfuric-acid-puddle-small",
        "min(0.16, 4 * clamp(eon_default_sulfuric_acid_geyser_patches, 0, 1))",
        true
    )
    set_resource_aligned_decorative_probability(
        "sulfur-rock-cluster",
        "min(0.04, 1.5 * clamp(eon_default_sulfuric_acid_geyser_patches - 0.02, 0, 1))",
        true
    )
    set_resource_aligned_decorative_probability(
        "small-sulfur-rock",
        "min(0.06, 1.5 * clamp(eon_default_sulfuric_acid_geyser_patches - 0.005, 0, 1))",
        true
    )
    set_resource_aligned_decorative_probability(
        "tiny-sulfur-rock",
        "min(0.08, 1.2 * clamp(eon_default_sulfuric_acid_geyser_patches, 0, 1))",
        true
    )
end

local calcite_probability_base_expression =
"(control:calcite:size > 0) * \z
    (1000 * ((1 + vulcanus_calcite_region) * random_penalty_between(0.9, 1, 1) - 1))"

local calcite_probability_expression = guarded_resources_enabled
    and mask_vulcanus_resource_terrain(calcite_probability_base_expression)
    or mask_off_ammonia_ocean(calcite_probability_base_expression)

local calcite_richness_expression = guarded_resources_enabled
    and string.format(eon_vulcanus_resource_richness_expression, "vulcanus_calcite_richness")
    or "vulcanus_calcite_richness"

local sulfuric_acid_geyser_probability_base_expression =
"(control:sulfuric_acid_geyser:size > 0) * \z
    (0.025 * control:sulfuric_acid_geyser:frequency * \z
    ((vulcanus_sulfuric_acid_region_patchy > 0) + 2 * vulcanus_sulfuric_acid_region_patchy))"

local sulfuric_acid_geyser_probability_expression = guarded_resources_enabled
    and mask_vulcanus_resource_terrain(sulfuric_acid_geyser_probability_base_expression)
    or mask_off_ammonia_ocean(sulfuric_acid_geyser_probability_base_expression)

local sulfuric_acid_geyser_richness_expression = guarded_resources_enabled
    and string.format(eon_vulcanus_resource_richness_expression, "vulcanus_sulfuric_acid_geyser_richness")
    or "vulcanus_sulfuric_acid_geyser_richness"

local default_sulfuric_acid_geyser_patches_expression =
"resource_autoplace_all_patches{base_density = 8.2, base_spots_per_km2 = 1.8, \z
    candidate_spot_count = 21, frequency_multiplier = control:sulfuric_acid_geyser:frequency, \z
    has_starting_area_placement = 0, random_spot_size_minimum = 1, random_spot_size_maximum = 1, \z
    regular_blob_amplitude_multiplier = 0.125, \z
    regular_patch_set_count = default_regular_resource_patch_set_count, regular_patch_set_index = 5, \z
    regular_rq_factor = 0.1, seed1 = 177, size_multiplier = control:sulfuric_acid_geyser:size, \z
    starting_blob_amplitude_multiplier = 0.125, \z
    starting_patch_set_count = default_starting_resource_patch_set_count, starting_patch_set_index = 0, \z
    starting_rq_factor = 0.14285714285714}"

local default_sulfuric_acid_geyser_probability_expression =
"(control:sulfuric_acid_geyser:size > 0) * \z
    (clamp(eon_default_sulfuric_acid_geyser_patches, 0, 1) * random_penalty{x = x, y = y, source = 1, amplitude = 1 / 0.020833333333333})"

local default_sulfuric_acid_geyser_richness_expression =
"(control:sulfuric_acid_geyser:size > 0) * \z
    (control:sulfuric_acid_geyser:richness * \z
    (eon_default_sulfuric_acid_geyser_patches / 0.020833333333333 + 220000) * \z
    max((1000 + distance) / 2600, 1))"

data:extend({
    {
        type = "noise-expression",
        name = "eon_nauvis_vulcanus_calcite_probability",
        expression = calcite_probability_expression
    },
    {
        type = "noise-expression",
        name = "eon_nauvis_vulcanus_calcite_richness",
        expression = calcite_richness_expression
    },
    {
        type = "noise-expression",
        name = "eon_nauvis_vulcanus_sulfuric_acid_geyser_probability",
        expression = sulfuric_acid_geyser_probability_expression
    },
    {
        type = "noise-expression",
        name = "eon_nauvis_vulcanus_sulfuric_acid_geyser_richness",
        expression = sulfuric_acid_geyser_richness_expression
    },
    {
        type = "noise-expression",
        name = "eon_default_sulfuric_acid_geyser_patches",
        expression = default_sulfuric_acid_geyser_patches_expression
    },
    {
        type = "noise-expression",
        name = "eon_default_sulfuric_acid_geyser_probability",
        expression = default_sulfuric_acid_geyser_probability_expression
    },
    {
        type = "noise-expression",
        name = "eon_default_sulfuric_acid_geyser_richness",
        expression = default_sulfuric_acid_geyser_richness_expression
    }
})

data.raw["noise-expression"]["vulcanus_starting_sulfur"].expression = "-inf"

data.raw["noise-expression"]["vulcanus_starting_tungsten"].expression = "-inf"

configure_guarded_resource {
    guarded = function()
        set_guarded_resource_probability("tungsten-ore", "1000 * vulcanus_tungsten_ore_probability")
        data.raw.resource["tungsten-ore"].autoplace.richness_expression =
            string.format(eon_vulcanus_tungsten_richness_expression, "vulcanus_tungsten_ore_richness")

        data.raw["noise-expression"]["vulcanus_tungsten_ore_region"].expression =
        "max(vulcanus_starting_tungsten, min(1 - vulcanus_starting_circle, vulcanus_place_non_metal_spots(789, 15, 2, vulcanus_tungsten_ore_size * min(1.2, vulcanus_ore_dist) * 25, control:tungsten_ore:frequency, vulcanus_mountains_resource_favorability)))"
    end,
    normal = function()
        data.raw["noise-expression"]["vulcanus_tungsten_ore_probability"].expression =
            mask_off_aquilo_territory(mask_off_ammonia_ocean(
                "(control:tungsten_ore:size > 0) * (1000 * ((0.7 + vulcanus_tungsten_ore_region) * random_penalty_between(0.9, 1, 1) - 1))"))
        terrain.mask_resource_territory("tungsten-ore", "resource")
    end
}

---@param planet_name string
---@return table<string, table>|nil
local function get_planet_entity_settings(planet_name)
    local planet = data.raw.planet[planet_name]
    if not planet or not planet.map_gen_settings then return nil end

    local autoplace_settings = planet.map_gen_settings.autoplace_settings
    if not autoplace_settings or not autoplace_settings.entity then return nil end

    return autoplace_settings.entity.settings
end

---@param proto table
---@return string|nil
local function expression_for_autoplace(proto)
    if not proto.autoplace then return nil end

    if type(proto.autoplace.probability_expression) == "string" and proto.autoplace.probability_expression ~= "" then
        return proto.autoplace.probability_expression
    end

    if proto.autoplace.probability ~= nil then
        local expression = tostring(proto.autoplace.probability)
        proto.autoplace.probability = nil
        return expression
    end

    return nil
end

---@param proto table
---@return string|nil
local function richness_expression_for_autoplace(proto)
    if not proto.autoplace then return nil end

    if type(proto.autoplace.richness_expression) == "string" and proto.autoplace.richness_expression ~= "" then
        return proto.autoplace.richness_expression
    end

    if proto.autoplace.richness ~= nil then
        local expression = tostring(proto.autoplace.richness)
        proto.autoplace.richness = nil
        return expression
    end

    return nil
end

---@param planet_name string
---@param entity_name string
---@return string|nil
local function get_planet_richness_expression(planet_name, entity_name)
    local planet = data.raw.planet[planet_name]
    if not planet or not planet.map_gen_settings then return nil end

    local names = planet.map_gen_settings.property_expression_names
    if not names then return nil end

    local expression_name = names["entity:" .. entity_name .. ":richness"]
    if type(expression_name) == "string" and expression_name ~= "" then
        return expression_name
    end

    return nil
end

---@param planet_name string
---@param entity_name string
---@return string|nil
local function get_planet_probability_expression(planet_name, entity_name)
    local planet = data.raw.planet[planet_name]
    if not planet or not planet.map_gen_settings then return nil end

    local names = planet.map_gen_settings.property_expression_names
    if not names then return nil end

    local expression_name = names["entity:" .. entity_name .. ":probability"]
    if type(expression_name) == "string" and expression_name ~= "" then
        return expression_name
    end

    return nil
end

---@param expression string
---@param mask_name string
---@return string
local function mask_expression(expression, mask_name)
    return mask_name .. "(" .. expression .. ")"
end

---@param masked string[]
---@return string|nil
local function combine_masked_expressions(masked)
    if #masked == 0 then return nil end
    if #masked == 1 then return masked[1] end

    return "max(" .. table.concat(masked, ", ") .. ")"
end

---@param masked string[]
---@param expression string
---@param mask_name string
---@return nil
local function add_masked_expression(masked, expression, mask_name)
    table.insert(masked, mask_expression(expression, mask_name))
end

---@param entity_name string
---@param mask_name string
---@return nil
local function apply_simple_entity_biome_mask(entity_name, mask_name)
    local proto = data.raw["simple-entity"] and data.raw["simple-entity"][entity_name]
    if not proto or not proto.autoplace then return end

    local expression = expression_for_autoplace(proto)
    if not expression then expression = "1" end

    proto.autoplace.probability_expression = mask_expression(expression, mask_name)
end

---@param resource_name string
---@param planet_name string
---@param default_expression string
---@return string
local function guarded_resource_expression_for_planet(resource_name, planet_name, default_expression)
    local use_current_expression = {
        ["calcite"] = true,
        ["sulfuric-acid-geyser"] = true,
        ["tungsten-ore"] = true,
    }

    if not use_current_expression[resource_name] then
        local planet_expression = get_planet_probability_expression(planet_name, resource_name)
        if planet_expression then return planet_expression end
    end

    return default_expression
end

---@param name string
---@param expression string
---@return nil
local function set_or_extend_noise_expression(name, expression)
    local existing = data.raw["noise-expression"] and data.raw["noise-expression"][name]

    if existing then
        existing.expression = expression
    else
        data:extend({
            {
                type = "noise-expression",
                name = name,
                expression = expression
            }
        })
    end
end

---@param entity_name string
---@param property_name string
---@param expression_name string
---@return nil
local function set_nauvis_entity_property_expression(entity_name, property_name, expression_name)
    local nauvis = data.raw.planet["nauvis"]
    if not nauvis or not nauvis.map_gen_settings then return end

    nauvis.map_gen_settings.property_expression_names = nauvis.map_gen_settings.property_expression_names or {}
    nauvis.map_gen_settings.property_expression_names["entity:" .. entity_name .. ":" .. property_name] = expression_name
end

---@param resource_name string
---@param resource table
---@return nil
local function apply_guarded_resource_biome_mask(resource_name, resource)
    local nauvis_settings = get_planet_entity_settings("nauvis") or {}
    local gleba_settings = get_planet_entity_settings("gleba") or {}
    local vulcanus_settings = get_planet_entity_settings("vulcanus") or {}

    local default_expression = expression_for_autoplace(resource)
    if not default_expression then default_expression = "1" end

    local masked = {}

    local eon_added_vulcanus_resources = {
        ["calcite"] = true,
        ["sulfuric-acid-geyser"] = true,
        ["tungsten-ore"] = true,
    }

    if nauvis_settings[resource_name] and not eon_added_vulcanus_resources[resource_name] then
        add_masked_expression(masked, default_expression, "eon_mask_nauvis_territory")
    end

    if gleba_settings[resource_name] then
        add_masked_expression(
            masked,
            guarded_resource_expression_for_planet(resource_name, "gleba", default_expression),
            "eon_mask_gleba_territory"
        )
    end

    if vulcanus_settings[resource_name] then
        add_masked_expression(
            masked,
            guarded_resource_expression_for_planet(resource_name, "vulcanus", default_expression),
            "eon_mask_vulcano_terrain"
        )
    end

    local probability_expression = combine_masked_expressions(masked)
    if probability_expression then
        resource.autoplace.probability_expression = probability_expression
    end

    if resource_name == "stone" and gleba_settings[resource_name] then
        local default_richness = richness_expression_for_autoplace(resource)
        local gleba_richness = get_planet_richness_expression("gleba", "stone")

        if probability_expression then
            set_or_extend_noise_expression(
                "eon_guarded_stone_probability",
                mask_off_ammonia_ocean(probability_expression)
            )
            set_nauvis_entity_property_expression("stone", "probability", "eon_guarded_stone_probability")
            resource.autoplace.probability_expression = "eon_guarded_stone_probability"
        end

        if default_richness and gleba_richness then
            local richness_expression = combine_masked_expressions({
                mask_expression(default_richness, "eon_mask_nauvis_territory"),
                mask_expression(gleba_richness, "eon_mask_gleba_territory")
            })

            if richness_expression then
                set_or_extend_noise_expression("eon_guarded_stone_richness", richness_expression)
                set_nauvis_entity_property_expression("stone", "richness", "eon_guarded_stone_richness")
                resource.autoplace.richness_expression = "eon_guarded_stone_richness"
            end
        elseif gleba_richness then
            local richness_expression = mask_expression(gleba_richness, "eon_mask_gleba_territory")

            set_or_extend_noise_expression("eon_guarded_stone_richness", richness_expression)
            set_nauvis_entity_property_expression("stone", "richness", "eon_guarded_stone_richness")
            resource.autoplace.richness_expression = "eon_guarded_stone_richness"
        end
    end

    if resource_name == "coal" and vulcanus_settings[resource_name] then
        local default_richness = richness_expression_for_autoplace(resource)
        local vulcanus_richness = get_planet_richness_expression("vulcanus", "coal")

        if probability_expression then
            set_or_extend_noise_expression(
                "eon_guarded_coal_probability",
                mask_off_ammonia_ocean(probability_expression)
            )
            set_nauvis_entity_property_expression("coal", "probability", "eon_guarded_coal_probability")
            resource.autoplace.probability_expression = "eon_guarded_coal_probability"
        end

        if default_richness and vulcanus_richness then
            local richness_expression = combine_masked_expressions({
                mask_expression(default_richness, "eon_mask_nauvis_territory"),
                mask_expression(vulcanus_richness, "eon_mask_vulcano_terrain")
            })

            if richness_expression then
                set_or_extend_noise_expression("eon_guarded_coal_richness", richness_expression)
                set_nauvis_entity_property_expression("coal", "richness", "eon_guarded_coal_richness")
                resource.autoplace.richness_expression = "eon_guarded_coal_richness"
            end
        elseif vulcanus_richness then
            local richness_expression = mask_expression(vulcanus_richness, "eon_mask_vulcano_terrain")

            set_or_extend_noise_expression("eon_guarded_coal_richness", richness_expression)
            set_nauvis_entity_property_expression("coal", "richness", "eon_guarded_coal_richness")
            resource.autoplace.richness_expression = "eon_guarded_coal_richness"
        end
    end
end

---@return nil
local function align_guarded_resources_to_biomes()
    for resource_name, resource in pairs(data.raw.resource or {}) do
        if resource.autoplace then
            apply_guarded_resource_biome_mask(resource_name, resource)
        end
    end

    apply_simple_entity_biome_mask("iron-stromatolite", "eon_mask_gleba_territory")
    apply_simple_entity_biome_mask("copper-stromatolite", "eon_mask_gleba_territory")
end


if guarded_resources_enabled then
    set_resource_probability("calcite", "eon_nauvis_vulcanus_calcite_probability")
    data.raw.resource["calcite"].autoplace.richness_expression = "eon_nauvis_vulcanus_calcite_richness"

    set_guarded_resource_probability(
        "tungsten-ore",
        "vulcanus_tungsten_ore_probability * (1 - clamp(vulcanus_sulfuric_acid_region_patchy, 0, 1))"
    )

    align_guarded_resources_to_biomes()

    set_nauvis_entity_property_expression("calcite", "probability", "eon_nauvis_vulcanus_calcite_probability")
    set_nauvis_entity_property_expression("calcite", "richness", "eon_nauvis_vulcanus_calcite_richness")
    data.raw.resource["calcite"].autoplace.probability_expression = "eon_nauvis_vulcanus_calcite_probability"
    data.raw.resource["calcite"].autoplace.richness_expression = "eon_nauvis_vulcanus_calcite_richness"

    set_nauvis_entity_property_expression("sulfuric-acid-geyser", "probability",
        "eon_nauvis_vulcanus_sulfuric_acid_geyser_probability")
    set_nauvis_entity_property_expression("sulfuric-acid-geyser", "richness",
        "eon_nauvis_vulcanus_sulfuric_acid_geyser_richness")
    data.raw.resource["sulfuric-acid-geyser"].autoplace.probability_expression =
    "eon_nauvis_vulcanus_sulfuric_acid_geyser_probability"
    data.raw.resource["sulfuric-acid-geyser"].autoplace.richness_expression =
    "eon_nauvis_vulcanus_sulfuric_acid_geyser_richness"
else
    set_nauvis_entity_property_expression("sulfuric-acid-geyser", "probability",
        "eon_default_sulfuric_acid_geyser_probability")
    set_nauvis_entity_property_expression("sulfuric-acid-geyser", "richness",
        "eon_default_sulfuric_acid_geyser_richness")
    data.raw.resource["sulfuric-acid-geyser"].autoplace.probability_expression =
    "eon_default_sulfuric_acid_geyser_probability"
    data.raw.resource["sulfuric-acid-geyser"].autoplace.richness_expression =
    "eon_default_sulfuric_acid_geyser_richness"
end

align_resource_decoratives_to_current_resources()

local nauvis_settings = data.raw.planet["nauvis"]
    and data.raw.planet["nauvis"].map_gen_settings
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings

if mask_vulcanus_resources_off_ammonia_ocean and nauvis_settings then
    local skip_ammonia_ocean_mask = {
        ["lithium-brine"] = true,
        ["fluorine-vent"] = true,
    }

    for resource_name, resource in pairs(data.raw.resource) do
        if not skip_ammonia_ocean_mask[resource_name]
            and nauvis_settings[resource_name]
            and resource.autoplace
        then
            local expression = resource.autoplace.probability_expression

            if type(expression) == "string"
                and expression ~= ""
                and not string.find(expression, "eon_mask_off_ammonia_ocean(", 1, true)
            then
                resource.autoplace.probability_expression = mask_off_ammonia_ocean(expression)
            end
        end
    end
end
