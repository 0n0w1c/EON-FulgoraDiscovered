local data_util = require("data-util")

local terrain = {}

local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value == true

local eon_aquilo_planet_name = eon_aquilo_on_fulgora and "fulgora" or "nauvis"

local eon_guarded_resources_enabled = settings.startup["eon-fd-guarded-resources"]
    and settings.startup["eon-fd-guarded-resources"].value == true

local eon_aquilo_resource_tile_mask = "eon_mask_aquilo_resource_tiles"
local eon_off_aquilo_resource_tile_mask = "eon_mask_off_aquilo_resource_tiles"

---@param expression string
---@param in_aquilo_only boolean
---@return string
local function eon_mask_resource_tiles(expression, in_aquilo_only)
    local mask = in_aquilo_only and eon_aquilo_resource_tile_mask or eon_off_aquilo_resource_tile_mask
    return mask .. "(" .. expression .. ")"
end

local eon_aquilo_north_bias_y_offset = eon_aquilo_on_fulgora and 650 or -250

local eon_aquilo_exclusion_mask = eon_aquilo_on_fulgora
    and "eon_identity"
    or "eon_mask_off_vulcano_coverage"

local eon_ammonia_ocean_tile_mask = "eon_mask_aquilo_territory"

local eon_ammonia_ocean_tile_expression = eon_aquilo_on_fulgora
    and "eon_aquilo_ammonia_core"
    or "eon_aquilo_ammonia"

local eon_aquilo_decorative_mask = "eon_mask_aquilo_territory"

local eon_vulcanus_off_aquilo_mask = eon_aquilo_on_fulgora
    and "eon_identity"
    or "eon_mask_off_aquilo_territory"

local eon_aquilo_snow_decorative_mask = eon_aquilo_on_fulgora
    and "eon_identity"
    or "eon_mask_aquilo_territory"

local eon_nauvis_territory_expression = eon_aquilo_on_fulgora
    and "eon_mask_off_gleba_territory(eon_mask_off_vulcano_terrain(expression))"
    or "eon_mask_off_aquilo_territory(eon_mask_off_gleba_territory(eon_mask_off_vulcano_terrain(expression)))"

local eon_nauvis_cliffiness_expression = eon_aquilo_on_fulgora
    and "(main_cliffiness >= cliff_cutoff) * 10"
    or "eon_mask_off_aquilo_territory((main_cliffiness >= cliff_cutoff) * 10)"

local eon_fulgora_cliffiness_expression = eon_aquilo_on_fulgora
    and "eon_mask_off_aquilo_territory(fulgora_cliffiness)"
    or "fulgora_cliffiness"

local eon_gleba_region_expression =
"eon_mask_off_vulcano_terrain(if(gleba_noise + gleba_intermediate_noise + gleba_small_noise + moisture_nauvis + south_offset > threshold, 1, 0))"

local eon_gleba_mask_threshold = -10
local eon_gleba_south_bias_y_offset = eon_aquilo_on_fulgora and 1000 or 1500

local eon_vulcanus_coverage_expression = eon_aquilo_on_fulgora
    and "eon_vulcanus_region(0)"
    or
    "max(eon_updated_volcanic_folds, eon_lava_mountains_range, eon_lava_hot_mountains_range, eon_volcano_cracks_warm_range) > 0"

local eon_vulcanus_terrain_expression = eon_aquilo_on_fulgora
    and "eon_vulcanus_region(0)"
    or "max(eon_vulcano_coverage, eon_updated_volcanic_folds_flat) > 0"

local eon_vulcanus_tree_on_nauvis_expression =
    "min(10 * (vulcanus_ashlands_biome - 0.75), " ..
    "4 * (-1.5 + 1.5 * vulcanus_moisture + 0.5 * (vulcanus_moisture > 0.9) - " ..
    "0.5 * vulcanus_aux + 0.5 * vulcanus_decorative_knockout))"

local eon_gleba_continuous_cliffiness_expression = "clamp(quick_multioctave_noise{x = x,\z
                                                       y = y,\z
                                                       seed0 = map_seed,\z
                                                       seed1 = 456,\z
                                                       octaves = 2,\z
                                                       input_scale = 1/128,\z
                                                       output_scale = 1.5}, 0, 1)"

local eon_vulcanus_cliffiness_expression = "clamp(quick_multioctave_noise{x = x,\z
                                                  y = y,\z
                                                  seed0 = map_seed,\z
                                                  seed1 = 123,\z
                                                  octaves = 4,\z
                                                  input_scale = 1/48,\z
                                                  output_scale = 1} * 1.4, 0, 1)"

local eon_blended_cliffiness_expression = "if(eon_vulcanus_terrain,\z
                                          eon_vulcanus_cliffiness * 2,\z
                                          if(eon_gleba_mask,\z
                                             eon_gleba_continuous_cliffiness,\z
                                             cliffiness_nauvis * 0.8))"

local eon_blended_cliff_elevation_expression = "if(eon_vulcanus_terrain,\z
                                               elevation * 1.5,\z
                                               if(eon_gleba_mask,\z
                                                  gleba_elevation * 0.2,\z
                                                  cliff_elevation_nauvis * 0.4))"

local eon_aquilo_decorative_names = {
    ["lithium-iceberg-medium"] = true,
    ["lithium-iceberg-small"] = true,
    ["lithium-iceberg-tiny"] = true,
    ["floating-iceberg-large"] = true,
    ["floating-iceberg-small"] = true,
    ["aqulio-ice-decal-blue"] = true,
    ["aqulio-snowy-decal"] = true,
    ["snow-drift-decal"] = true,
}

local eon_aquilo_entity_names = {
    ["lithium-brine"] = true,
    ["fluorine-vent"] = true,
    ["lithium-iceberg-huge"] = true,
    ["lithium-iceberg-big"] = true,
}

local eon_aquilo_tile_names = {
    ["snow-flat"] = true,
    ["snow-crests"] = true,
    ["snow-lumpy"] = true,
    ["snow-patchy"] = true,
    ["ice-rough"] = true,
    ["ice-smooth"] = true,
    ["brash-ice"] = true,
    ["ammoniacal-ocean"] = true,
    ["ammoniacal-ocean-2"] = true,
}

local eon_aquilo_snow_decorative_tile_names = {
    "snow-flat",
    "snow-crests",
    "snow-lumpy",
    "snow-patchy",
    "ice-rough",
    "ice-smooth",
    "fulgoran-rock",
    "fulgoran-dust",
    "fulgoran-sand",
    "fulgoran-dunes",
    "fulgoran-walls",
    "fulgoran-paving",
    "fulgoran-conduit",
    "fulgoran-machinery",
}

---@param prototype table?
---@param wrapper string
---@return nil
local function eon_wrap_probability_expression(prototype, wrapper)
    if not prototype or not prototype.autoplace then return end
    local expression = prototype.autoplace.probability_expression
    if type(expression) == "string" and expression ~= "" then
        if not string.find(expression, wrapper .. "%(", 1, false) then
            prototype.autoplace.probability_expression = wrapper .. "(" .. expression .. ")"
        end
    end
end

---@param value any
---@return table<string, string>?
local function eon_normalize_local_expressions(value)
    if type(value) ~= "table" then
        return nil
    end

    local local_expressions = {}

    for name, expression in pairs(value) do
        if type(name) == "string" and type(expression) == "string" then
            local_expressions[name] = expression
        end
    end

    return next(local_expressions) and local_expressions or nil
end

---@param name string
---@param expression string
---@param local_expressions table<string, string>?
---@return nil
local function eon_set_or_extend_noise_expression(name, expression, local_expressions)
    local noise_expression = data.raw["noise-expression"] and data.raw["noise-expression"][name]

    if noise_expression then
        noise_expression.expression = expression
        noise_expression.local_expressions = local_expressions
        return
    end

    data:extend({
        {
            type = "noise-expression",
            name = name,
            expression = expression,
            local_expressions = local_expressions,
        }
    })
end

---@return nil
local function eon_mask_fulgora_oil_ocean_off_aquilo_ocean_edge()
    for _, tile_name in pairs({ "oil-ocean-deep", "oil-ocean-shallow" }) do
        local tile = data.raw.tile and data.raw.tile[tile_name]
        eon_wrap_probability_expression(tile, "eon_mask_off_aquilo_ocean_edge")
    end
end

---@param entity_name string
---@return table? prototype Prototype with an autoplace probability expression, when one exists.
local function eon_autoplace_entity_prototype(entity_name)
    for _, prototype_type in pairs({ "resource", "simple-entity", "lightning-attractor" }) do
        local prototypes = data.raw[prototype_type]
        local prototype = prototypes and prototypes[entity_name]
        if prototype and prototype.autoplace then
            return prototype
        end
    end

    return nil
end

---@param prototype_type any
---@param prototype_name string
---@param tile_names string[]
---@return nil
local function eon_restrict_autoplace_to_tiles(prototype_type, prototype_name, tile_names)
    local prototypes = data.raw[prototype_type]
    if not prototypes then return end

    local prototype = prototypes[prototype_name]
    if not prototype or not prototype.autoplace then return end

    prototype.autoplace.tile_restriction = tile_names
end

---@param prototype_type any
---@param prototype_name string
---@param tile_names string[]
---@return nil
local function eon_extend_autoplace_tile_restriction(prototype_type, prototype_name, tile_names)
    local prototypes = data.raw[prototype_type]
    if not prototypes then return end

    local prototype = prototypes[prototype_name]
    if not prototype or not prototype.autoplace then return end

    local seen = {}
    local merged = {}

    if prototype.autoplace.tile_restriction then
        for _, tile_name in pairs(prototype.autoplace.tile_restriction) do
            if not seen[tile_name] then
                seen[tile_name] = true
                table.insert(merged, tile_name)
            end
        end
    end

    for _, tile_name in ipairs(tile_names) do
        if not seen[tile_name] then
            seen[tile_name] = true
            table.insert(merged, tile_name)
        end
    end

    prototype.autoplace.tile_restriction = merged
end

---@return nil
local function eon_apply_aquilo_on_fulgora_snow_decorative_rules()
    if not eon_aquilo_on_fulgora then return end

    eon_extend_autoplace_tile_restriction("optimized-decorative",
        "aqulio-snowy-decal",
        eon_aquilo_snow_decorative_tile_names)

    eon_restrict_autoplace_to_tiles("optimized-decorative",
        "snow-drift-decal",
        eon_aquilo_snow_decorative_tile_names)
end

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
    local mask = prototype_type == "resource" and eon_aquilo_resource_tile_mask or "eon_mask_aquilo_territory"
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
    data.raw[decorative_type][decorative].autoplace.probability_expression = eon_aquilo_decorative_mask .. "(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---@param decorative string
---@param decorative_type string
---@return nil
function terrain.mask_aquilo_snow_decorative_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = eon_aquilo_snow_decorative_mask .. "(" ..
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

data:extend({
    {
        type = "noise-expression",
        name = "eon_starting_radius",
        expression = "0.7 * 0.75"
    },
})

data.raw.tile["water"].autoplace.probability_expression = "eon_updated_water + if(eon_gleba_region(-10), -inf, 0)"
data.raw.tile["deepwater"].autoplace.probability_expression =
"eon_updated_deepwater + if(eon_gleba_region(-100), -inf, 0)"

data.raw["noise-expression"]["trees_forest_path_cutout_faded"].expression =
"eon_mask_nauvis_territory(trees_forest_path_cutout * 0.3 + tree_small_noise * 0.1)"

terrain.mask_nauvis_territory("cracked-mud-decal", "optimized-decorative")
terrain.mask_nauvis_territory("dark-mud-decal", "optimized-decorative")
terrain.mask_nauvis_territory("lichen-decal", "optimized-decorative")
terrain.mask_nauvis_territory("light-mud-decal", "optimized-decorative")
terrain.mask_nauvis_territory("small-rock", "optimized-decorative")
terrain.mask_nauvis_territory("small-sand-rock", "optimized-decorative")
terrain.mask_nauvis_territory("tiny-rock", "optimized-decorative")

terrain.mask_nauvis_territory("big-rock", "simple-entity")
terrain.mask_nauvis_territory("big-sand-rock", "simple-entity")
terrain.mask_nauvis_territory("brown-asterisk", "optimized-decorative")
terrain.mask_nauvis_territory("brown-asterisk-mini", "optimized-decorative")
terrain.mask_nauvis_territory("brown-carpet-grass", "optimized-decorative")
terrain.mask_nauvis_territory("brown-fluff", "optimized-decorative")
terrain.mask_nauvis_territory("brown-fluff-dry", "optimized-decorative")
terrain.mask_nauvis_territory("brown-hairy-grass", "optimized-decorative")
terrain.mask_nauvis_territory("garballo", "optimized-decorative")
terrain.mask_nauvis_territory("garballo-mini-dry", "optimized-decorative")
terrain.mask_nauvis_territory("green-asterisk", "optimized-decorative")
terrain.mask_nauvis_territory("green-asterisk-mini", "optimized-decorative")
terrain.mask_nauvis_territory("green-bush-mini", "optimized-decorative")
terrain.mask_nauvis_territory("green-carpet-grass", "optimized-decorative")
terrain.mask_nauvis_territory("green-croton", "optimized-decorative")
terrain.mask_nauvis_territory("green-desert-bush", "optimized-decorative")
terrain.mask_nauvis_territory("green-hairy-grass", "optimized-decorative")
terrain.mask_nauvis_territory("green-pita", "optimized-decorative")
terrain.mask_nauvis_territory("green-pita-mini", "optimized-decorative")
terrain.mask_nauvis_territory("green-small-grass", "optimized-decorative")
terrain.mask_nauvis_territory("huge-rock", "simple-entity")
terrain.mask_nauvis_territory("medium-rock", "optimized-decorative")
terrain.mask_nauvis_territory("medium-sand-rock", "optimized-decorative")
terrain.mask_nauvis_territory("red-asterisk", "optimized-decorative")
terrain.mask_nauvis_territory("red-croton", "optimized-decorative")
terrain.mask_nauvis_territory("red-desert-bush", "optimized-decorative")
terrain.mask_nauvis_territory("red-desert-decal", "optimized-decorative")
terrain.mask_nauvis_territory("red-pita", "optimized-decorative")
terrain.mask_nauvis_territory("sand-decal", "optimized-decorative")
terrain.mask_nauvis_territory("sand-dune-decal", "optimized-decorative")
terrain.mask_nauvis_territory("white-desert-bush", "optimized-decorative")

terrain.mask_nauvis_territory("grass-1", "tile")
terrain.mask_nauvis_territory("grass-2", "tile")
terrain.mask_nauvis_territory("grass-3", "tile")
terrain.mask_nauvis_territory("grass-4", "tile")
terrain.mask_nauvis_territory("dry-dirt", "tile")
terrain.mask_nauvis_territory("dirt-1", "tile")
terrain.mask_nauvis_territory("dirt-2", "tile")
terrain.mask_nauvis_territory("dirt-3", "tile")
terrain.mask_nauvis_territory("dirt-4", "tile")
terrain.mask_nauvis_territory("dirt-5", "tile")
terrain.mask_nauvis_territory("dirt-6", "tile")
terrain.mask_nauvis_territory("dirt-7", "tile")
terrain.mask_nauvis_territory("sand-1", "tile")
terrain.mask_nauvis_territory("sand-2", "tile")
terrain.mask_nauvis_territory("sand-3", "tile")
terrain.mask_nauvis_territory("red-desert-0", "tile")
terrain.mask_nauvis_territory("red-desert-1", "tile")
terrain.mask_nauvis_territory("red-desert-2", "tile")
terrain.mask_nauvis_territory("red-desert-3", "tile")

data.raw["noise-expression"]["cliffiness_nauvis"].expression = eon_nauvis_cliffiness_expression

---@return nil
local function eon_apply_blended_nauvis_cliff_settings()
    local nauvis = data.raw.planet and data.raw.planet["nauvis"]
    if not (nauvis and nauvis.map_gen_settings) then return end

    nauvis.map_gen_settings.property_expression_names = nauvis.map_gen_settings.property_expression_names or {}
    nauvis.map_gen_settings.property_expression_names["cliffiness"] = "eon_blended_cliffiness"
    nauvis.map_gen_settings.property_expression_names["cliff_elevation"] = "eon_blended_cliff_elevation"

    local cliff_settings = nauvis.map_gen_settings.cliff_settings
    if cliff_settings then
        cliff_settings.cliff_smoothing = 0
        cliff_settings.cliff_elevation_interval = 12
        cliff_settings.richness = 1.0
    end
end

data:extend({
    {
        type = "noise-expression",
        name = "eon_updated_water",
        expression = "eon_mask_nauvis_territory(eon_water_base(0, 100) + eon_gleba_region(-100))"
    },
    {
        type = "noise-expression",
        name = "eon_updated_deepwater",
        expression = "eon_mask_nauvis_territory(eon_water_base(-2, 200))"
    },
    {
        type = "noise-expression",
        name = "eon_gleba_continuous_cliffiness",
        expression = eon_gleba_continuous_cliffiness_expression
    },
    {
        type = "noise-expression",
        name = "eon_vulcanus_cliffiness",
        expression = eon_vulcanus_cliffiness_expression
    },
    {
        type = "noise-expression",
        name = "eon_blended_cliffiness",
        expression = eon_blended_cliffiness_expression
    },
    {
        type = "noise-expression",
        name = "eon_blended_cliff_elevation",
        expression = eon_blended_cliff_elevation_expression
    },
    {
        type = "noise-expression",
        name = "eon_resource_territory",
        expression = "eon_aquilo_base(eon_aquilo_ammonia_depth + 2, 200)"
    },
    {
        type = "noise-function",
        name = "eon_identity",
        parameters = { "expression" },
        expression = "expression"
    },
    {
        type = "noise-function",
        name = "eon_mask_nauvis_territory",
        parameters = { "expression" },
        expression = eon_nauvis_territory_expression
    },
    {
        type = "noise-function",
        name = "eon_mask_off_nauvis_territory",
        parameters = { "expression" },
        expression = "if(eon_mask_nauvis_territory(expression) < 0, expression, -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_resource_territory",
        parameters = { "expression" },
        expression =
        "if(eon_resource_territory <= 0, if(eon_aquilo_mask, if(eon_aquilo_resource_placeable_land, expression, -inf), expression), -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_fulgora_aquilo_territory",
        parameters = { "expression" },
        expression = "if(y < eon_fulgora_aquilo_boundary, expression, -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_off_fulgora_aquilo_territory",
        parameters = { "expression" },
        expression = "if(eon_fulgora_aquilo_territory_mask, -inf, expression)"
    },
})

eon_apply_blended_nauvis_cliff_settings()

local eon_aquilo_map_gen = data.raw.planet[eon_aquilo_planet_name].map_gen_settings
local eon_inactive_aquilo_planet_name = eon_aquilo_on_fulgora and "nauvis" or "fulgora"
local eon_inactive_aquilo_map_gen = data.raw.planet[eon_inactive_aquilo_planet_name]
    and data.raw.planet[eon_inactive_aquilo_planet_name].map_gen_settings

local eon_aquilo_autoplace_controls = {
    "lithium_brine",
    "fluorine_vent",
}

local eon_all_aquilo_autoplace_controls = {
    "lithium_brine",
    "fluorine_vent",
    "ammonia_ocean",
}

if data.raw.resource["lithium-brine"] and data.raw.resource["lithium-brine"].autoplace then
    data.raw.resource["lithium-brine"].autoplace.control = "lithium_brine"
end

if data.raw.resource["fluorine-vent"] and data.raw.resource["fluorine-vent"].autoplace then
    data.raw.resource["fluorine-vent"].autoplace.control = "fluorine_vent"
end

---@param planet_name string
---@param property_key string
---@param expression_name string
---@return nil
local function eon_set_property_expression(planet_name, property_key, expression_name)
    local planet = data.raw.planet[planet_name]
    if not planet or not planet.map_gen_settings then return end

    planet.map_gen_settings.property_expression_names = planet.map_gen_settings.property_expression_names or {}
    planet.map_gen_settings.property_expression_names[property_key] = expression_name
end

---@param planet_name string
---@param entity_name string
---@param property_name string
---@param expression_name string
---@return nil
local function eon_set_entity_property_expression(planet_name, entity_name, property_name, expression_name)
    eon_set_property_expression(planet_name, "entity:" .. entity_name .. ":" .. property_name, expression_name)
end

---@param planet_name string
---@param decorative_name string
---@param expression_name string
---@return nil
local function eon_set_decorative_probability_expression(planet_name, decorative_name, expression_name)
    eon_set_property_expression(planet_name, "decorative:" .. decorative_name .. ":probability", expression_name)
end

table.insert(eon_aquilo_autoplace_controls, "ammonia_ocean")

---@param map_gen any
---@return nil
local function eon_enable_aquilo_autoplace_controls(map_gen)
    if not map_gen then return end

    map_gen.autoplace_controls = map_gen.autoplace_controls or {}

    for _, control_name in pairs(eon_aquilo_autoplace_controls) do
        map_gen.autoplace_controls[control_name] = {}
    end
end

---@param planet_name string
---@param resource_name string
---@param property_name string
---@param expression any
---@return nil
local function eon_set_resource_property_expression_if_string(
    planet_name,
    resource_name,
    property_name,
    expression
)
    if type(expression) ~= "string" then return end

    eon_set_entity_property_expression(
        planet_name,
        resource_name,
        property_name,
        expression
    )
end

---@param map_gen any
---@return nil
local function eon_disable_aquilo_autoplace_controls(map_gen)
    if not (map_gen and map_gen.autoplace_controls) then return end

    for _, control_name in pairs(eon_all_aquilo_autoplace_controls) do
        map_gen.autoplace_controls[control_name] = nil
    end
end

if eon_aquilo_map_gen then
    eon_enable_aquilo_autoplace_controls(eon_aquilo_map_gen)
    eon_disable_aquilo_autoplace_controls(eon_inactive_aquilo_map_gen)

    eon_aquilo_map_gen.autoplace_settings.tile.settings["snow-flat"] = {}
    eon_aquilo_map_gen.autoplace_settings.tile.settings["snow-crests"] = {}
    eon_aquilo_map_gen.autoplace_settings.tile.settings["snow-lumpy"] = {}
    eon_aquilo_map_gen.autoplace_settings.tile.settings["snow-patchy"] = {}
    eon_aquilo_map_gen.autoplace_settings.tile.settings["ice-rough"] = {}
    eon_aquilo_map_gen.autoplace_settings.tile.settings["ice-smooth"] = {}
    eon_aquilo_map_gen.autoplace_settings.tile.settings["brash-ice"] = {}
    eon_aquilo_map_gen.autoplace_settings.tile.settings["ammoniacal-ocean"] = {}
    eon_aquilo_map_gen.autoplace_settings.tile.settings["ammoniacal-ocean-2"] = {}

    eon_aquilo_map_gen.autoplace_settings.decorative.settings["lithium-iceberg-medium"] = {}
    eon_aquilo_map_gen.autoplace_settings.decorative.settings["lithium-iceberg-small"] = {}
    eon_aquilo_map_gen.autoplace_settings.decorative.settings["lithium-iceberg-tiny"] = {}
    eon_aquilo_map_gen.autoplace_settings.decorative.settings["floating-iceberg-large"] = {}
    eon_aquilo_map_gen.autoplace_settings.decorative.settings["floating-iceberg-small"] = {}
    eon_aquilo_map_gen.autoplace_settings.decorative.settings["aqulio-ice-decal-blue"] = {}
    eon_aquilo_map_gen.autoplace_settings.decorative.settings["aqulio-snowy-decal"] = {}
    eon_aquilo_map_gen.autoplace_settings.decorative.settings["snow-drift-decal"] = {}

    eon_aquilo_map_gen.autoplace_settings.entity.settings["lithium-brine"] = {}
    eon_aquilo_map_gen.autoplace_settings.entity.settings["fluorine-vent"] = {}
    eon_aquilo_map_gen.autoplace_settings.entity.settings["lithium-iceberg-huge"] = {}
    eon_aquilo_map_gen.autoplace_settings.entity.settings["lithium-iceberg-big"] = {}
end

if eon_aquilo_on_fulgora then
    data.raw.planet["fulgora"].map_gen_settings.property_expression_names =
        data.raw.planet["fulgora"].map_gen_settings.property_expression_names or {}
    data.raw.planet["fulgora"].map_gen_settings.property_expression_names["cliffiness"] =
    "eon_fulgora_cliffiness_off_aquilo"

    local fulgora_settings = data.raw.planet["fulgora"].map_gen_settings.autoplace_settings

    if fulgora_settings then
        for tile_name, _ in pairs(fulgora_settings.tile.settings) do
            if not eon_aquilo_tile_names[tile_name] and data.raw.tile[tile_name] then
                eon_wrap_probability_expression(data.raw.tile[tile_name],
                    "eon_mask_off_aquilo_territory")
            end
        end

        for decorative_name, _ in pairs(fulgora_settings.decorative.settings) do
            if not eon_aquilo_decorative_names[decorative_name] then
                eon_wrap_probability_expression(data.raw["optimized-decorative"][decorative_name],
                    "eon_mask_off_aquilo_territory")
            end
        end
    end

    eon_mask_fulgora_oil_ocean_off_aquilo_ocean_edge()

    if fulgora_settings then
        for entity_name, _ in pairs(fulgora_settings.entity.settings) do
            if not eon_aquilo_entity_names[entity_name] then
                eon_wrap_probability_expression(
                    eon_autoplace_entity_prototype(entity_name),
                    "eon_mask_off_aquilo_territory")
            end
        end

        eon_wrap_probability_expression(
            eon_autoplace_entity_prototype("fulgoran-ruin-attractor"),
            "eon_mask_off_aquilo_territory")
    end

    local fulgora_aquilo_resources = {
        ["lithium-brine"] = true,
        ["fluorine-vent"] = true,
    }

    for resource_name, _ in pairs(fulgora_aquilo_resources) do
        local resource = data.raw.resource and data.raw.resource[resource_name]

        if resource and resource.autoplace then
            local probability_expression_name = "eon_fulgora_aquilo_" ..
                string.gsub(resource_name, "[^%w_]", "_") .. "_probability"
            local original_probability_expression_name = data_util.generate_eon_name(resource_name)

            eon_set_or_extend_noise_expression(
                probability_expression_name,
                eon_mask_resource_tiles(original_probability_expression_name, true)
            )

            resource.autoplace.probability_expression = probability_expression_name
            eon_set_entity_property_expression("fulgora", resource_name, "probability", probability_expression_name)
            eon_set_resource_property_expression_if_string(
                "fulgora",
                resource_name,
                "richness",
                resource.autoplace.richness_expression
            )
        end
    end

    local scrap = data.raw.resource and data.raw.resource["scrap"]
    if scrap and scrap.autoplace then
        local probability_expression = scrap.autoplace.probability_expression

        if type(probability_expression) == "string" then
            local probability_expression_name = "eon_fulgora_scrap_probability"
            local richness_expression_name = "eon_fulgora_scrap_richness"
            local scrap_local_expressions = eon_normalize_local_expressions(scrap.autoplace.local_expressions)

            eon_set_or_extend_noise_expression(
                probability_expression_name,
                "eon_mask_off_aquilo_territory(" .. probability_expression .. ")",
                scrap_local_expressions
            )

            scrap.autoplace.probability_expression = probability_expression_name
            eon_set_entity_property_expression("fulgora", "scrap", "probability", probability_expression_name)

            local richness_expression = scrap.autoplace.richness_expression
            if type(richness_expression) == "string" then
                eon_set_or_extend_noise_expression(
                    richness_expression_name,
                    richness_expression,
                    scrap_local_expressions
                )
                eon_set_entity_property_expression("fulgora", "scrap", "richness", richness_expression_name)
            end
        end
    end
end

if eon_guarded_resources_enabled then
    terrain.mask_aquilo_territory("lithium-brine", "resource")
    terrain.mask_aquilo_territory("fluorine-vent", "resource")
end

if not eon_aquilo_on_fulgora then
    local lithium_brine = data.raw.resource["lithium-brine"]
    if lithium_brine and lithium_brine.autoplace then
        eon_set_resource_property_expression_if_string(
            "nauvis",
            "lithium-brine",
            "probability",
            lithium_brine.autoplace.probability_expression
        )
        eon_set_resource_property_expression_if_string(
            "nauvis",
            "lithium-brine",
            "richness",
            lithium_brine.autoplace.richness_expression
        )
    end

    local fluorine_vent = data.raw.resource["fluorine-vent"]
    if fluorine_vent and fluorine_vent.autoplace then
        eon_set_resource_property_expression_if_string(
            "nauvis",
            "fluorine-vent",
            "probability",
            fluorine_vent.autoplace.probability_expression
        )
        eon_set_resource_property_expression_if_string(
            "nauvis",
            "fluorine-vent",
            "richness",
            fluorine_vent.autoplace.richness_expression
        )
    end
end

terrain.mask_aquilo_territory("snow-crests", "tile")
terrain.mask_aquilo_territory("snow-lumpy", "tile")
terrain.mask_aquilo_territory("snow-patchy", "tile")

terrain.mask_aquilo_decorative_territory("lithium-iceberg-medium", "optimized-decorative")
terrain.mask_aquilo_decorative_territory("lithium-iceberg-small", "optimized-decorative")
terrain.mask_aquilo_decorative_territory("lithium-iceberg-tiny", "optimized-decorative")
terrain.mask_aquilo_decorative_territory("floating-iceberg-large", "optimized-decorative")
terrain.mask_aquilo_decorative_territory("floating-iceberg-small", "optimized-decorative")
terrain.mask_aquilo_decorative_territory("aqulio-ice-decal-blue", "optimized-decorative")
terrain.mask_aquilo_snow_decorative_territory("aqulio-snowy-decal", "optimized-decorative")
terrain.mask_aquilo_snow_decorative_territory("snow-drift-decal", "optimized-decorative")

terrain.mask_aquilo_territory("lithium-iceberg-huge", "simple-entity")
terrain.mask_aquilo_territory("lithium-iceberg-big", "simple-entity")

if not eon_aquilo_on_fulgora then
    ---@class EonNauvisAquiloFluidResourceConfig
    ---@field resource_name string
    ---@field expression_name string
    ---@field control string
    ---@field seed integer
    ---@field guarded_count integer
    ---@field skip_offset integer
    ---@field guarded_radius number
    ---@field unrestricted_patch_index integer
    ---@field unrestricted_seed integer
    ---@field probability_multiplier number
    ---@field richness number

    ---@type EonNauvisAquiloFluidResourceConfig[]
    local eon_nauvis_aquilo_fluid_resource_configs = {
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

    ---@param control string
    ---@param property string
    ---@return string
    local function eon_control_expression(control, property)
        return "control:" .. control .. ":" .. property
    end

    ---@param config EonNauvisAquiloFluidResourceConfig
    ---@param property string
    ---@return string
    local function eon_nauvis_aquilo_fluid_expression_name(config, property)
        return "eon_nauvis_aquilo_" .. config.expression_name .. "_" .. property
    end

    ---@param config EonNauvisAquiloFluidResourceConfig
    ---@return string
    local function eon_nauvis_aquilo_fluid_spots_expression(config)
        local frequency = eon_control_expression(config.control, "frequency")
        local size = eon_control_expression(config.control, "size")

        if eon_guarded_resources_enabled then
            return "aquilo_spot_noise{seed = " .. config.seed ..
                ", count = " .. config.guarded_count ..
                ", skip_offset = " .. config.skip_offset ..
                ", region_size = 600 + 400 / " .. frequency ..
                ", density = 1" ..
                ", radius = aquilo_spot_size * " .. config.guarded_radius .. " * sqrt(" .. size .. ")" ..
                ", favorability = 1}"
        end

        return "resource_autoplace_all_patches{base_density = 8.2" ..
            ", base_spots_per_km2 = 1.8" ..
            ", candidate_spot_count = 21" ..
            ", frequency_multiplier = " .. frequency ..
            ", has_starting_area_placement = 0" ..
            ", random_spot_size_minimum = 1" ..
            ", random_spot_size_maximum = 1" ..
            ", regular_blob_amplitude_multiplier = 0.125" ..
            ", regular_patch_set_count = default_regular_resource_patch_set_count" ..
            ", regular_patch_set_index = " .. config.unrestricted_patch_index ..
            ", regular_rq_factor = 0.1" ..
            ", seed1 = " .. config.unrestricted_seed ..
            ", size_multiplier = " .. size ..
            ", starting_blob_amplitude_multiplier = 0.125" ..
            ", starting_patch_set_count = default_starting_resource_patch_set_count" ..
            ", starting_patch_set_index = 0" ..
            ", starting_rq_factor = 0.14285714285714}"
    end

    ---@param config EonNauvisAquiloFluidResourceConfig
    ---@param spots_name string
    ---@return string
    local function eon_nauvis_aquilo_fluid_probability_expression(config, spots_name)
        local size = eon_control_expression(config.control, "size")

        if eon_guarded_resources_enabled then
            return eon_mask_resource_tiles(
                "(" .. size .. " > 0) * max(0, " .. spots_name .. ") * " .. config.probability_multiplier,
                true)
        end

        return eon_mask_resource_tiles(
            "(" .. size .. " > 0) * (clamp(" .. spots_name ..
            ", 0, 1) * random_penalty{x = x, y = y, source = 1, amplitude = 1 / 0.020833333333333})",
            false)
    end

    ---@param config EonNauvisAquiloFluidResourceConfig
    ---@param spots_name string
    ---@return string
    local function eon_nauvis_aquilo_fluid_richness_expression(config, spots_name)
        local size = eon_control_expression(config.control, "size")
        local richness = eon_control_expression(config.control, "richness")

        if eon_guarded_resources_enabled then
            return "max(0, " .. spots_name .. ") * " .. config.richness .. " * " .. richness
        end

        return "(" .. size .. " > 0) * (" .. richness .. " * (" .. spots_name ..
            " / 0.020833333333333 + 220000) * max((1000 + distance) / 2600, 1))"
    end

    ---@param resource_name string
    ---@param probability_name string
    ---@param richness_name string
    ---@return nil
    local function eon_assign_nauvis_aquilo_fluid_resource(resource_name, probability_name, richness_name)
        local resource = data.raw.resource[resource_name]
        if not resource or not resource.autoplace then return end

        resource.autoplace.probability_expression = probability_name
        resource.autoplace.richness_expression = richness_name
        eon_set_entity_property_expression("nauvis", resource_name, "probability", probability_name)
        eon_set_entity_property_expression("nauvis", resource_name, "richness", richness_name)
    end

    local eon_fluid_resource_spots = "max(eon_nauvis_aquilo_lithium_brine_spots, eon_nauvis_aquilo_fluorine_vent_spots)"
    local eon_fluid_resource_expressions = {}

    for _, config in ipairs(eon_nauvis_aquilo_fluid_resource_configs) do
        local spots_name = eon_nauvis_aquilo_fluid_expression_name(config, "spots")
        local probability_name = eon_nauvis_aquilo_fluid_expression_name(config, "probability")
        local richness_name = eon_nauvis_aquilo_fluid_expression_name(config, "richness")

        table.insert(eon_fluid_resource_expressions, {
            type = "noise-expression",
            name = spots_name,
            expression = eon_nauvis_aquilo_fluid_spots_expression(config),
        })
        table.insert(eon_fluid_resource_expressions, {
            type = "noise-expression",
            name = probability_name,
            expression = eon_nauvis_aquilo_fluid_probability_expression(config, spots_name),
        })
        table.insert(eon_fluid_resource_expressions, {
            type = "noise-expression",
            name = richness_name,
            expression = eon_nauvis_aquilo_fluid_richness_expression(config, spots_name),
        })

        eon_assign_nauvis_aquilo_fluid_resource(config.resource_name, probability_name, richness_name)
    end

    table.insert(eon_fluid_resource_expressions, {
        type = "noise-expression",
        name = "eon_nauvis_aquilo_fluid_resource_snow_decal",
        expression = eon_mask_resource_tiles(
            "min(0.055, 0.9 * clamp(" .. eon_fluid_resource_spots .. " - 0.16, 0, 1))",
            eon_guarded_resources_enabled),
    })
    table.insert(eon_fluid_resource_expressions, {
        type = "noise-expression",
        name = "eon_nauvis_aquilo_fluid_resource_snow_drift",
        expression = eon_mask_resource_tiles(
            "min(0.018, 0.35 * clamp(" .. eon_fluid_resource_spots .. " - 0.24, 0, 1))",
            eon_guarded_resources_enabled),
    })

    data:extend(eon_fluid_resource_expressions)

    local eon_aquilo_snowy_decal_expression_name = "eon_nauvis_aquilo_fluid_resource_snowy_decal_probability"
    local eon_snow_drift_decal_expression_name = "eon_nauvis_aquilo_fluid_resource_snow_drift_decal_probability"

    data:extend({
        {
            type = "noise-expression",
            name = eon_aquilo_snowy_decal_expression_name,
            expression = "max(" ..
                eon_aquilo_snow_decorative_mask ..
                "(eon_aqulio_snowy_decal), eon_nauvis_aquilo_fluid_resource_snow_decal)"
        },
        {
            type = "noise-expression",
            name = eon_snow_drift_decal_expression_name,
            expression = "max(" ..
                eon_aquilo_snow_decorative_mask .. "(eon_snow_drift_decal), eon_nauvis_aquilo_fluid_resource_snow_drift)"
        }
    })

    local eon_aquilo_snowy_decal = data.raw["optimized-decorative"] and
        data.raw["optimized-decorative"]["aqulio-snowy-decal"]
    if eon_aquilo_snowy_decal and eon_aquilo_snowy_decal.autoplace then
        eon_aquilo_snowy_decal.autoplace.tile_restriction = nil
        eon_aquilo_snowy_decal.autoplace.probability_expression = eon_aquilo_snowy_decal_expression_name
        eon_set_decorative_probability_expression("nauvis", "aqulio-snowy-decal",
            eon_aquilo_snowy_decal_expression_name)
    end

    local eon_snow_drift_decal = data.raw["optimized-decorative"] and
        data.raw["optimized-decorative"]["snow-drift-decal"]
    if eon_snow_drift_decal and eon_snow_drift_decal.autoplace then
        eon_snow_drift_decal.autoplace.tile_restriction = nil
        eon_snow_drift_decal.autoplace.probability_expression = eon_snow_drift_decal_expression_name
        eon_set_decorative_probability_expression("nauvis", "snow-drift-decal",
            eon_snow_drift_decal_expression_name)
    end
end

eon_apply_aquilo_on_fulgora_snow_decorative_rules()

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

if data.raw["autoplace-control"]["fulgora_cliff"] then
    data.raw["autoplace-control"]["fulgora_cliff"].order = "c-z-c"
    data.raw["autoplace-control"]["fulgora_cliff"].category = "cliff"
    data.raw["autoplace-control"]["fulgora_cliff"].localised_description = nil
else
    data:extend({
        {
            type = "autoplace-control",
            name = "fulgora_cliff",
            order = "c-z-c",
            category = "cliff",
        },
    })
end

local eon_fulgora_map_gen = data.raw.planet["fulgora"] and data.raw.planet["fulgora"].map_gen_settings
if eon_fulgora_map_gen then
    eon_fulgora_map_gen.autoplace_controls = eon_fulgora_map_gen.autoplace_controls or {}
    eon_fulgora_map_gen.autoplace_controls["fulgora_cliff"] =
        eon_fulgora_map_gen.autoplace_controls["fulgora_cliff"] or {}
end

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

data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["gleba_plants"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["gleba_water"] = {}

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["natural-yumako-soil"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["natural-jellynut-soil"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["wetland-yumako"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["wetland-jellynut"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["wetland-light-green-slime"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["wetland-green-slime"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["wetland-light-dead-skin"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["wetland-dead-skin"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["wetland-pink-tentacle"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["wetland-red-tentacle"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-brown-blubber"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-olive-blubber"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-olive-blubber-2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-olive-blubber-3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-pale-green"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-cream-cauliflower"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-cream-cauliflower-2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-dead-skin"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-dead-skin-2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-cream-red"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-red-vein"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-red-vein-2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-red-vein-3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-red-vein-4"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-red-vein-dead"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lowland-red-infection"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["midland-turquoise-bark"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["midland-turquoise-bark-2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["midland-cracked-lichen"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["midland-cracked-lichen-dull"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["midland-cracked-lichen-dark"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["midland-yellow-crust"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["midland-yellow-crust-2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["midland-yellow-crust-3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["midland-yellow-crust-4"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["highland-dark-rock"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["highland-dark-rock-2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["highland-yellow-rock"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["pit-rock"] = {}

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["yellow-lettuce-lichen-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["yellow-lettuce-lichen-3x3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["yellow-lettuce-lichen-6x6"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["yellow-lettuce-lichen-cups-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["yellow-lettuce-lichen-cups-3x3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["yellow-lettuce-lichen-cups-6x6"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-lettuce-lichen-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-lettuce-lichen-3x3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-lettuce-lichen-6x6"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-lettuce-lichen-water-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-lettuce-lichen-water-3x3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-lettuce-lichen-water-6x6"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["split-gill-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["split-gill-2x2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["split-gill-dying-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["split-gill-dying-2x2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["split-gill-red-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["split-gill-red-2x2"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["veins"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["veins-small"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["mycelium"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["coral-water"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["coral-land"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["black-sceptre"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pink-phalanges"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pink-lichen-decal"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["red-lichen-decal"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-cup"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["brown-cup"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["blood-grape"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["blood-grape-vibrant"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["brambles"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["polycephalum-slime"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["polycephalum-balloon"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["fuchsia-pita"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["wispy-lichen"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["grey-cracked-mud-decal"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["barnacles-decal"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["coral-stunted"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["coral-stunted-grey"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["nerve-roots-dense"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["nerve-roots-sparse"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["yellow-coral"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["solo-barnacle"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["curly-roots-orange"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["knobbly-roots"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["knobbly-roots-orange"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["matches-small"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pale-lettuce-lichen-cups-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pale-lettuce-lichen-cups-3x3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pale-lettuce-lichen-cups-6x6"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pale-lettuce-lichen-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pale-lettuce-lichen-3x3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pale-lettuce-lichen-6x6"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pale-lettuce-lichen-water-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pale-lettuce-lichen-water-3x3"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["pale-lettuce-lichen-water-6x6"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["white-carpet-grass"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-carpet-grass"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-hairy-grass"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["light-mud-decal"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["dark-mud-decal"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["cracked-mud-decal"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["red-desert-bush"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["white-desert-bush"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["red-pita"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-bush-mini"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-croton"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-pita"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["green-pita-mini"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["lichen-decal"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["shroom-decal"] = {}

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["honeycomb-fungus"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["honeycomb-fungus-1x1"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings["honeycomb-fungus-decayed"] = {}

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["iron-stromatolite"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["copper-stromatolite"] = {}

terrain.mask_gleba_territory("natural-yumako-soil", "tile")
terrain.mask_gleba_territory("natural-jellynut-soil", "tile")
terrain.mask_gleba_territory("wetland-yumako", "tile")
terrain.mask_gleba_territory("wetland-jellynut", "tile")
terrain.mask_gleba_territory("wetland-blue-slime", "tile")
terrain.mask_gleba_territory("wetland-light-green-slime", "tile")
terrain.mask_gleba_territory("wetland-green-slime", "tile")
terrain.mask_gleba_territory("wetland-light-dead-skin", "tile")
terrain.mask_gleba_territory("wetland-dead-skin", "tile")
terrain.mask_gleba_territory("wetland-pink-tentacle", "tile")
terrain.mask_gleba_territory("wetland-red-tentacle", "tile")
terrain.mask_gleba_territory("gleba-deep-lake", "tile")
terrain.mask_gleba_territory("lowland-brown-blubber", "tile")
terrain.mask_gleba_territory("lowland-olive-blubber", "tile")
terrain.mask_gleba_territory("lowland-olive-blubber-2", "tile")
terrain.mask_gleba_territory("lowland-olive-blubber-3", "tile")
terrain.mask_gleba_territory("lowland-pale-green", "tile")
terrain.mask_gleba_territory("lowland-cream-cauliflower", "tile")
terrain.mask_gleba_territory("lowland-cream-cauliflower-2", "tile")
terrain.mask_gleba_territory("lowland-dead-skin", "tile")
terrain.mask_gleba_territory("lowland-dead-skin-2", "tile")
terrain.mask_gleba_territory("lowland-cream-red", "tile")
terrain.mask_gleba_territory("lowland-red-vein", "tile")
terrain.mask_gleba_territory("lowland-red-vein-2", "tile")
terrain.mask_gleba_territory("lowland-red-vein-3", "tile")
terrain.mask_gleba_territory("lowland-red-vein-4", "tile")
terrain.mask_gleba_territory("lowland-red-vein-dead", "tile")
terrain.mask_gleba_territory("lowland-red-infection", "tile")
terrain.mask_gleba_territory("midland-turquoise-bark", "tile")
terrain.mask_gleba_territory("midland-turquoise-bark-2", "tile")
terrain.mask_gleba_territory("midland-cracked-lichen", "tile")
terrain.mask_gleba_territory("midland-cracked-lichen-dull", "tile")
terrain.mask_gleba_territory("midland-cracked-lichen-dark", "tile")
terrain.mask_gleba_territory("midland-yellow-crust", "tile")
terrain.mask_gleba_territory("midland-yellow-crust-2", "tile")
terrain.mask_gleba_territory("midland-yellow-crust-3", "tile")
terrain.mask_gleba_territory("midland-yellow-crust-4", "tile")
terrain.mask_gleba_territory("highland-dark-rock", "tile")
terrain.mask_gleba_territory("highland-dark-rock-2", "tile")
terrain.mask_gleba_territory("highland-yellow-rock", "tile")
terrain.mask_gleba_territory("pit-rock", "tile")

terrain.mask_gleba_territory("yellow-lettuce-lichen-1x1", "optimized-decorative")
terrain.mask_gleba_territory("yellow-lettuce-lichen-3x3", "optimized-decorative")
terrain.mask_gleba_territory("yellow-lettuce-lichen-6x6", "optimized-decorative")
terrain.mask_gleba_territory("yellow-lettuce-lichen-cups-1x1", "optimized-decorative")
terrain.mask_gleba_territory("yellow-lettuce-lichen-cups-3x3", "optimized-decorative")
terrain.mask_gleba_territory("yellow-lettuce-lichen-cups-6x6", "optimized-decorative")
terrain.mask_gleba_territory("green-lettuce-lichen-1x1", "optimized-decorative")
terrain.mask_gleba_territory("green-lettuce-lichen-3x3", "optimized-decorative")
terrain.mask_gleba_territory("green-lettuce-lichen-6x6", "optimized-decorative")
terrain.mask_gleba_territory("green-lettuce-lichen-water-1x1", "optimized-decorative")
terrain.mask_gleba_territory("green-lettuce-lichen-water-3x3", "optimized-decorative")
terrain.mask_gleba_territory("green-lettuce-lichen-water-6x6", "optimized-decorative")
terrain.mask_gleba_territory("split-gill-1x1", "optimized-decorative")
terrain.mask_gleba_territory("split-gill-2x2", "optimized-decorative")
terrain.mask_gleba_territory("split-gill-dying-1x1", "optimized-decorative")
terrain.mask_gleba_territory("split-gill-dying-2x2", "optimized-decorative")
terrain.mask_gleba_territory("split-gill-red-1x1", "optimized-decorative")
terrain.mask_gleba_territory("split-gill-red-2x2", "optimized-decorative")
terrain.mask_gleba_territory("veins", "optimized-decorative")
terrain.mask_gleba_territory("veins-small", "optimized-decorative")
terrain.mask_gleba_territory("mycelium", "optimized-decorative")
terrain.mask_gleba_territory("coral-water", "optimized-decorative")
terrain.mask_gleba_territory("coral-land", "optimized-decorative")
terrain.mask_gleba_territory("black-sceptre", "optimized-decorative")
terrain.mask_gleba_territory("pink-phalanges", "optimized-decorative")
terrain.mask_gleba_territory("pink-lichen-decal", "optimized-decorative")
terrain.mask_gleba_territory("red-lichen-decal", "optimized-decorative")
terrain.mask_gleba_territory("green-cup", "optimized-decorative")
terrain.mask_gleba_territory("brown-cup", "optimized-decorative")
terrain.mask_gleba_territory("blood-grape", "optimized-decorative")
terrain.mask_gleba_territory("blood-grape-vibrant", "optimized-decorative")
terrain.mask_gleba_territory("brambles", "optimized-decorative")
terrain.mask_gleba_territory("polycephalum-slime", "optimized-decorative")
terrain.mask_gleba_territory("polycephalum-balloon", "optimized-decorative")
terrain.mask_gleba_territory("fuchsia-pita", "optimized-decorative")
terrain.mask_gleba_territory("wispy-lichen", "optimized-decorative")
terrain.mask_gleba_territory("grey-cracked-mud-decal", "optimized-decorative")
terrain.mask_gleba_territory("barnacles-decal", "optimized-decorative")
terrain.mask_gleba_territory("coral-stunted", "optimized-decorative")
terrain.mask_gleba_territory("coral-stunted-grey", "optimized-decorative")
terrain.mask_gleba_territory("nerve-roots-dense", "optimized-decorative")
terrain.mask_gleba_territory("nerve-roots-sparse", "optimized-decorative")
terrain.mask_gleba_territory("yellow-coral", "optimized-decorative")
terrain.mask_gleba_territory("solo-barnacle", "optimized-decorative")
terrain.mask_gleba_territory("curly-roots-orange", "optimized-decorative")
terrain.mask_gleba_territory("knobbly-roots", "optimized-decorative")
terrain.mask_gleba_territory("knobbly-roots-orange", "optimized-decorative")
terrain.mask_gleba_territory("matches-small", "optimized-decorative")
terrain.mask_gleba_territory("pale-lettuce-lichen-cups-1x1", "optimized-decorative")
terrain.mask_gleba_territory("pale-lettuce-lichen-cups-3x3", "optimized-decorative")
terrain.mask_gleba_territory("pale-lettuce-lichen-cups-6x6", "optimized-decorative")
terrain.mask_gleba_territory("pale-lettuce-lichen-1x1", "optimized-decorative")
terrain.mask_gleba_territory("pale-lettuce-lichen-3x3", "optimized-decorative")
terrain.mask_gleba_territory("pale-lettuce-lichen-6x6", "optimized-decorative")
terrain.mask_gleba_territory("pale-lettuce-lichen-water-1x1", "optimized-decorative")
terrain.mask_gleba_territory("pale-lettuce-lichen-water-3x3", "optimized-decorative")
terrain.mask_gleba_territory("pale-lettuce-lichen-water-6x6", "optimized-decorative")
terrain.mask_gleba_territory("white-carpet-grass", "optimized-decorative")
terrain.mask_gleba_territory("green-carpet-grass", "optimized-decorative")
terrain.mask_gleba_territory("green-hairy-grass", "optimized-decorative")
terrain.mask_gleba_territory("light-mud-decal", "optimized-decorative")
terrain.mask_gleba_territory("dark-mud-decal", "optimized-decorative")
terrain.mask_gleba_territory("cracked-mud-decal", "optimized-decorative")
terrain.mask_gleba_territory("red-desert-bush", "optimized-decorative")
terrain.mask_gleba_territory("white-desert-bush", "optimized-decorative")
terrain.mask_gleba_territory("red-pita", "optimized-decorative")
terrain.mask_gleba_territory("green-bush-mini", "optimized-decorative")
terrain.mask_gleba_territory("green-croton", "optimized-decorative")
terrain.mask_gleba_territory("green-pita", "optimized-decorative")
terrain.mask_gleba_territory("green-pita-mini", "optimized-decorative")
terrain.mask_gleba_territory("lichen-decal", "optimized-decorative")
terrain.mask_gleba_territory("shroom-decal", "optimized-decorative")

terrain.mask_gleba_territory("iron-stromatolite", "simple-entity")
terrain.mask_gleba_territory("copper-stromatolite", "simple-entity")

terrain.mask_gleba_territory("cuttlepop", "tree")
terrain.mask_gleba_territory("slipstack", "tree")
terrain.mask_gleba_territory("funneltrunk", "tree")
terrain.mask_gleba_territory("hairyclubnub", "tree")
terrain.mask_gleba_territory("teflilly", "tree")
terrain.mask_gleba_territory("lickmaw", "tree")
terrain.mask_gleba_territory("stingfrond", "tree")
terrain.mask_gleba_territory("boompuff", "tree")
terrain.mask_gleba_territory("sunnycomb", "tree")
terrain.mask_gleba_territory("water-cane", "tree")

terrain.mask_gleba_territory("honeycomb-fungus", "optimized-decorative")
terrain.mask_gleba_territory("honeycomb-fungus-1x1", "optimized-decorative")
terrain.mask_gleba_territory("honeycomb-fungus-decayed", "optimized-decorative")

data.raw["autoplace-control"]["gleba_plants"].can_be_disabled = true
data.raw["autoplace-control"]["gleba_water"].can_be_disabled = true

data.raw["noise-expression"]["gleba_plants_noise"].expression = "eon_mask_gleba_territory(abs(multioctave_noise{x = x,\z
                                                                                                                y = y,\z
                                                                                                                persistence = 0.8,\z
                                                                                                                seed0 = map_seed,\z
                                                                                                                seed1 = 700000,\z
                                                                                                                octaves = 3,\z
                                                                                                                input_scale = 1/20 }\z
                                                                                            * multioctave_noise{x = x,\z
                                                                                                                y = y,\z
                                                                                                                persistence = 0.8,\z
                                                                                                                seed0 = map_seed,\z
                                                                                                                seed1 = 200000,\z
                                                                                                                octaves = 3,\z
                                                                                                                input_scale = 1/6 * control:gleba_plants:frequency }))"
data.raw["noise-expression"]["gleba_plants_noise_b"].expression =
"eon_mask_gleba_territory(abs(multioctave_noise{x = x,\z
                                                                                                                  y = y,\z
                                                                                                                  persistence = 0.8,\z
                                                                                                                  seed0 = map_seed,\z
                                                                                                                  seed1 = 750000,\z
                                                                                                                  octaves = 3,\z
                                                                                                                  input_scale = 1/20 * control:gleba_plants:frequency }\z
                                                                                              * multioctave_noise{x = x,\z
                                                                                                                  y = y,\z
                                                                                                                  persistence = 0.8,\z
                                                                                                                  seed0 = map_seed,\z
                                                                                                                  seed1 = 250000,\z
                                                                                                                  octaves = 3,\z
                                                                                                                  input_scale = 1/6 * control:gleba_plants:frequency }))"

data.raw.tile["wetland-jellynut"].autoplace.probability_expression = "eon_jellynut_spots"
data.raw.tile["wetland-yumako"].autoplace.probability_expression = "eon_yumako_spots"
data.raw.tile["natural-jellynut-soil"].autoplace.probability_expression = "eon_jellynut_soil"
data.raw.tile["natural-yumako-soil"].autoplace.probability_expression = "eon_yumako_soil"

data:extend({
    {
        type = "noise-expression",
        name = "eon_gleba_mask",
        expression = "eon_gleba_region(" .. eon_gleba_mask_threshold .. ")"
    },
    {
        type = "noise-expression",
        name = "eon_jellynut_spots",
        expression =
        "clamp(eon_gleba_agriculture_spots(1, 64 * sqrt(control:gleba_water:size), control:gleba_water:frequency) * 5000 * control:gleba_water:frequency, -inf, 2)"
    },
    {
        type = "noise-expression",
        name = "eon_yumako_spots",
        expression =
        "clamp(eon_gleba_agriculture_spots(2, 64 * sqrt(control:gleba_water:size), control:gleba_water:frequency) * 5000 * control:gleba_water:frequency, -inf, 2)"
    },
    {
        type = "noise-expression",
        name = "eon_jellynut_soil",
        expression =
        "eon_gleba_agriculture_spots(1, 32 * sqrt(control:gleba_plants:size), control:gleba_plants:frequency) * 6 * control:gleba_plants:frequency"
    },
    {
        type = "noise-expression",
        name = "eon_yumako_soil",
        expression =
        "eon_gleba_agriculture_spots(2, 32 * sqrt(control:gleba_plants:size), control:gleba_plants:frequency) * 6 * control:gleba_plants:frequency"
    },

    {
        type = "noise-function",
        name = "eon_gleba_region",
        parameters = { "threshold" },
        expression = eon_gleba_region_expression,
        local_expressions = {
            gleba_noise = "quick_multioctave_noise{x = x,\z
                                             y = y,\z
                                             seed0 = map_seed,\z
                                             seed1 = 5,\z
                                             octaves = 4,\z
                                             input_scale = var('control:gleba_plants:frequency') / 32,\z
                                             output_scale = 1/2,\z
                                             octave_output_scale_multiplier = 3,\z
                                             octave_input_scale_multiplier = 1/3}",
            gleba_intermediate_noise = "quick_multioctave_noise{x = x,\z
                                                          y = y,\z
                                                          seed0 = map_seed,\z
                                                          seed1 = 6,\z
                                                          octaves = 4,\z
                                                          input_scale = var('control:gleba_plants:frequency') / 32,\z
                                                          output_scale = 2,\z
                                                          octave_output_scale_multiplier = 3,\z
                                                          octave_input_scale_multiplier = 1/3}",
            gleba_small_noise = "quick_multioctave_noise{x = x,\z
                                                          y = y,\z
                                                          seed0 = map_seed,\z
                                                          seed1 = 7,\z
                                                          octaves = 4,\z
                                                          input_scale = var('control:gleba_plants:frequency') / 4,\z
                                                          output_scale = 1,\z
                                                          octave_output_scale_multiplier = 3,\z
                                                          octave_input_scale_multiplier = 1/3}",
            y_offset = "y - " .. eon_gleba_south_bias_y_offset,
            south_offset = "y_offset / (1 + pow(2, 0.01 * y_offset)) + 0.1 * y_offset - 60"
        }
    },
    {
        type = "noise-function",
        name = "eon_gleba_agriculture_spots",
        parameters = { "seed", "spot_radius_expression", "spot_frequency_expression" },
        expression = "eon_mask_gleba_territory(spot_noise{x = x + wobble_noise_x * 15,\z
                                                      y = y + wobble_noise_y * 15,\z
                                                      seed0 = map_seed,\z
                                                      seed1 = seed,\z
                                                      candidate_spot_count = 4,\z
                                                      suggested_minimum_candidate_point_spacing = 128,\z
                                                      skip_span = 1,\z
                                                      skip_offset = 0,\z
                                                      region_size = 1024 / max(0.125, spot_frequency_expression),\z
                                                      density_expression = 80,\z
                                                      spot_quantity_expression = 1000,\z
                                                      spot_radius_expression = spot_radius_expression,\z
                                                      hard_region_target_quantity = 0,\z
                                                      spot_favorability_expression = 60,\z
                                                      basement_value = -0.5,\z
                                                      maximum_spot_basement_radius = max(32, 128 * sqrt(control:gleba_water:size))})",
        local_expressions =
        {
            wobble_noise_x =
            "multioctave_noise{x = x, y = y, persistence = 0.5, seed0 = map_seed, seed1 = 3000000, octaves = 2, input_scale = 1/20}",
            wobble_noise_y =
            "multioctave_noise{x = x, y = y, persistence = 0.5, seed0 = map_seed, seed1 = 4000000, octaves = 2, input_scale = 1/20}"
        }
    },
    {
        type = "noise-function",
        name = "eon_mask_gleba_territory",
        parameters = { "expression" },
        expression = "if(eon_gleba_mask, expression, -inf)"
    },
    {
        type = "noise-function",
        name = "eon_mask_off_gleba_territory",
        parameters = { "expression" },
        expression = "if(eon_gleba_mask, -inf, expression)"
    },
})

data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["vulcanus_volcanism"] = {}

local eon_vulcanus_tile_names = {
    "volcanic-soil-dark",
    "volcanic-soil-light",
    "volcanic-ash-soil",
    "volcanic-ash-flats",
    "volcanic-ash-light",
    "volcanic-ash-dark",
    "volcanic-cracks",
    "volcanic-cracks-warm",
    "volcanic-folds",
    "volcanic-folds-flat",
    "lava",
    "lava-hot",
    "volcanic-folds-warm",
    "volcanic-pumice-stones",
    "volcanic-cracks-hot",
    "volcanic-jagged-ground",
    "volcanic-smooth-stone",
    "volcanic-smooth-stone-warm",
    "volcanic-ash-cracks",
}

if eon_aquilo_on_fulgora then
    for _, tile_name in pairs(eon_vulcanus_tile_names) do
        data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings[tile_name] = {}
    end
else
    data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["volcanic-folds"] = {}
    data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["volcanic-folds-flat"] = {}
    data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lava"] = {}
    data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings["lava-hot"] = {}
end

---@return table<string, table>|nil
local function eon_vulcanus_optimized_decorative_settings()
    local planet = data.raw.planet and data.raw.planet["vulcanus"]
    return planet
        and planet.map_gen_settings
        and planet.map_gen_settings.autoplace_settings
        and planet.map_gen_settings.autoplace_settings.decorative
        and planet.map_gen_settings.autoplace_settings.decorative.settings
end

local eon_vulcanus_optimized_decorative_names = {}
do
    local settings = eon_vulcanus_optimized_decorative_settings()
    if settings then
        for decorative_name, _ in pairs(settings) do
            local decorative = data.raw["optimized-decorative"]
                and data.raw["optimized-decorative"][decorative_name]
            if decorative and decorative.autoplace then
                table.insert(eon_vulcanus_optimized_decorative_names, decorative_name)
                data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings[decorative_name] = {}
            end
        end
    end
end

data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["crater-cliff"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["vulcanus-chimney"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["vulcanus-chimney-faded"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["vulcanus-chimney-cold"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["vulcanus-chimney-short"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["vulcanus-chimney-truncated"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["huge-volcanic-rock"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["big-volcanic-rock"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["ashland-lichen-tree"] = {}
data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["ashland-lichen-tree-flaming"] = {}

if eon_aquilo_on_fulgora then
    local eon_vulcanus_tile_probability_expressions = {
        ["volcanic-soil-dark"] = "volcanic_soil_dark_range",
        ["volcanic-soil-light"] = "volcanic_soil_light_range",
        ["volcanic-ash-soil"] = "volcanic_ash_soil_range",
        ["volcanic-ash-flats"] = "volcanic_ash_flats_range",
        ["volcanic-ash-light"] = "volcanic_ash_light_range",
        ["volcanic-ash-dark"] = "volcanic_ash_dark_range",
        ["volcanic-cracks"] = "volcanic_cracks_cold_range",
        ["volcanic-cracks-warm"] = "volcanic_cracks_warm_range",
        ["volcanic-folds"] = "volcanic_folds_range",
        ["volcanic-folds-flat"] = "volcanic_folds_flat_range",
        ["lava"] = "max(lava_basalts_range, lava_mountains_range)",
        ["lava-hot"] = "max(lava_hot_basalts_range, lava_hot_mountains_range)",
        ["volcanic-folds-warm"] = "volcanic_folds_warm_range",
        ["volcanic-pumice-stones"] = "volcanic_pumice_stones_range",
        ["volcanic-cracks-hot"] = "volcanic_cracks_hot_range",
        ["volcanic-jagged-ground"] = "volcanic_jagged_ground_range",
        ["volcanic-smooth-stone"] = "volcanic_smooth_stone_range",
        ["volcanic-smooth-stone-warm"] = "volcanic_smooth_stone_warm_range",
        ["volcanic-ash-cracks"] = "volcanic_ash_cracks_range",
    }

    for tile_name, probability_expression in pairs(eon_vulcanus_tile_probability_expressions) do
        if data.raw.tile[tile_name] and data.raw.tile[tile_name].autoplace then
            data.raw.tile[tile_name].autoplace.probability_expression =
                "eon_mask_vulcano_terrain(" .. probability_expression .. ")"
        end
    end

    data.raw.cliff["crater-cliff"].autoplace.probability_expression = "eon_crater_cliff"
else
    terrain.mask_vulcano_coverage("volcanic-ash-flats", "tile")
    terrain.mask_vulcano_coverage("volcanic-ash-light", "tile")
    terrain.mask_vulcano_coverage("volcanic-ash-dark", "tile")
    terrain.mask_vulcano_coverage("volcanic-cracks", "tile")
    terrain.mask_vulcano_coverage("volcanic-cracks-warm", "tile")
    terrain.mask_vulcano_coverage("volcanic-folds-warm", "tile")
    terrain.mask_vulcano_coverage("volcanic-pumice-stones", "tile")
    terrain.mask_vulcano_coverage("volcanic-cracks-hot", "tile")
    terrain.mask_vulcano_coverage("volcanic-jagged-ground", "tile")
    terrain.mask_vulcano_coverage("volcanic-smooth-stone", "tile")
    terrain.mask_vulcano_coverage("volcanic-smooth-stone-warm", "tile")
    terrain.mask_vulcano_coverage("volcanic-ash-cracks", "tile")

    data.raw.tile["volcanic-folds"].autoplace.probability_expression = "eon_updated_volcanic_folds"
    data.raw.tile["volcanic-folds-flat"].autoplace.probability_expression = "eon_updated_volcanic_folds_flat"
    data.raw.tile["lava"].autoplace.probability_expression = "eon_lava_mountains_range"
    data.raw.tile["lava-hot"].autoplace.probability_expression = "eon_lava_hot_mountains_range"
    data.raw.tile["volcanic-cracks-warm"].autoplace.probability_expression = "eon_volcano_cracks_warm_range"
    data.raw.cliff["crater-cliff"].autoplace.probability_expression = "eon_lava_hot_mountains_range"
end

local eon_vulcanus_decoratives_off_aquilo = eon_vulcanus_optimized_decorative_names

local eon_vulcanus_decorative_tile_restrictions = {
    "volcanic-ash-cracks",
    "volcanic-ash-dark",
    "volcanic-ash-flats",
    "volcanic-ash-light",
    "volcanic-ash-soil",
    "volcanic-cracks",
    "volcanic-cracks-hot",
    "volcanic-cracks-warm",
    "volcanic-folds",
    "volcanic-folds-flat",
    "volcanic-folds-warm",
    "volcanic-jagged-ground",
    "volcanic-pumice-stones",
    "volcanic-smooth-stone",
    "volcanic-smooth-stone-warm",
    "volcanic-soil-dark",
    "volcanic-soil-light",
}

local eon_vulcanus_lava_fire_tile_restrictions = {
    "lava",
}

local eon_vulcanus_trees_off_aquilo = {
    "ashland-lichen-tree",
    "ashland-lichen-tree-flaming",
    "tree-volcanic-a",
}

---@param expression string|nil
---@param wrapper string
---@return boolean
local function eon_expression_has_wrapper(expression, wrapper)
    return type(expression) == "string"
        and string.find(expression, wrapper .. "%(", 1, false) ~= nil
end

---@param prototype_type string
---@param prototype_name string
---@param wrapper string
local function eon_wrap_current_autoplace_expression(prototype_type, prototype_name, wrapper)
    local prototypes = data.raw[prototype_type]
    local prototype = prototypes and prototypes[prototype_name]
    local autoplace = prototype and prototype.autoplace
    local expression = autoplace and autoplace.probability_expression

    if type(expression) ~= "string" or expression == "" then return end
    if eon_expression_has_wrapper(expression, wrapper) then return end

    autoplace.probability_expression = wrapper .. "(" .. expression .. ")"
end

terrain.mask_vulcano_coverage("vulcanus-chimney", "simple-entity")
terrain.mask_vulcano_coverage("vulcanus-chimney-faded", "simple-entity")
terrain.mask_vulcano_coverage("vulcanus-chimney-cold", "simple-entity")
terrain.mask_vulcano_coverage("vulcanus-chimney-short", "simple-entity")
terrain.mask_vulcano_coverage("vulcanus-chimney-truncated", "simple-entity")
terrain.mask_vulcano_coverage("huge-volcanic-rock", "simple-entity")
terrain.mask_vulcano_coverage("big-volcanic-rock", "simple-entity")
terrain.mask_vulcano_terrain("ashland-lichen-tree", "tree")
terrain.mask_vulcano_terrain("ashland-lichen-tree-flaming", "tree")

for _, name in ipairs(eon_vulcanus_trees_off_aquilo) do
    eon_wrap_current_autoplace_expression("tree", name, eon_vulcanus_off_aquilo_mask)
    eon_restrict_autoplace_to_tiles("tree", name, eon_vulcanus_decorative_tile_restrictions)
end

---@param tree_name string
---@param expression string
---@return nil
local function eon_set_vulcanus_tree_probability(tree_name, expression)
    local tree = data.raw.tree and data.raw.tree[tree_name]
    if not (tree and tree.autoplace) then return end

    tree.autoplace.probability_expression =
        eon_vulcanus_off_aquilo_mask .. "(eon_mask_vulcano_terrain(" .. expression .. "))"
end

eon_set_vulcanus_tree_probability("ashland-lichen-tree", "eon_vulcanus_tree_on_nauvis")
eon_set_vulcanus_tree_probability("ashland-lichen-tree-flaming", "eon_vulcanus_tree_on_nauvis / 16")

for _, decorative_name in ipairs(eon_vulcanus_optimized_decorative_names) do
    terrain.mask_vulcano_terrain(decorative_name, "optimized-decorative")
end

for _, name in ipairs(eon_vulcanus_decoratives_off_aquilo) do
    eon_wrap_current_autoplace_expression("optimized-decorative", name, eon_vulcanus_off_aquilo_mask)
    eon_restrict_autoplace_to_tiles("optimized-decorative", name, eon_vulcanus_decorative_tile_restrictions)
end

local lava_fire = data.raw["optimized-decorative"] and data.raw["optimized-decorative"]["vulcanus-lava-fire"]
if lava_fire and lava_fire.autoplace then
    lava_fire.autoplace.probability_expression =
        eon_vulcanus_off_aquilo_mask .. "(eon_mask_vulcano_terrain(0.04))"
    lava_fire.autoplace.tile_restriction = eon_vulcanus_lava_fire_tile_restrictions
end

data:extend({
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
        expression = eon_vulcanus_coverage_expression
    },
    {
        type = "noise-expression",
        name = "eon_vulcanus_terrain",
        expression = eon_vulcanus_terrain_expression
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
})

return terrain
