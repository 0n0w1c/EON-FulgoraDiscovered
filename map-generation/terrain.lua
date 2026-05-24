local data_util = require("data-util")

local terrain = {}
local eon_generated_tiles = data_util.generated_tiles_by_surface()
local eon_generated_worldgen = data_util.generated_worldgen_prototypes_by_surface()

local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value == true

local eon_aquilo_planet_name = eon_aquilo_on_fulgora and "fulgora" or "nauvis"

local eon_aquilo_north_bias_y_offset = 650

local eon_aquilo_exclusion_mask = eon_aquilo_on_fulgora
    and "eon_identity"
    or "eon_mask_off_vulcano_coverage"

local eon_ammonia_ocean_tile_mask = "eon_mask_aquilo_territory"

local eon_ammonia_ocean_tile_expression = eon_aquilo_on_fulgora
    and "eon_aquilo_ammonia_core"
    or "eon_aquilo_ammonia"

local eon_aquilo_decorative_mask = "eon_mask_aquilo_territory"

local eon_aquilo_snow_decorative_mask = eon_aquilo_on_fulgora
    and "eon_identity"
    or "eon_mask_aquilo_territory"

local eon_nauvis_territory_expression = eon_aquilo_on_fulgora
    and "eon_mask_off_gleba_territory(eon_mask_off_vulcano_terrain(expression))"
    or "eon_mask_off_aquilo_territory(eon_mask_off_gleba_territory(eon_mask_off_vulcano_terrain(expression)))"

local eon_nauvis_cliffiness_expression = eon_aquilo_on_fulgora
    and "(main_cliffiness >= cliff_cutoff) * 10"
    or "eon_mask_off_aquilo_territory((main_cliffiness >= cliff_cutoff) * 10)"

local eon_gleba_region_expression =
"eon_mask_off_vulcano_terrain(if(gleba_noise + gleba_intermediate_noise + gleba_small_noise + moisture_nauvis + south_offset > threshold, 1, 0))"

local eon_gleba_mask_threshold = -10

local eon_vulcanus_coverage_expression = eon_aquilo_on_fulgora
    and "eon_vulcanus_region(0)"
    or "max(eon_updated_volcanic_folds, eon_lava_mountains_range, eon_lava_hot_mountains_range) > 0"

local eon_vulcanus_terrain_expression = eon_aquilo_on_fulgora
    and "eon_vulcanus_region(0)"
    or "max(eon_vulcano_coverage, eon_updated_volcanic_folds_flat) > 0"

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

local eon_aquilo_decorative_list = {
    "lithium-iceberg-medium",
    "lithium-iceberg-small",
    "lithium-iceberg-tiny",
    "floating-iceberg-large",
    "floating-iceberg-small",
    "aqulio-ice-decal-blue",
    "aqulio-snowy-decal",
    "snow-drift-decal",
}

local eon_aquilo_resource_list = {
    "lithium-brine",
    "fluorine-vent",
}

local eon_aquilo_simple_entity_list = {
    "lithium-iceberg-huge",
    "lithium-iceberg-big",
}

local eon_aquilo_decorative_names = {}
for _, decorative_name in ipairs(eon_aquilo_decorative_list) do
    eon_aquilo_decorative_names[decorative_name] = true
end

local eon_aquilo_entity_names = {}
for _, entity_name in ipairs(eon_aquilo_resource_list) do
    eon_aquilo_entity_names[entity_name] = true
end
for _, entity_name in ipairs(eon_aquilo_simple_entity_list) do
    eon_aquilo_entity_names[entity_name] = true
end

---@alias EONPrototypeName string
---@alias EONPrototypeList EONPrototypeName[]
---@alias EONPrototypeSet table<EONPrototypeName, boolean>
---@alias EONMapGen table

---@type EONPrototypeList
local eon_aquilo_tile_names = data_util.tiles_for_sprite_usage_surface("aquilo", {
    "ammoniacal-ocean",
    "ammoniacal-ocean-2",
})

---@type EONPrototypeSet
local eon_aquilo_tile_name_set = {}
for _, tile_name in ipairs(eon_aquilo_tile_names) do
    eon_aquilo_tile_name_set[tile_name] = true
end

local eon_aquilo_snow_decorative_tile_names = data_util.tiles_for_sprite_usage_surfaces({ "aquilo", "fulgora" }, nil, {
    ["ammoniacal-ocean"] = true,
    ["ammoniacal-ocean-2"] = true,
    ["oil-ocean-shallow"] = true,
    ["oil-ocean-deep"] = true,
})

---Wrap probability expression.
---@param prototype table|nil
---@param wrapper string
local function eon_wrap_probability_expression(prototype, wrapper)
    if not prototype or not prototype.autoplace then return end
    local expression = prototype.autoplace.probability_expression
    if type(expression) == "string" and expression ~= "" then
        if not string.find(expression, wrapper .. "%(", 1, false) then
            prototype.autoplace.probability_expression = wrapper .. "(" .. expression .. ")"
        end
    end
end

---Mask fulgora oil ocean off aquilo ocean edge.
local function eon_mask_fulgora_oil_ocean_off_aquilo_ocean_edge()
    for _, tile_name in ipairs({ "oil-ocean-deep", "oil-ocean-shallow" }) do
        local tile = data.raw.tile and data.raw.tile[tile_name]
        eon_wrap_probability_expression(tile, "eon_mask_off_aquilo_ocean_edge")
    end
end

---Restrict autoplace to tiles.
---@param prototype_type string
---@param prototype_name string
---@param tile_names? EONPrototypeList
local function eon_restrict_autoplace_to_tiles(prototype_type, prototype_name, tile_names)
    local prototypes = data.raw[prototype_type]
    if not prototypes then return end

    local prototype = prototypes[prototype_name]
    if not prototype or not prototype.autoplace then return end

    prototype.autoplace.tile_restriction = tile_names
end

---Extend autoplace tile restriction.
---@param prototype_type string
---@param prototype_name string
---@param tile_names? EONPrototypeList
local function eon_extend_autoplace_tile_restriction(prototype_type, prototype_name, tile_names)
    local prototypes = data.raw[prototype_type]
    if not prototypes then return end

    local prototype = prototypes[prototype_name]
    if not prototype or not prototype.autoplace then return end

    ---@type EONPrototypeSet
    local seen = {}

    ---@type EONPrototypeList
    local merged = {}

    if prototype.autoplace.tile_restriction then
        for _, tile_name in ipairs(prototype.autoplace.tile_restriction) do
            if not seen[tile_name] then
                seen[tile_name] = true
                table.insert(merged, tile_name)
            end
        end
    end

    for _, tile_name in ipairs(tile_names or {}) do
        if not seen[tile_name] then
            seen[tile_name] = true
            table.insert(merged, tile_name)
        end
    end

    prototype.autoplace.tile_restriction = merged
end

---Apply aquilo on fulgora snow decorative rules.
local function eon_apply_aquilo_on_fulgora_snow_decorative_rules()
    if not eon_aquilo_on_fulgora then return end

    eon_extend_autoplace_tile_restriction("optimized-decorative",
        "aqulio-snowy-decal",
        eon_aquilo_snow_decorative_tile_names)
    eon_restrict_autoplace_to_tiles("optimized-decorative",
        "snow-drift-decal",
        eon_aquilo_snow_decorative_tile_names)
end

local eon_autoplace_setting_prototype_types = {
    tile = "tile",
    decorative = "optimized-decorative",
    entity = "simple-entity",
}

---Register generated prototypes in a planet autoplace settings bucket.
---@param planet_name string
---@param setting_type "tile"|"decorative"|"entity"
---@param prototype_names? EONPrototypeList
---@param prototype_type_override? string
local function eon_register_planet_autoplace_settings(planet_name, setting_type, prototype_names, prototype_type_override)
    local planet = data.raw.planet and data.raw.planet[planet_name]
    local map_gen_settings = planet and planet.map_gen_settings
    local autoplace_settings = map_gen_settings and map_gen_settings.autoplace_settings
    local setting_bucket = autoplace_settings and autoplace_settings[setting_type]
    local settings = setting_bucket and setting_bucket.settings
    local prototype_type = prototype_type_override or eon_autoplace_setting_prototype_types[setting_type]
    local prototypes = prototype_type and data.raw[prototype_type]

    if not (settings and prototypes) then return end

    for _, prototype_name in ipairs(prototype_names or {}) do
        local prototype = prototypes[prototype_name]
        if prototype and prototype.autoplace then
            settings[prototype_name] = settings[prototype_name] or {}
        end
    end
end

---Register generated Gleba prototypes on Nauvis.
local function eon_register_gleba_map_gen_on_nauvis()
    local nauvis = data.raw.planet and data.raw.planet["nauvis"]
    local map_gen_settings = nauvis and nauvis.map_gen_settings
    if not map_gen_settings then return end

    map_gen_settings.autoplace_controls["gleba_plants"] = {}
    map_gen_settings.autoplace_controls["gleba_water"] = {}

    eon_register_planet_autoplace_settings("nauvis", "tile", eon_generated_tiles.gleba)
    eon_register_planet_autoplace_settings("nauvis", "decorative", eon_generated_worldgen.gleba.decoratives)
    eon_register_planet_autoplace_settings("nauvis", "entity", eon_generated_worldgen.gleba.entities)
    eon_register_planet_autoplace_settings("nauvis", "entity", eon_generated_worldgen.gleba.trees, "tree")
    eon_register_planet_autoplace_settings("nauvis", "entity", eon_generated_worldgen.gleba.plants, "plant")
end

---Register generated Vulcanus prototypes on Nauvis.
---@param tile_names EONPrototypeList
local function eon_register_vulcanus_map_gen_on_nauvis(tile_names)
    local nauvis = data.raw.planet and data.raw.planet["nauvis"]
    local map_gen_settings = nauvis and nauvis.map_gen_settings
    if not map_gen_settings then return end

    map_gen_settings.autoplace_controls["vulcanus_volcanism"] = {}

    eon_register_planet_autoplace_settings("nauvis", "tile", tile_names)
    eon_register_planet_autoplace_settings("nauvis", "decorative", eon_generated_worldgen.vulcanus.decoratives)
    eon_register_planet_autoplace_settings("nauvis", "entity", eon_generated_worldgen.vulcanus.entities)
    eon_register_planet_autoplace_settings("nauvis", "entity", eon_generated_worldgen.vulcanus.trees, "tree")
end

---Mask prototypes.
---@param prototype_type string
---@param prototype_names? EONPrototypeList
---@param mask_function fun(name:string, prototype_type:string)
local function eon_mask_prototypes(prototype_type, prototype_names, mask_function)
    local prototypes = data.raw[prototype_type]
    if not prototypes then return end

    for _, prototype_name in ipairs(prototype_names or {}) do
        local prototype = prototypes[prototype_name]
        if prototype and prototype.autoplace then
            if data_util.has_eon_noise_expression(prototype_name) then
                mask_function(prototype_name, prototype_type)
            else
                data_util.log_skipped_missing_eon_noise_expression(prototype_type, prototype_name)
            end
        end
    end
end

---Mask tiles.
---@param tile_names? EONPrototypeList
---@param mask_function fun(name:string, prototype_type:string)
local function eon_mask_tiles(tile_names, mask_function)
    eon_mask_prototypes("tile", tile_names, mask_function)
end

---Mask generated surface tiles.
---@param surface_name string
---@param mask_function fun(name:string, prototype_type:string)
---@param excluded_names? table<string, boolean>
---@param extra_names? EONPrototypeList
local function eon_mask_generated_surface_tiles(surface_name, mask_function, excluded_names, extra_names)
    eon_mask_tiles(data_util.tiles_for_sprite_usage_surface(surface_name, extra_names, excluded_names), mask_function)
end

---Mask a prototype into Nauvis territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_nauvis_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_nauvis_territory(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype out of Nauvis territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_off_nauvis_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_nauvis_territory(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a resource into valid Nauvis resource territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_resource_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_resource_territory(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype into Aquilo territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_aquilo_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_aquilo_territory(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype out of Aquilo territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_off_aquilo_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_aquilo_territory(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype into Aquilo-on-Fulgora territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_fulgora_aquilo_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_fulgora_aquilo_territory(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype out of Aquilo-on-Fulgora territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_off_fulgora_aquilo_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_fulgora_aquilo_territory(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype into ammonia ocean territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_ammonia_ocean(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_ammonia_ocean(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a decorative into Aquilo territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_aquilo_decorative_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = eon_aquilo_decorative_mask .. "(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a snow decorative into Aquilo territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_aquilo_snow_decorative_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = eon_aquilo_snow_decorative_mask .. "(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype out of ammonia ocean territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_off_ammonia_ocean(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_ammonia_ocean(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype into Gleba territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_gleba_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_gleba_territory(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype out of Gleba territory.
---@param decorative string
---@param decorative_type string
function terrain.mask_off_gleba_territory(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_gleba_territory(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype into broad Vulcanus coverage.
---@param decorative string
---@param decorative_type string
function terrain.mask_vulcano_coverage(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_vulcano_coverage(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype out of broad Vulcanus coverage.
---@param decorative string
---@param decorative_type string
function terrain.mask_off_vulcano_coverage(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_off_vulcano_coverage(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype into Vulcanus terrain.
---@param decorative string
---@param decorative_type string
function terrain.mask_vulcano_terrain(decorative, decorative_type)
    data.raw[decorative_type][decorative].autoplace.probability_expression = "eon_mask_vulcano_terrain(" ..
        data_util.generate_eon_name(decorative) .. ")"
end

---Mask a prototype out of Vulcanus terrain.
---@param decorative string
---@param decorative_type string
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

data_util.apply_mask_group {
    names = eon_generated_worldgen.nauvis.decoratives,
    prototype_type = "optimized-decorative",
    mask = terrain.mask_nauvis_territory,
}

data_util.apply_mask_group {
    names = eon_generated_worldgen.nauvis.entities,
    prototype_type = "simple-entity",
    mask = terrain.mask_nauvis_territory,
}

data_util.apply_mask_group {
    names = eon_generated_worldgen.nauvis.trees,
    prototype_type = "tree",
    mask = terrain.mask_nauvis_territory,
}

data_util.apply_mask_group {
    names = eon_generated_worldgen.nauvis.plants,
    prototype_type = "plant",
    mask = terrain.mask_nauvis_territory,
}

data_util.apply_mask_group {
    names = eon_generated_tiles.nauvis,
    prototype_type = "tile",
    mask = terrain.mask_nauvis_territory,
}

data.raw["noise-expression"]["cliffiness_nauvis"].expression = eon_nauvis_cliffiness_expression

---Apply blended nauvis cliff settings.
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
        expression = "if(eon_resource_territory <= 0, expression, -inf)"
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


---@type EONMapGen|nil
local eon_aquilo_map_gen = data.raw.planet[eon_aquilo_planet_name]
    and data.raw.planet[eon_aquilo_planet_name].map_gen_settings

local eon_inactive_aquilo_planet_name = eon_aquilo_on_fulgora and "nauvis" or "fulgora"

---@type EONMapGen|nil
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

---@alias EONNoiseExpression string|number|boolean

---Set entity property expression.
---@param planet_name string
---@param entity_name string
---@param property_name string
---@param expression EONNoiseExpression
local function eon_set_entity_property_expression(planet_name, entity_name, property_name, expression)
    local planet = data.raw.planet[planet_name]
    if not planet or not planet.map_gen_settings then return end

    planet.map_gen_settings.property_expression_names = planet.map_gen_settings.property_expression_names or {}
    planet.map_gen_settings.property_expression_names["entity:" .. entity_name .. ":" .. property_name] = expression
end

table.insert(eon_aquilo_autoplace_controls, "ammonia_ocean")

---Enable aquilo autoplace controls.
---@param map_gen EONMapGen|nil
local function eon_enable_aquilo_autoplace_controls(map_gen)
    if not map_gen then return end

    map_gen.autoplace_controls = map_gen.autoplace_controls or {}

    for _, control_name in ipairs(eon_aquilo_autoplace_controls) do
        map_gen.autoplace_controls[control_name] = {}
    end
end

---Disable aquilo autoplace controls.
---@param map_gen EONMapGen|nil
local function eon_disable_aquilo_autoplace_controls(map_gen)
    if not (map_gen and map_gen.autoplace_controls) then return end

    for _, control_name in ipairs(eon_all_aquilo_autoplace_controls) do
        map_gen.autoplace_controls[control_name] = nil
    end
end

if eon_aquilo_map_gen then
    eon_enable_aquilo_autoplace_controls(eon_aquilo_map_gen)
    if eon_inactive_aquilo_map_gen then
        eon_disable_aquilo_autoplace_controls(eon_inactive_aquilo_map_gen)
    end

    eon_register_planet_autoplace_settings(eon_aquilo_planet_name, "tile", eon_aquilo_tile_names)
    eon_register_planet_autoplace_settings(eon_aquilo_planet_name, "decorative", eon_aquilo_decorative_list)
    eon_register_planet_autoplace_settings(eon_aquilo_planet_name, "entity", eon_aquilo_resource_list, "resource")
    eon_register_planet_autoplace_settings(eon_aquilo_planet_name, "entity", eon_aquilo_simple_entity_list)
end

if eon_aquilo_on_fulgora then
    local fulgora_settings = data.raw.planet["fulgora"].map_gen_settings.autoplace_settings

    if fulgora_settings then
        for tile_name, _ in pairs(fulgora_settings.tile.settings) do
            if not eon_aquilo_tile_name_set[tile_name] and data.raw.tile[tile_name] then
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
                if data.raw.resource[entity_name] then
                    eon_wrap_probability_expression(data.raw.resource[entity_name],
                        "eon_mask_off_aquilo_territory")
                elseif data.raw["simple-entity"][entity_name] then
                    eon_wrap_probability_expression(data.raw["simple-entity"][entity_name],
                        "eon_mask_off_aquilo_territory")
                end
            end
        end
    end
end

terrain.mask_aquilo_territory("lithium-brine", "resource")
terrain.mask_aquilo_territory("fluorine-vent", "resource")

if not eon_aquilo_on_fulgora then
    if data.raw.resource["lithium-brine"] and data.raw.resource["lithium-brine"].autoplace then
        eon_set_entity_property_expression(
            "nauvis",
            "lithium-brine",
            "probability",
            data.raw.resource["lithium-brine"].autoplace.probability_expression
        )
        eon_set_entity_property_expression(
            "nauvis",
            "lithium-brine",
            "richness",
            data.raw.resource["lithium-brine"].autoplace.richness_expression
        )
    end

    if data.raw.resource["fluorine-vent"] and data.raw.resource["fluorine-vent"].autoplace then
        eon_set_entity_property_expression(
            "nauvis",
            "fluorine-vent",
            "probability",
            data.raw.resource["fluorine-vent"].autoplace.probability_expression
        )
        eon_set_entity_property_expression(
            "nauvis",
            "fluorine-vent",
            "richness",
            data.raw.resource["fluorine-vent"].autoplace.richness_expression
        )
    end
end

eon_mask_generated_surface_tiles("aquilo", terrain.mask_aquilo_territory, {
    ["ammoniacal-ocean"] = true,
    ["ammoniacal-ocean-2"] = true,
    ["snow-flat"] = true,
    ["ice-rough"] = true,
    ["ice-smooth"] = true,
    ["brash-ice"] = true,
})

data_util.apply_mask_group {
    names = eon_generated_worldgen.aquilo.decoratives,
    prototype_type = "optimized-decorative",
    mask = terrain.mask_aquilo_decorative_territory,
}

data_util.apply_mask_group {
    names = eon_generated_worldgen.aquilo.entities,
    prototype_type = "simple-entity",
    mask = terrain.mask_aquilo_territory,
}

eon_mask_prototypes("optimized-decorative", {
    "floating-iceberg-large",
    "floating-iceberg-small",
}, terrain.mask_aquilo_decorative_territory)

eon_mask_prototypes("optimized-decorative", {
    "aqulio-snowy-decal",
    "snow-drift-decal",
}, terrain.mask_aquilo_snow_decorative_territory)

if not eon_aquilo_on_fulgora then
    data:extend({
        {
            type = "noise-expression",
            name = "eon_nauvis_aquilo_lithium_brine_spots",
            expression =
            "aquilo_spot_noise{seed = 567, count = 3, skip_offset = 1, region_size = 600 + 400 / control:lithium_brine:frequency, density = eon_aquilo_land > 0, radius = aquilo_spot_size * 1.2 * sqrt(control:lithium_brine:size), favorability = max(0, eon_aquilo_land)}"
        },
        {
            type = "noise-expression",
            name = "eon_nauvis_aquilo_lithium_brine_probability",
            expression =
            "eon_mask_aquilo_territory((control:lithium_brine:size > 0) * max(0, eon_nauvis_aquilo_lithium_brine_spots) * 0.012)"
        },
        {
            type = "noise-expression",
            name = "eon_nauvis_aquilo_lithium_brine_richness",
            expression = "max(0, eon_nauvis_aquilo_lithium_brine_spots) * 720000 * control:lithium_brine:richness"
        },
        {
            type = "noise-expression",
            name = "eon_nauvis_aquilo_fluorine_vent_spots",
            expression =
            "aquilo_spot_noise{seed = 567, count = 2, skip_offset = 2, region_size = 600 + 400 / control:fluorine_vent:frequency, density = eon_aquilo_land > 0, radius = aquilo_spot_size * 1.5 * sqrt(control:fluorine_vent:size), favorability = max(0, eon_aquilo_land)}"
        },
        {
            type = "noise-expression",
            name = "eon_nauvis_aquilo_fluorine_vent_probability",
            expression =
            "eon_mask_aquilo_territory((control:fluorine_vent:size > 0) * max(0, eon_nauvis_aquilo_fluorine_vent_spots) * 0.008)"
        },
        {
            type = "noise-expression",
            name = "eon_nauvis_aquilo_fluorine_vent_richness",
            expression = "max(0, eon_nauvis_aquilo_fluorine_vent_spots) * 520000 * control:fluorine_vent:richness"
        }
    })

    if data.raw.resource["lithium-brine"] and data.raw.resource["lithium-brine"].autoplace then
        data.raw.resource["lithium-brine"].autoplace.probability_expression =
        "eon_nauvis_aquilo_lithium_brine_probability"
        data.raw.resource["lithium-brine"].autoplace.richness_expression =
        "eon_nauvis_aquilo_lithium_brine_richness"
        eon_set_entity_property_expression("nauvis", "lithium-brine", "probability",
            "eon_nauvis_aquilo_lithium_brine_probability")
        eon_set_entity_property_expression("nauvis", "lithium-brine", "richness",
            "eon_nauvis_aquilo_lithium_brine_richness")
    end

    if data.raw.resource["fluorine-vent"] and data.raw.resource["fluorine-vent"].autoplace then
        data.raw.resource["fluorine-vent"].autoplace.probability_expression =
        "eon_nauvis_aquilo_fluorine_vent_probability"
        data.raw.resource["fluorine-vent"].autoplace.richness_expression =
        "eon_nauvis_aquilo_fluorine_vent_richness"
        eon_set_entity_property_expression("nauvis", "fluorine-vent", "probability",
            "eon_nauvis_aquilo_fluorine_vent_probability")
        eon_set_entity_property_expression("nauvis", "fluorine-vent", "richness",
            "eon_nauvis_aquilo_fluorine_vent_richness")
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
data.raw.tile["brash-ice"].autoplace.probability_expression =
"eon_mask_aquilo_territory(eon_aquilo_base(eon_aquilo_ammonia_depth + 0.5, 200))"

data:extend({
    {
        type = "autoplace-control",
        name = "ammonia_ocean",
        localised_description = nil,
        order = "z-ammonia",
        category = "resource",
        hidden = false,
        can_be_disabled = false
    },
})

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
            ammonia_level = "2 * pow(log2(1 + control:ammonia_ocean:size), 1.3)",
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
})


eon_register_gleba_map_gen_on_nauvis()

eon_mask_generated_surface_tiles("gleba", terrain.mask_gleba_territory)

data_util.apply_mask_group {
    names = eon_generated_worldgen.gleba.decoratives,
    prototype_type = "optimized-decorative",
    mask = terrain.mask_gleba_territory,
}

data_util.apply_mask_group {
    names = eon_generated_worldgen.gleba.entities,
    prototype_type = "simple-entity",
    mask = terrain.mask_gleba_territory,
}

eon_mask_prototypes("optimized-decorative", {
    "nerve-roots-dense",
    "nerve-roots-sparse",
    "green-carpet-grass",
    "green-hairy-grass",
    "light-mud-decal",
    "dark-mud-decal",
    "cracked-mud-decal",
    "red-desert-bush",
    "white-desert-bush",
    "red-pita",
    "green-bush-mini",
    "green-croton",
    "green-pita",
    "green-pita-mini",
    "lichen-decal",
    "shroom-decal",
}, terrain.mask_gleba_territory)

data_util.apply_mask_group {
    names = eon_generated_worldgen.gleba.trees,
    prototype_type = "tree",
    mask = terrain.mask_gleba_territory,
}

data_util.apply_mask_group {
    names = eon_generated_worldgen.gleba.plants,
    prototype_type = "plant",
    mask = terrain.mask_gleba_territory,
}

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
        expression = "clamp(eon_gleba_agriculture_spots(1, 64) * 5000, -inf, 2)"
    },
    {
        type = "noise-expression",
        name = "eon_yumako_spots",
        expression = "clamp(eon_gleba_agriculture_spots(2, 64) * 5000, -inf, 2)"
    },
    {
        type = "noise-expression",
        name = "eon_jellynut_soil",
        expression = "eon_gleba_agriculture_spots(1, 32) * 6"
    },
    {
        type = "noise-expression",
        name = "eon_yumako_soil",
        expression = "eon_gleba_agriculture_spots(2, 32) * 6"
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
            y_offset = "y - 1000",
            south_offset = "y_offset / (1 + pow(2, 0.01 * y_offset)) + 0.1 * y_offset - 60"
        }
    },
    {
        type = "noise-function",
        name = "eon_gleba_agriculture_spots",
        parameters = { "seed", "spot_radius_expression" },
        expression = "eon_mask_gleba_territory(spot_noise{x = x + wobble_noise_x * 15,\z
                                                      y = y + wobble_noise_y * 15,\z
                                                      seed0 = map_seed,\z
                                                      seed1 = seed,\z
                                                      candidate_spot_count = 4,\z
                                                      suggested_minimum_candidate_point_spacing = 128,\z
                                                      skip_span = 1,\z
                                                      skip_offset = 0,\z
                                                      region_size = 1024,\z
                                                      density_expression = 80,\z
                                                      spot_quantity_expression = 1000,\z
                                                      spot_radius_expression = spot_radius_expression,\z
                                                      hard_region_target_quantity = 0,\z
                                                      spot_favorability_expression = 60,\z
                                                      basement_value = -0.5,\z
                                                      maximum_spot_basement_radius = 128})",
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


local eon_vulcanus_tile_names = eon_generated_tiles.vulcanus

if eon_aquilo_on_fulgora then
    eon_register_vulcanus_map_gen_on_nauvis(eon_vulcanus_tile_names)
else
    eon_register_vulcanus_map_gen_on_nauvis({
        "volcanic-folds",
        "volcanic-folds-flat",
        "lava",
        "lava-hot",
    })
end

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
    eon_mask_generated_surface_tiles("vulcanus", terrain.mask_vulcano_coverage, {
        ["volcanic-soil-dark"] = true,
        ["volcanic-soil-light"] = true,
        ["volcanic-ash-soil"] = true,
        ["volcanic-folds"] = true,
        ["volcanic-folds-flat"] = true,
        ["lava"] = true,
        ["lava-hot"] = true,
    })

    data.raw.tile["volcanic-folds"].autoplace.probability_expression =
    "eon_updated_volcanic_folds"
    data.raw.tile["volcanic-folds-flat"].autoplace.probability_expression =
    "eon_updated_volcanic_folds_flat"
    data.raw.tile["lava"].autoplace.probability_expression = "eon_lava_mountains_range"
    data.raw.tile["lava-hot"].autoplace.probability_expression = "eon_lava_hot_mountains_range"
    data.raw.cliff["crater-cliff"].autoplace.probability_expression = "eon_lava_hot_mountains_range"
end

data_util.apply_mask_group {
    names = eon_generated_worldgen.vulcanus.entities,
    prototype_type = "simple-entity",
    mask = terrain.mask_vulcano_coverage,
}

data_util.apply_mask_group {
    names = eon_generated_worldgen.vulcanus.decoratives,
    prototype_type = "optimized-decorative",
    mask = terrain.mask_vulcano_terrain,
}

data_util.apply_mask_group {
    names = eon_generated_worldgen.vulcanus.trees,
    prototype_type = "tree",
    mask = terrain.mask_vulcano_terrain,
}

eon_mask_prototypes("optimized-decorative", {
    "crater-small",
    "crater-large",
    "pumice-relief-decal",
    "waves-decal",
}, terrain.mask_vulcano_terrain)

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
