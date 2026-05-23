local terrain = require("map-generation.terrain")

local guarded_resources_enabled = settings.startup["eon-fd-guarded-resources"]
    and settings.startup["eon-fd-guarded-resources"].value

---Mask off ammonia ocean.
---@param expression any
local function mask_off_ammonia_ocean(expression)
    return "eon_mask_off_ammonia_ocean(" .. expression .. ")"
end

---Mask vulcanus terrain.
---@param expression any
local function mask_vulcanus_terrain(expression)
    return "eon_mask_vulcano_terrain(" .. expression .. ")"
end

---Mask vulcanus coverage.
---@param expression any
local function mask_vulcanus_coverage(expression)
    return "eon_mask_vulcano_coverage(" .. expression .. ")"
end

---Set resource probability.
---@param resource_name string
---@param expression any
local function set_resource_probability(resource_name, expression)
    data.raw.resource[resource_name].autoplace.probability_expression = expression
end

---Set guarded resource probability.
---@param resource_name string
---@param expression any
local function set_guarded_resource_probability(resource_name, expression)
    set_resource_probability(resource_name, mask_off_ammonia_ocean(mask_vulcanus_coverage(expression)))
end

---Configure guarded resource.
---@param config table
local function configure_guarded_resource(config)
    if guarded_resources_enabled then
        config.guarded()
    else
        config.normal()
    end
end


terrain.mask_resource_territory("iron-ore", "resource")
terrain.mask_resource_territory("copper-ore", "resource")
terrain.mask_resource_territory("stone", "resource")
terrain.mask_resource_territory("coal", "resource")
terrain.mask_resource_territory("uranium-ore", "resource")
terrain.mask_resource_territory("crude-oil", "resource")


data.raw["noise-expression"]["aquilo_crude_oil_spots"].expression = "0"
data.raw.planet["aquilo"].map_gen_settings.autoplace_controls = {}


data.raw["autoplace-control"]["gleba_plants"].localised_description = nil

---Enable planet resource autoplace controls.
---@param planet_name string
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

data.raw["autoplace-control"]["vulcanus_volcanism"].order = "z-volcanism"
data.raw["autoplace-control"]["vulcanus_volcanism"].category = "resource"
data.raw["autoplace-control"]["vulcanus_volcanism"].localised_description = nil

data.raw["autoplace-control"]["sulfuric_acid_geyser"].order = "b-z"

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["calcite"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["sulfuric-acid-geyser"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["tungsten-ore"] = {}

data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["sulfuric_acid_geyser"] = {}

if guarded_resources_enabled then
    data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["calcite"] = {}
    data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["tungsten_ore"] = {}
end

data.raw["noise-expression"]["vulcanus_starting_calcite"].expression = "-inf"

local nauvis_property_expression_names = data.raw.planet["nauvis"].map_gen_settings.property_expression_names

local calcite_probability_expression = mask_off_ammonia_ocean(mask_vulcanus_terrain(
    "(control:calcite:size > 0) * \z
    (1000 * ((1 + vulcanus_calcite_region) * random_penalty_between(0.9, 1, 1) - 1))"
))

local calcite_richness_expression =
"if(eon_vulcanus_terrain, vulcanus_calcite_richness, 0)"

local sulfuric_acid_geyser_probability_expression = mask_off_ammonia_ocean(mask_vulcanus_terrain(
    "(control:sulfuric_acid_geyser:size > 0) * \z
    (0.025 * control:sulfuric_acid_geyser:frequency * \z
    ((vulcanus_sulfuric_acid_region_patchy > 0) + 2 * vulcanus_sulfuric_acid_region_patchy))"
))

local sulfuric_acid_geyser_richness_expression =
"if(eon_vulcanus_terrain, vulcanus_sulfuric_acid_geyser_richness, 0)"

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
    }
})

nauvis_property_expression_names["entity:calcite:probability"] = "eon_nauvis_vulcanus_calcite_probability"
nauvis_property_expression_names["entity:calcite:richness"] = "eon_nauvis_vulcanus_calcite_richness"
data.raw.resource["calcite"].autoplace.probability_expression = "eon_nauvis_vulcanus_calcite_probability"
data.raw.resource["calcite"].autoplace.richness_expression = "eon_nauvis_vulcanus_calcite_richness"

data.raw["noise-expression"]["vulcanus_starting_sulfur"].expression = "-inf"

nauvis_property_expression_names["entity:sulfuric-acid-geyser:probability"] =
"eon_nauvis_vulcanus_sulfuric_acid_geyser_probability"
nauvis_property_expression_names["entity:sulfuric-acid-geyser:richness"] =
"eon_nauvis_vulcanus_sulfuric_acid_geyser_richness"

data.raw.resource["sulfuric-acid-geyser"].autoplace.probability_expression =
"eon_nauvis_vulcanus_sulfuric_acid_geyser_probability"
data.raw.resource["sulfuric-acid-geyser"].autoplace.richness_expression =
"eon_nauvis_vulcanus_sulfuric_acid_geyser_richness"

data.raw["noise-expression"]["vulcanus_starting_tungsten"].expression = "-inf"

configure_guarded_resource {
    ---Guarded .
    guarded = function()
        set_guarded_resource_probability("tungsten-ore", "1000 * vulcanus_tungsten_ore_probability")
        data.raw.resource["tungsten-ore"].autoplace.richness_expression = "vulcanus_tungsten_ore_richness"

        data.raw["noise-expression"]["vulcanus_tungsten_ore_region"].expression =
        "max(vulcanus_starting_tungsten, min(1 - vulcanus_starting_circle, vulcanus_place_non_metal_spots(789, 15, 2, vulcanus_tungsten_ore_size * min(1.2, vulcanus_ore_dist) * 25, control:tungsten_ore:frequency, vulcanus_mountains_resource_favorability)))"
    end,
    ---Normal .
    normal = function()
        data.raw["noise-expression"]["vulcanus_tungsten_ore_probability"].expression =
            mask_off_ammonia_ocean(
                "(control:tungsten_ore:size > 0) * (1000 * ((0.7 + vulcanus_tungsten_ore_region) * random_penalty_between(0.9, 1, 1) - 1))")
        terrain.mask_resource_territory("tungsten-ore", "resource")
    end
}

---Get planet entity settings.
---@param planet_name string
local function get_planet_entity_settings(planet_name)
    local planet = data.raw.planet[planet_name]
    if not planet or not planet.map_gen_settings then return nil end

    local autoplace_settings = planet.map_gen_settings.autoplace_settings
    if not autoplace_settings or not autoplace_settings.entity then return nil end

    return autoplace_settings.entity.settings
end

---Get expression for autoplace.
---@param proto table
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

---Richness expression for autoplace.
---@param proto table
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

---Get planet richness expression.
---@param planet_name string
---@param entity_name string
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

---Get planet probability expression.
---@param planet_name string
---@param entity_name string
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

---Mask expression.
---@param expression any
---@param mask_name string
local function mask_expression(expression, mask_name)
    return mask_name .. "(" .. expression .. ")"
end

---Combine masked expressions.
---@param masked table
local function combine_masked_expressions(masked)
    if #masked == 0 then return nil end
    if #masked == 1 then return masked[1] end

    return "max(" .. table.concat(masked, ", ") .. ")"
end

---Add masked expression.
---@param masked table
---@param expression any
---@param mask_name string
local function add_masked_expression(masked, expression, mask_name)
    table.insert(masked, mask_expression(expression, mask_name))
end

---Apply simple entity biome mask.
---@param entity_name string
---@param mask_name string
local function apply_simple_entity_biome_mask(entity_name, mask_name)
    local proto = data.raw["simple-entity"] and data.raw["simple-entity"][entity_name]
    if not proto or not proto.autoplace then return end

    local expression = expression_for_autoplace(proto)
    if not expression then expression = "1" end

    proto.autoplace.probability_expression = mask_expression(expression, mask_name)
end

---Guarded resource expression for planet.
---@param resource_name string
---@param planet_name string
---@param default_expression any
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

---Set or extend noise expression.
---@param name string
---@param expression any
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

---Set nauvis entity property expression.
---@param entity_name string
---@param property_name string
---@param expression_name string
local function set_nauvis_entity_property_expression(entity_name, property_name, expression_name)
    local nauvis = data.raw.planet["nauvis"]
    if not nauvis or not nauvis.map_gen_settings then return end

    nauvis.map_gen_settings.property_expression_names = nauvis.map_gen_settings.property_expression_names or {}
    nauvis.map_gen_settings.property_expression_names["entity:" .. entity_name .. ":" .. property_name] = expression_name
end

---Apply guarded resource biome mask.
---@param resource_name string
---@param resource table
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

    local expression = combine_masked_expressions(masked)
    if expression then
        resource.autoplace.probability_expression = expression
    end

    if resource_name == "stone" and gleba_settings[resource_name] then
        local default_richness = richness_expression_for_autoplace(resource)
        local gleba_richness = get_planet_richness_expression("gleba", "stone")

        set_or_extend_noise_expression(
            "eon_guarded_stone_probability",
            mask_off_ammonia_ocean(combine_masked_expressions(masked))
        )
        set_nauvis_entity_property_expression("stone", "probability", "eon_guarded_stone_probability")
        resource.autoplace.probability_expression = "eon_guarded_stone_probability"

        if default_richness and gleba_richness then
            local richness_expression = combine_masked_expressions({
                mask_expression(default_richness, "eon_mask_nauvis_territory"),
                mask_expression(gleba_richness, "eon_mask_gleba_territory")
            })

            set_or_extend_noise_expression("eon_guarded_stone_richness", richness_expression)
            set_nauvis_entity_property_expression("stone", "richness", "eon_guarded_stone_richness")
            resource.autoplace.richness_expression = "eon_guarded_stone_richness"
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

        set_or_extend_noise_expression(
            "eon_guarded_coal_probability",
            mask_off_ammonia_ocean(combine_masked_expressions(masked))
        )
        set_nauvis_entity_property_expression("coal", "probability", "eon_guarded_coal_probability")
        resource.autoplace.probability_expression = "eon_guarded_coal_probability"

        if default_richness and vulcanus_richness then
            local richness_expression = combine_masked_expressions({
                mask_expression(default_richness, "eon_mask_nauvis_territory"),
                mask_expression(vulcanus_richness, "eon_mask_vulcano_terrain")
            })

            set_or_extend_noise_expression("eon_guarded_coal_richness", richness_expression)
            set_nauvis_entity_property_expression("coal", "richness", "eon_guarded_coal_richness")
            resource.autoplace.richness_expression = "eon_guarded_coal_richness"
        elseif vulcanus_richness then
            local richness_expression = mask_expression(vulcanus_richness, "eon_mask_vulcano_terrain")

            set_or_extend_noise_expression("eon_guarded_coal_richness", richness_expression)
            set_nauvis_entity_property_expression("coal", "richness", "eon_guarded_coal_richness")
            resource.autoplace.richness_expression = "eon_guarded_coal_richness"
        end
    end
end

---Align guarded resources to biomes.
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
end

local nauvis_settings = data.raw.planet["nauvis"]
    and data.raw.planet["nauvis"].map_gen_settings
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings

if nauvis_settings then
    local skip_ammonia_ocean_mask = {
        ["lithium-brine"] = true,
        ["fluorine-vent"] = true,
    }

    for resource_name, resource in pairs(data.raw.resource) do
        if not skip_ammonia_ocean_mask[resource_name]
            and nauvis_settings[resource_name]
            and resource.autoplace
            and type(resource.autoplace.probability_expression) == "string"
            and resource.autoplace.probability_expression ~= ""
        then
            local expression = resource.autoplace.probability_expression

            if type(expression) == "string" and expression ~= "" then
                if not string.find(expression, "eon_mask_off_ammonia_ocean(", 1, true) then
                    resource.autoplace.probability_expression = mask_off_ammonia_ocean(expression)
                end
            end
        end
    end
end
