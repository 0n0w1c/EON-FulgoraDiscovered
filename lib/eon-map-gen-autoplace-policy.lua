local eon_map_gen_autoplace_policy = {}

---@param map_gen table|nil Map gen settings table.
---@param control_name string
---@param enabled boolean|nil Pass false to remove the control; any other value enables it.
---@param control_settings table|nil Optional settings to assign when enabled.
---@return boolean changed
function eon_map_gen_autoplace_policy.set_map_gen_autoplace_control(map_gen, control_name, enabled, control_settings)
    if type(map_gen) ~= "table" or type(control_name) ~= "string" then return false end

    map_gen.autoplace_controls = map_gen.autoplace_controls or {}

    if enabled == false then
        if map_gen.autoplace_controls[control_name] == nil then return false end
        map_gen.autoplace_controls[control_name] = nil
        return true
    end

    map_gen.autoplace_controls[control_name] = control_settings or {}
    return true
end

---@param map_gen table|nil Map gen settings table.
---@param control_names string[]
---@param enabled boolean|nil Pass false to remove controls; any other value enables them.
---@return integer changed_count
function eon_map_gen_autoplace_policy.set_map_gen_autoplace_controls(map_gen, control_names, enabled)
    local changed = 0
    for _, control_name in ipairs(control_names or {}) do
        if eon_map_gen_autoplace_policy.set_map_gen_autoplace_control(map_gen, control_name, enabled) then
            changed = changed + 1
        end
    end
    return changed
end

---@param planet_name string
---@param control_name string
---@param enabled boolean|nil Pass false to remove the control; any other value enables it.
---@param control_settings table|nil Optional settings to assign when enabled.
---@return boolean changed
function eon_map_gen_autoplace_policy.set_planet_autoplace_control(planet_name, control_name, enabled, control_settings)
    local planet = data.raw["planet"] and data.raw["planet"][planet_name]
    local map_gen = planet and planet.map_gen_settings
    if not map_gen then return false end
    return eon_map_gen_autoplace_policy.set_map_gen_autoplace_control(map_gen, control_name, enabled, control_settings)
end

---@param planet_name string
---@param control_names string[]
---@param enabled boolean|nil Pass false to remove controls; any other value enables them.
---@return integer changed_count
function eon_map_gen_autoplace_policy.set_planet_autoplace_controls(planet_name, control_names, enabled)
    local planet = data.raw["planet"] and data.raw["planet"][planet_name]
    local map_gen = planet and planet.map_gen_settings
    if not map_gen then return 0 end
    return eon_map_gen_autoplace_policy.set_map_gen_autoplace_controls(map_gen, control_names, enabled)
end

---@param planet_name string
---@param create boolean|nil Defaults to true.
---@return table<string, boolean|string|number>|nil names
function eon_map_gen_autoplace_policy.planet_property_expression_names(planet_name, create)
    local planet = data.raw["planet"] and data.raw["planet"][planet_name]
    local map_gen = planet and planet.map_gen_settings
    if not map_gen then return nil end

    if create == false then
        return map_gen.property_expression_names
    end

    map_gen.property_expression_names = map_gen.property_expression_names or {}
    return map_gen.property_expression_names
end

---@param planet_name string
---@param property_key string
---@param expression_name string
---@return boolean changed
function eon_map_gen_autoplace_policy.set_planet_property_expression(planet_name, property_key, expression_name)
    local names = eon_map_gen_autoplace_policy.planet_property_expression_names(planet_name)
    if not names or type(property_key) ~= "string" or type(expression_name) ~= "string" then return false end
    names[property_key] = expression_name
    return true
end

---@param planet_name string
---@param entity_name string
---@param property_name string Either "probability" or "richness".
---@return string|nil expression_name
function eon_map_gen_autoplace_policy.get_planet_entity_property_expression(planet_name, entity_name, property_name)
    local names = eon_map_gen_autoplace_policy.planet_property_expression_names(planet_name, false)
    if not names then return nil end

    local expression_name = names["entity:" .. entity_name .. ":" .. property_name]
    if type(expression_name) == "string" and expression_name ~= "" then
        return expression_name
    end

    return nil
end

---@param planet_name string
---@param entity_name string
---@param property_name string Either "probability" or "richness".
---@param expression_name string
---@return boolean changed
function eon_map_gen_autoplace_policy.set_planet_entity_property_expression(planet_name, entity_name, property_name,
                                                                            expression_name)
    return eon_map_gen_autoplace_policy.set_planet_property_expression(
        planet_name,
        "entity:" .. entity_name .. ":" .. property_name,
        expression_name
    )
end

---@param map_gen table|nil Map gen settings table.
---@param category string Autoplace settings category, such as "entity", "tile", or "decorative".
---@param create boolean|nil When false, only returns an existing settings table. Defaults to true.
---@return table|nil settings
function eon_map_gen_autoplace_policy.map_gen_autoplace_category_settings(map_gen, category, create)
    if type(map_gen) ~= "table" or type(category) ~= "string" then return nil end

    if create == false then
        return map_gen.autoplace_settings
            and map_gen.autoplace_settings[category]
            and map_gen.autoplace_settings[category].settings
    end

    map_gen.autoplace_settings = map_gen.autoplace_settings or {}
    map_gen.autoplace_settings[category] = map_gen.autoplace_settings[category] or { settings = {} }
    map_gen.autoplace_settings[category].settings = map_gen.autoplace_settings[category].settings or {}

    return map_gen.autoplace_settings[category].settings
end

---@param planet_name string
---@param category string
---@param create boolean|nil When false, only returns an existing settings table. Defaults to true.
---@return table|nil settings
function eon_map_gen_autoplace_policy.planet_autoplace_category_settings(planet_name, category, create)
    local planet = data.raw["planet"] and data.raw["planet"][planet_name]
    local map_gen = planet and planet.map_gen_settings
    return eon_map_gen_autoplace_policy.map_gen_autoplace_category_settings(map_gen, category, create)
end

---@param planet_name string
---@param category string
---@param prototype_names string[]
---@return integer removed_count
function eon_map_gen_autoplace_policy.remove_planet_autoplace_settings(planet_name, category, prototype_names)
    local settings = eon_map_gen_autoplace_policy.planet_autoplace_category_settings(planet_name, category, false)
    if not settings then return 0 end

    local removed = 0
    for _, prototype_name in ipairs(prototype_names or {}) do
        if settings[prototype_name] ~= nil then
            settings[prototype_name] = nil
            removed = removed + 1
        end
    end

    return removed
end

---@param map_gen table|nil Map gen settings table.
---@param category string Autoplace settings category, such as "entity", "tile", or "decorative".
---@param prototype_name string Prototype name to ensure in the category settings table.
---@param settings table|nil Optional settings table. Defaults to an empty table.
---@return boolean changed
function eon_map_gen_autoplace_policy.ensure_map_gen_autoplace_setting(map_gen, category, prototype_name, settings)
    if type(map_gen) ~= "table" or type(category) ~= "string" or type(prototype_name) ~= "string" then
        return false
    end

    local category_settings = eon_map_gen_autoplace_policy.map_gen_autoplace_category_settings(map_gen, category)
    if not category_settings then return false end

    if category_settings[prototype_name] ~= nil then return false end
    category_settings[prototype_name] = settings or {}
    return true
end

---@param planet_name string
---@param category string
---@param prototype_name string
---@param settings table|nil
---@return boolean changed
function eon_map_gen_autoplace_policy.ensure_planet_autoplace_setting(planet_name, category, prototype_name, settings)
    local planet = data.raw["planet"] and data.raw["planet"][planet_name]
    local map_gen = planet and planet.map_gen_settings
    if not map_gen then return false end
    return eon_map_gen_autoplace_policy.ensure_map_gen_autoplace_setting(map_gen, category, prototype_name, settings)
end

---@param planet_name string
---@param category string
---@param prototype_names string[]
---@return integer changed_count
function eon_map_gen_autoplace_policy.ensure_planet_autoplace_settings(planet_name, category, prototype_names)
    local changed = 0
    for _, prototype_name in ipairs(prototype_names or {}) do
        if eon_map_gen_autoplace_policy.ensure_planet_autoplace_setting(planet_name, category, prototype_name) then
            changed = changed + 1
        end
    end
    return changed
end

---@param source_planet_name string
---@param target_planet_name string
---@param category string|nil Autoplace control prototype category filter, such as "resource".
---@return integer changed_count
function eon_map_gen_autoplace_policy.copy_planet_autoplace_controls_by_category(source_planet_name, target_planet_name,
                                                                                 category)
    local source_planet = data.raw["planet"] and data.raw["planet"][source_planet_name]
    local target_planet = data.raw["planet"] and data.raw["planet"][target_planet_name]
    local source_map_gen = source_planet and source_planet.map_gen_settings
    local target_map_gen = target_planet and target_planet.map_gen_settings

    if not (source_map_gen and target_map_gen and source_map_gen.autoplace_controls) then return 0 end

    target_map_gen.autoplace_controls = target_map_gen.autoplace_controls or {}

    local changed = 0
    for control_name, control_settings in pairs(source_map_gen.autoplace_controls) do
        local control = data.raw["autoplace-control"] and data.raw["autoplace-control"][control_name]
        if control and (category == nil or control.category == category) then
            control.localised_description = nil
            target_map_gen.autoplace_controls[control_name] = table.deepcopy(control_settings or {})
            changed = changed + 1
        end
    end

    return changed
end

return eon_map_gen_autoplace_policy
