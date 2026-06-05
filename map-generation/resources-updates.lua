local terrain = require("map-generation.terrain")

local guarded_resources_enabled = settings.startup["eon-fd-guarded-resources"]
    and settings.startup["eon-fd-guarded-resources"].value

local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value == true

local eon_unrestricted_vulcanus_resource_mode = eon_aquilo_on_fulgora
    and not guarded_resources_enabled

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
    or mask_off_aquilo_resource_tiles(sulfuric_acid_geyser_probability_base_expression)

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

local default_sulfuric_acid_geyser_probability_base_expression =
"(control:sulfuric_acid_geyser:size > 0) * \z
    (clamp(eon_default_sulfuric_acid_geyser_patches, 0, 1) * random_penalty{x = x, y = y, source = 1, amplitude = 1 / 0.020833333333333})"

local default_sulfuric_acid_geyser_probability_expression =
    mask_off_aquilo_resource_tiles(default_sulfuric_acid_geyser_probability_base_expression)

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

local eon_aquilo_nauvis_fluid_resources = {
    ["lithium-brine"] = true,
    ["fluorine-vent"] = true,
}

---@param resource_name string
---@param resource table
---@return nil
local function apply_guarded_resource_biome_mask(resource_name, resource)
    if not eon_aquilo_on_fulgora and eon_aquilo_nauvis_fluid_resources[resource_name] then
        return
    end

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

    if not eon_aquilo_on_fulgora then
        set_nauvis_entity_property_expression("lithium-brine", "probability",
            "eon_nauvis_aquilo_lithium_brine_probability")
        set_nauvis_entity_property_expression("lithium-brine", "richness",
            "eon_nauvis_aquilo_lithium_brine_richness")
        data.raw.resource["lithium-brine"].autoplace.probability_expression =
        "eon_nauvis_aquilo_lithium_brine_probability"
        data.raw.resource["lithium-brine"].autoplace.richness_expression =
        "eon_nauvis_aquilo_lithium_brine_richness"

        set_nauvis_entity_property_expression("fluorine-vent", "probability",
            "eon_nauvis_aquilo_fluorine_vent_probability")
        set_nauvis_entity_property_expression("fluorine-vent", "richness",
            "eon_nauvis_aquilo_fluorine_vent_richness")
        data.raw.resource["fluorine-vent"].autoplace.probability_expression =
        "eon_nauvis_aquilo_fluorine_vent_probability"
        data.raw.resource["fluorine-vent"].autoplace.richness_expression =
        "eon_nauvis_aquilo_fluorine_vent_richness"
    end
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

---@class EonUnrestrictedVulcanusResourceConfig
---@field control string
---@field base_density number
---@field base_spots_per_km2 number
---@field candidate_spot_count integer
---@field regular_patch_set_index integer
---@field seed integer
---@field random_spot_size_minimum number
---@field random_spot_size_maximum number
---@field size_multiplier number
---@field richness number
---@field regular_rq_factor number
---@field starting_rq number
---@field fluid boolean|nil

---@type table<string, EonUnrestrictedVulcanusResourceConfig>
local eon_unrestricted_vulcanus_resource_configs = {
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

---@param resource_name string
---@return boolean
local function should_boost_unrestricted_vulcanus_resource(resource_name)
    if not eon_unrestricted_vulcanus_resource_mode then
        return false
    end

    if not nauvis_settings then
        return false
    end

    return nauvis_settings[resource_name] ~= nil
        and eon_unrestricted_vulcanus_resource_configs[resource_name] ~= nil
end

---@param resource_name string
---@param property_name string
---@return string
local function unrestricted_vulcanus_expression_name(resource_name, property_name)
    return "eon_unrestricted_vulcanus_" .. resource_name:gsub("[^%w_]", "_") .. "_" .. property_name
end

---@param control_name string
---@param property_name string
---@return string
local function control_variable(control_name, property_name)
    return "var('control:" .. control_name .. ":" .. property_name .. "')"
end

---@param expression string
---@param additive_expression string
---@return string
local function add_expression_on_vulcanus_terrain(expression, additive_expression)
    return "max(" .. expression .. ", eon_mask_vulcano_terrain(" .. additive_expression .. "))"
end

---@param config EonUnrestrictedVulcanusResourceConfig
---@return string
local function nauvis_style_vulcanus_patches_expression(config)
    return "resource_autoplace_all_patches{base_density = " .. config.base_density ..
        ", base_spots_per_km2 = " .. config.base_spots_per_km2 ..
        ", candidate_spot_count = " .. config.candidate_spot_count ..
        ", frequency_multiplier = " .. control_variable(config.control, "frequency") ..
        ", has_starting_area_placement = 0" ..
        ", random_spot_size_minimum = " .. config.random_spot_size_minimum ..
        ", random_spot_size_maximum = " .. config.random_spot_size_maximum ..
        ", regular_blob_amplitude_multiplier = 0.125" ..
        ", regular_patch_set_count = default_regular_resource_patch_set_count" ..
        ", regular_patch_set_index = " .. config.regular_patch_set_index ..
        ", regular_rq_factor = " .. config.regular_rq_factor ..
        ", seed1 = " .. config.seed ..
        ", size_multiplier = " .. control_variable(config.control, "size") .. " * " .. config.size_multiplier ..
        ", starting_blob_amplitude_multiplier = 0.125" ..
        ", starting_patch_set_count = default_starting_resource_patch_set_count" ..
        ", starting_patch_set_index = 0" ..
        ", starting_rq_factor = " .. config.starting_rq .. "}"
end

---@param config EonUnrestrictedVulcanusResourceConfig
---@param patches_name string
---@return string
local function nauvis_style_vulcanus_probability_expression(config, patches_name)
    local probability = "(" .. control_variable(config.control, "size") .. " > 0) * clamp(" .. patches_name .. ", 0, 1)"

    if config.fluid then
        probability = probability .. " * random_penalty{x = x, y = y, source = 1, amplitude = 1 / 0.020833333333333}"
    end

    return probability
end

---@param config EonUnrestrictedVulcanusResourceConfig
---@param patches_name string
---@return string
local function nauvis_style_vulcanus_richness_expression(config, patches_name)
    local size = control_variable(config.control, "size")
    local richness = control_variable(config.control, "richness")

    if config.fluid then
        return "(" .. size .. " > 0) * " .. richness .. " * (" ..
            patches_name .. " / 0.020833333333333 + 220000) * max((1000 + distance) / 2600, 1)"
    end

    return "(" .. size .. " > 0) * " .. richness .. " * " ..
        config.richness .. " * " .. patches_name .. " * max((1000 + distance) / 2600, 1)"
end

---@param resource_name string
---@param resource table
---@return nil
local function boost_unrestricted_vulcanus_resource(resource_name, resource)
    if not should_boost_unrestricted_vulcanus_resource(resource_name) or not resource.autoplace then return end

    local config = eon_unrestricted_vulcanus_resource_configs[resource_name]
    local patches_name = unrestricted_vulcanus_expression_name(resource_name, "patches")
    set_or_extend_noise_expression(patches_name, nauvis_style_vulcanus_patches_expression(config))

    local probability_expression = expression_for_autoplace(resource)
    if probability_expression and probability_expression ~= "" then
        local probability_name = unrestricted_vulcanus_expression_name(resource_name, "probability")
        local boosted_probability_expression = add_expression_on_vulcanus_terrain(
            probability_expression,
            nauvis_style_vulcanus_probability_expression(config, patches_name)
        )

        set_or_extend_noise_expression(probability_name,
            mask_off_aquilo_resource_tiles(boosted_probability_expression))
        resource.autoplace.probability_expression = probability_name
        set_nauvis_entity_property_expression(resource_name, "probability", probability_name)
    end

    local richness_expression = richness_expression_for_autoplace(resource)
    if richness_expression and richness_expression ~= "" then
        local richness_name = unrestricted_vulcanus_expression_name(resource_name, "richness")
        local boosted_richness_expression = add_expression_on_vulcanus_terrain(
            richness_expression,
            nauvis_style_vulcanus_richness_expression(config, patches_name)
        )

        set_or_extend_noise_expression(richness_name, boosted_richness_expression)
        resource.autoplace.richness_expression = richness_name
        set_nauvis_entity_property_expression(resource_name, "richness", richness_name)
    end
end

if eon_unrestricted_vulcanus_resource_mode and nauvis_settings then
    for resource_name, resource in pairs(data.raw.resource or {}) do
        boost_unrestricted_vulcanus_resource(resource_name, resource)
    end
end

if mask_vulcanus_resources_off_ammonia_ocean and nauvis_settings then
    for resource_name, resource in pairs(data.raw.resource or {}) do
        if nauvis_settings[resource_name] and resource.autoplace then
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

---@param expression string
---@return boolean
local function has_aquilo_resource_tile_mask(expression)
    return string.find(expression, "eon_mask_off_aquilo_resource_tiles(", 1, true) ~= nil
        or string.find(expression, "eon_mask_aquilo_resource_tiles(", 1, true) ~= nil
end

---@param resource_name string
---@param property_name string
---@return string
local function masked_resource_property_expression_name(resource_name, property_name)
    return "eon_" .. resource_name:gsub("[^%w_]", "_") .. "_aquilo_resource_tile_safe_" .. property_name
end

---@param resource_name string
---@param resource table
---@return nil
local function mask_resource_autoplace_off_invalid_aquilo_tiles(resource_name, resource)
    if not resource.autoplace then return end

    local expression = resource.autoplace.probability_expression
    if type(expression) == "string" and expression ~= "" and not has_aquilo_resource_tile_mask(expression) then
        resource.autoplace.probability_expression = mask_off_aquilo_resource_tiles(expression)
    end

    local nauvis = data.raw.planet["nauvis"]
    local map_gen = nauvis and nauvis.map_gen_settings
    local property_names = map_gen and map_gen.property_expression_names
    if not property_names then return end

    local property_key = "entity:" .. resource_name .. ":probability"
    local property_expression = property_names[property_key]
    if type(property_expression) ~= "string" or property_expression == "" then return end
    if has_aquilo_resource_tile_mask(property_expression) then return end

    local masked_name = masked_resource_property_expression_name(resource_name, "probability")
    set_or_extend_noise_expression(masked_name, mask_off_aquilo_resource_tiles(property_expression))
    property_names[property_key] = masked_name
end

for resource_name, resource in pairs(data.raw.resource or {}) do
    mask_resource_autoplace_off_invalid_aquilo_tiles(resource_name, resource)
end
