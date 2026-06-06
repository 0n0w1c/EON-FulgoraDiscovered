local water_tiles = require("lib.eon-water-tiles")
local eon_collision_mask_policy = require("lib.eon-collision-mask-policy")
local eon_expression_policy = require("lib.eon-expression-policy")
local eon_map_gen_autoplace_policy = require("lib.eon-map-gen-autoplace-policy")
local eon_autoplace_role_templates = require("lib.eon-autoplace-role-templates")

local policy = {}

local FALLBACK_NAUVIS_LAND_TILES = {
    "grass-1", "grass-2", "grass-3", "grass-4",
    "dry-dirt", "dirt-1", "dirt-2", "dirt-3", "dirt-4", "dirt-5", "dirt-6", "dirt-7",
    "sand-1", "sand-2", "sand-3",
    "red-desert-0", "red-desert-1", "red-desert-2", "red-desert-3",
}

---@param names string[]|nil
---@return table<string, boolean>
function policy.make_set(names)
    local set = {}
    for _, name in ipairs(names or {}) do
        set[name] = true
    end
    return set
end

---@param names string[]|nil
---@return string[]
function policy.copy_names(names)
    local result = {}
    for _, name in ipairs(names or {}) do
        result[#result + 1] = name
    end
    return result
end

---@param names string[]|nil
---@param reject_set table<string, boolean>
---@return string[]
function policy.filter_out_set(names, reject_set)
    local result = {}
    for _, name in ipairs(names or {}) do
        if not reject_set[name] then
            result[#result + 1] = name
        end
    end
    return result
end

---@param names string[]|nil
---@return string[]
function policy.filter_land_tiles(names)
    return water_tiles.filter_land_tiles(names or {})
end

---@return string[]
function policy.collect_solid_land_tile_names()
    local tiles = {}

    for tile_name, tile in pairs(data.raw["tile"] or {}) do
        local mask = tile.collision_mask
        local has_ground = false
        local has_water = false

        if type(mask) == "table" and type(mask.layers) == "table" then
            has_ground = mask.layers.ground_tile == true
            has_water = mask.layers.water_tile == true
        elseif type(mask) == "table" then
            for _, mask_layer in pairs(mask) do
                if mask_layer == "ground_tile" then has_ground = true end
                if mask_layer == "water_tile" then has_water = true end
            end
        end

        if has_ground and not has_water and not water_tiles.is_water_tile(tile_name) then
            tiles[#tiles + 1] = tile_name
        end
    end

    if #tiles > 0 then return tiles end
    return policy.copy_names(FALLBACK_NAUVIS_LAND_TILES)
end

---@param value any
---@return any
function policy.copy_value(value)
    if type(value) == "table" then
        return table.deepcopy(value)
    end
    return value
end

---@param autoplace table|nil
---@return table|nil copied_autoplace
function policy.copy_autoplace(autoplace)
    if type(autoplace) ~= "table" then return nil end

    local copied = table.deepcopy(autoplace)
    if type(autoplace.local_expressions) == "table" then
        copied.local_expressions = table.deepcopy(autoplace.local_expressions)
    end

    return copied
end

---@param expression string
---@param multiplier number
---@return string
function policy.scaled_expression(expression, multiplier)
    return "(" .. multiplier .. ") * (" .. expression .. ")"
end

---@param proto table|nil Prototype with autoplace probability expression.
---@param multiplier number
---@return boolean changed
function policy.scale_autoplace_probability(proto, multiplier)
    if type(proto) ~= "table" or type(proto.autoplace) ~= "table" then return false end
    local expression = policy.autoplace_probability_expression(proto)
    if not expression then return false end
    proto.autoplace.probability_expression = policy.scaled_expression(expression, multiplier)
    return true
end

---@param name string
---@param expression string
---@return boolean created
function policy.ensure_noise_expression(name, expression)
    local noise_expressions = data.raw["noise-expression"]
    if not noise_expressions or noise_expressions[name] then return false end

    data:extend({
        {
            type = "noise-expression",
            name = name,
            expression = expression,
        },
    })

    return true
end

---@param config table
---@param tile_names string[]|nil
---@param options table|nil Supports `land_only` and `exclude_water_group`.
---@return table copied_config
function policy.autoplace_config(config, tile_names, options)
    local copied = {}
    for key, value in pairs(config or {}) do
        copied[key] = value
    end

    local restriction = tile_names or copied.tile_restriction
    if restriction then
        local names = policy.copy_names(restriction)
        if options and options.land_only then
            names = policy.filter_land_tiles(names)
        end
        if options and options.exclude_water_group then
            names = policy.filter_out_set(names, policy.water_exclusion_set(options.exclude_water_group))
        end
        copied.tile_restriction = names
    end

    return copied
end

---@param prototype_type string
---@param prototype_name string
---@return table|nil
function policy.autoplace_prototype(prototype_type, prototype_name)
    local prototypes = data.raw[prototype_type]
    local prototype = prototypes and prototypes[prototype_name]
    if not (prototype and prototype.autoplace) then return nil end
    return prototype
end

---@param proto table|nil Prototype with an autoplace table.
---@param tile_names string[]
---@param options table|nil Supports `land_only` and `exclude_water_group`.
---@return boolean changed
function policy.set_autoplace_tile_restriction(proto, tile_names, options)
    if type(proto) ~= "table" or type(proto.autoplace) ~= "table" then return false end

    local names = policy.copy_names(tile_names or {})
    if options and options.land_only then
        names = policy.filter_land_tiles(names)
    end

    if options and options.exclude_water_group then
        names = policy.filter_out_set(names, policy.water_exclusion_set(options.exclude_water_group))
    end

    proto.autoplace.tile_restriction = names
    return true
end

---@param prototype_type string
---@param prototype_name string
---@param tile_names string[]
---@param options table|nil
---@return boolean changed
function policy.restrict_to_tiles(prototype_type, prototype_name, tile_names, options)
    return policy.set_autoplace_tile_restriction(
        policy.autoplace_prototype(prototype_type, prototype_name),
        tile_names,
        options
    )
end

---@param prototype_type string
---@param prototype_name string
---@param tile_names string[]
---@param options table|nil
---@return boolean changed
function policy.extend_tile_restriction(prototype_type, prototype_name, tile_names, options)
    local prototype = policy.autoplace_prototype(prototype_type, prototype_name)
    if not prototype then return false end

    local names = policy.copy_names(tile_names or {})
    if options and options.land_only then
        names = policy.filter_land_tiles(names)
    end

    local seen = {}
    local merged = {}

    for _, tile_name in pairs(prototype.autoplace.tile_restriction or {}) do
        if not seen[tile_name] then
            seen[tile_name] = true
            merged[#merged + 1] = tile_name
        end
    end

    for _, tile_name in ipairs(names) do
        if not seen[tile_name] then
            seen[tile_name] = true
            merged[#merged + 1] = tile_name
        end
    end

    prototype.autoplace.tile_restriction = merged
    return true
end

---@param group_name string|nil
---@return table<string, boolean>
function policy.water_exclusion_set(group_name)
    if group_name then
        local named_set = water_tiles.set_for_group(group_name)
        if next(named_set) ~= nil then return named_set end
    end

    return water_tiles.set
end

---@param proto table|nil
---@param fallback_land_tiles string[]
---@param group_name string|nil
---@return boolean changed
function policy.exclude_water_like_tiles_from_existing_restriction(proto, fallback_land_tiles, group_name)
    return policy.exclude_tiles_from_existing_restriction(
        proto,
        fallback_land_tiles,
        policy.water_exclusion_set(group_name)
    )
end

---@param proto table|nil
---@param fallback_land_tiles string[]
---@param excluded_tiles table<string, boolean>|nil
---@return boolean changed
function policy.exclude_tiles_from_existing_restriction(proto, fallback_land_tiles, excluded_tiles)
    if type(proto) ~= "table" or type(proto.autoplace) ~= "table" then return false end

    local restriction = proto.autoplace.tile_restriction
    local reject = excluded_tiles or water_tiles.set

    if type(restriction) ~= "table" then
        proto.autoplace.tile_restriction = policy.copy_names(fallback_land_tiles or {})
        return true
    end

    local filtered = policy.filter_out_set(restriction, reject)
    if #filtered == #restriction then return false end

    if #filtered == 0 then
        filtered = policy.copy_names(fallback_land_tiles or {})
    end

    proto.autoplace.tile_restriction = filtered
    return true
end

---@param mask table|nil Collision mask table from a prototype, if present.
---@param layer string Collision layer name to test.
---@return boolean has_layer True when the layer is present and enabled.
function policy.collision_mask_has_layer(mask, layer)
    return eon_collision_mask_policy.has_layer(mask, layer)
end

---@param proto table|nil Prototype with a collision_mask field.
---@param layer string Collision layer to add.
---@return boolean changed True when the layer was newly added.
function policy.add_collision_mask_layer(proto, layer)
    return eon_collision_mask_policy.add_layer(proto, layer)
end

---@param layers string[]
---@return table collision_mask
function policy.make_collision_mask(layers)
    return eon_collision_mask_policy.make(layers)
end

---@param map_gen table|nil Map gen settings table.
---@param control_name string
---@param enabled boolean|nil Pass false to remove the control; any other value enables it.
---@param control_settings table|nil Optional settings to assign when enabled.
---@return boolean changed
function policy.set_map_gen_autoplace_control(map_gen, control_name, enabled, control_settings)
    return eon_map_gen_autoplace_policy.set_map_gen_autoplace_control(map_gen, control_name, enabled, control_settings)
end

---@param map_gen table|nil Map gen settings table.
---@param control_names string[]
---@param enabled boolean|nil Pass false to remove controls; any other value enables them.
---@return integer changed_count
function policy.set_map_gen_autoplace_controls(map_gen, control_names, enabled)
    return eon_map_gen_autoplace_policy.set_map_gen_autoplace_controls(map_gen, control_names, enabled)
end

---@param planet_name string
---@param control_name string
---@param enabled boolean|nil Pass false to remove the control; any other value enables it.
---@param control_settings table|nil Optional settings to assign when enabled.
---@return boolean changed
function policy.set_planet_autoplace_control(planet_name, control_name, enabled, control_settings)
    return eon_map_gen_autoplace_policy.set_planet_autoplace_control(planet_name, control_name, enabled, control_settings)
end

---@param planet_name string
---@param control_names string[]
---@param enabled boolean|nil Pass false to remove controls; any other value enables them.
---@return integer changed_count
function policy.set_planet_autoplace_controls(planet_name, control_names, enabled)
    return eon_map_gen_autoplace_policy.set_planet_autoplace_controls(planet_name, control_names, enabled)
end

---@param map_gen table|nil Map gen settings table.
---@param category string Autoplace settings category, such as "entity", "tile", or "decorative".
---@param create boolean|nil When false, only returns an existing settings table. Defaults to true.
---@return table|nil settings
function policy.map_gen_autoplace_category_settings(map_gen, category, create)
    return eon_map_gen_autoplace_policy.map_gen_autoplace_category_settings(map_gen, category, create)
end

---@param planet_name string
---@param category string
---@param create boolean|nil When false, only returns an existing settings table. Defaults to true.
---@return table|nil settings
function policy.planet_autoplace_category_settings(planet_name, category, create)
    return eon_map_gen_autoplace_policy.planet_autoplace_category_settings(planet_name, category, create)
end

---@param planet_name string
---@param category string
---@param prototype_names string[]
---@return integer removed_count
function policy.remove_planet_autoplace_settings(planet_name, category, prototype_names)
    return eon_map_gen_autoplace_policy.remove_planet_autoplace_settings(planet_name, category, prototype_names)
end

---@param map_gen table|nil Map gen settings table.
---@param category string Autoplace settings category, such as "entity", "tile", or "decorative".
---@param prototype_name string Prototype name to ensure in the category settings table.
---@param settings table|nil Optional settings table. Defaults to an empty table.
---@return boolean changed
function policy.ensure_map_gen_autoplace_setting(map_gen, category, prototype_name, settings)
    return eon_map_gen_autoplace_policy.ensure_map_gen_autoplace_setting(map_gen, category, prototype_name, settings)
end

---@param planet_name string
---@param category string
---@param prototype_name string
---@param settings table|nil
---@return boolean changed
function policy.ensure_planet_autoplace_setting(planet_name, category, prototype_name, settings)
    return eon_map_gen_autoplace_policy.ensure_planet_autoplace_setting(planet_name, category, prototype_name, settings)
end

---@param planet_name string
---@param category string
---@param prototype_names string[]
---@return integer changed_count
function policy.ensure_planet_autoplace_settings(planet_name, category, prototype_names)
    return eon_map_gen_autoplace_policy.ensure_planet_autoplace_settings(planet_name, category, prototype_names)
end

---@param source_planet_name string
---@param target_planet_name string
---@param category string|nil Autoplace control prototype category filter, such as "resource".
---@return integer changed_count
function policy.copy_planet_autoplace_controls_by_category(source_planet_name, target_planet_name, category)
    return eon_map_gen_autoplace_policy.copy_planet_autoplace_controls_by_category(source_planet_name, target_planet_name,
        category)
end

---@param proto table|nil Prototype with an autoplace table.
---@param property_name string Either "probability" or "richness".
---@return string|nil expression
function policy.autoplace_expression(proto, property_name)
    if type(proto) ~= "table" or type(proto.autoplace) ~= "table" then return nil end

    local expression_field = property_name .. "_expression"
    local literal_field = property_name
    local expression = proto.autoplace[expression_field]

    if type(expression) == "string" and expression ~= "" then
        return expression
    end

    if proto.autoplace[literal_field] ~= nil then
        expression = tostring(proto.autoplace[literal_field])
        proto.autoplace[literal_field] = nil
        return expression
    end

    return nil
end

---@param proto table|nil Prototype with an autoplace table.
---@return string|nil expression
function policy.autoplace_probability_expression(proto)
    return policy.autoplace_expression(proto, "probability")
end

---@param proto table|nil Prototype with an autoplace table.
---@return string|nil expression
function policy.autoplace_richness_expression(proto)
    return policy.autoplace_expression(proto, "richness")
end

---@param planet_name string
---@param create boolean|nil Defaults to true.
---@return table<string, string>|nil names
function policy.planet_property_expression_names(planet_name, create)
    return eon_map_gen_autoplace_policy.planet_property_expression_names(planet_name, create)
end

---@param planet_name string
---@param property_key string
---@param expression_name string
---@return boolean changed
function policy.set_planet_property_expression(planet_name, property_key, expression_name)
    return eon_map_gen_autoplace_policy.set_planet_property_expression(planet_name, property_key, expression_name)
end

---@param planet_name string
---@param entity_name string
---@param property_name string Either "probability" or "richness".
---@return string|nil expression_name
function policy.get_planet_entity_property_expression(planet_name, entity_name, property_name)
    return eon_map_gen_autoplace_policy.get_planet_entity_property_expression(planet_name, entity_name, property_name)
end

---@param planet_name string
---@param entity_name string
---@param property_name string Either "probability" or "richness".
---@param expression_name string
---@return boolean changed
function policy.set_planet_entity_property_expression(planet_name, entity_name, property_name, expression_name)
    return eon_map_gen_autoplace_policy.set_planet_entity_property_expression(planet_name, entity_name, property_name,
        expression_name)
end

---@param expression string
---@param wrapper_name string
---@return string
function policy.wrap_expression(expression, wrapper_name)
    return eon_expression_policy.wrap(expression, wrapper_name)
end

---@param expressions string[]
---@return string|nil expression
function policy.combine_max_expressions(expressions)
    return eon_expression_policy.combine_max(expressions)
end

---@param expressions string[]
---@param expression string
---@param wrapper_name string
---@return nil
function policy.add_wrapped_expression(expressions, expression, wrapper_name)
    eon_expression_policy.add_wrapped(expressions, expression, wrapper_name)
end

---@param proto table|nil Prototype with an autoplace table.
---@param wrapper_name string
---@param fallback_expression string|nil Defaults to "1".
---@return boolean changed
function policy.wrap_autoplace_probability(proto, wrapper_name, fallback_expression)
    if type(proto) ~= "table" or type(proto.autoplace) ~= "table" then return false end
    local expression = policy.autoplace_probability_expression(proto) or fallback_expression or "1"
    proto.autoplace.probability_expression = policy.wrap_expression(expression, wrapper_name)
    return true
end

---@param value string
---@return string
function policy.sanitized_identifier(value)
    return eon_expression_policy.sanitized_identifier(value)
end

---@param prefix string
---@param prototype_name string
---@param property_name string
---@return string
function policy.prototype_property_expression_name(prefix, prototype_name, property_name)
    return eon_expression_policy.prototype_property_expression_name(prefix, prototype_name, property_name)
end

---@param control_name string
---@param property_name string
---@return string
function policy.control_variable(control_name, property_name)
    return eon_expression_policy.control_variable(control_name, property_name)
end

---@param base_expression string
---@param mask_name string
---@param additive_expression string
---@return string
function policy.max_with_masked_expression(base_expression, mask_name, additive_expression)
    return eon_expression_policy.max_with_masked(base_expression, mask_name, additive_expression)
end

---@param config table Resource patch config containing the vanilla resource_autoplace_all_patches parameters.
---@return string
function policy.resource_autoplace_all_patches_expression(config)
    return eon_expression_policy.resource_autoplace_all_patches(config)
end

---@param config table
---@param patches_name string
---@return string
function policy.resource_probability_from_patches_expression(config, patches_name)
    return eon_expression_policy.resource_probability_from_patches(config, patches_name)
end

---@param config table
---@param patches_name string
---@return string
function policy.resource_richness_from_patches_expression(config, patches_name)
    return eon_expression_policy.resource_richness_from_patches(config, patches_name)
end

---@return table
function policy.role_templates()
    return eon_autoplace_role_templates.templates()
end

return policy
