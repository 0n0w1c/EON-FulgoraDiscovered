---@type table<string, boolean>
local CRAFT_DECO_ROCK_SUBGROUPS = {
    ["craftable-rocks"] = true,
    ["craftable-alien-biomes-rocks"] = true,
    ["craftable-simple-rocks"] = true,
}

---@class EonCraftDecoRockFamily
---@field base_name string
---@field match fun(name: string): boolean

---@type EonCraftDecoRockFamily[]
local ROCK_FAMILIES = {
    {
        base_name = "huge-rock",
        match = function(name)
            return string.match(name, "^rock%-huge%-") ~= nil
        end,
    },
    {
        base_name = "big-rock",
        match = function(name)
            return string.match(name, "^rock%-big%-") ~= nil
        end,
    },
}

---@param subgroup_name string|nil
---@return boolean
local function is_environment_subgroup(subgroup_name)
    if not subgroup_name then return false end

    local subgroup = data.raw["item-subgroup"] and data.raw["item-subgroup"][subgroup_name]
    return subgroup ~= nil and subgroup.group == "environment"
end

---@param name string
---@return boolean
local function is_craft_deco_rock_item(name)
    if not mods["craft-deco-2"] then return false end

    local item = data.raw.item and data.raw.item[name]
    return item ~= nil
        and is_environment_subgroup(item.subgroup)
        and CRAFT_DECO_ROCK_SUBGROUPS[item.subgroup] == true
        and item.place_result == name
end

---@param name string
---@return boolean
local function is_rock_entity(name)
    return data.raw["simple-entity"] ~= nil
        and data.raw["simple-entity"][name] ~= nil
end

---@param family EonCraftDecoRockFamily
---@return string[]
local function collect_family_variants(family)
    local result = {}

    for name, _ in pairs(data.raw.item or {}) do
        if name ~= family.base_name
            and family.match(name)
            and is_craft_deco_rock_item(name)
            and is_rock_entity(name)
        then
            table.insert(result, name)
        end
    end

    table.sort(result)
    return result
end

---@param autoplace table
---@return table
local function copy_autoplace(autoplace)
    local result = table.deepcopy(autoplace)
    result.local_expressions = table.deepcopy(autoplace.local_expressions)
    return result
end

---@param expression string
---@param multiplier number
---@return string
local function scaled_expression(expression, multiplier)
    return "(" .. multiplier .. ") * (" .. expression .. ")"
end

---@param planet_name string
---@return table|nil
local function planet_entity_autoplace_settings(planet_name)
    local planet = data.raw.planet and data.raw.planet[planet_name]
    local map_gen_settings = planet and planet.map_gen_settings
    if not map_gen_settings then return nil end

    map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
    map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or { settings = {} }
    map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

    return map_gen_settings.autoplace_settings.entity.settings
end

---@param names string[]
local function register_nauvis_rock_settings(names)
    local settings = planet_entity_autoplace_settings("nauvis")
    if not settings then return end

    for _, name in ipairs(names) do
        settings[name] = settings[name] or {}
    end
end

---@param names string[]
local function remove_fulgora_rock_settings(names)
    local settings = planet_entity_autoplace_settings("fulgora")
    if not settings then return end

    for _, name in ipairs(names) do
        settings[name] = nil
    end
end

---@param family EonCraftDecoRockFamily
---@param registered_names string[]
---@return nil
local function apply_family_rock_variety(family, registered_names)
    local base = data.raw["simple-entity"] and data.raw["simple-entity"][family.base_name]
    if not (base and base.autoplace and base.autoplace.probability_expression) then return end

    local variants = collect_family_variants(family)
    if #variants == 0 then return end

    local original_probability_expression = base.autoplace.probability_expression
    if type(original_probability_expression) ~= "string" then return end

    local equal_probability = 1 / (#variants + 1)

    base.autoplace.probability_expression = scaled_expression(original_probability_expression, equal_probability)

    for _, variant_name in ipairs(variants) do
        local variant = data.raw["simple-entity"][variant_name]
        variant.autoplace = copy_autoplace(base.autoplace)
        variant.autoplace.order = "z[rock]-c[craft-deco-2]-" .. variant_name
        variant.autoplace.probability_expression = scaled_expression(original_probability_expression, equal_probability)
        table.insert(registered_names, variant_name)
    end
end

if mods["craft-deco-2"] then
    local registered_names = {}

    for _, family in ipairs(ROCK_FAMILIES) do
        apply_family_rock_variety(family, registered_names)
    end

    register_nauvis_rock_settings(registered_names)
    remove_fulgora_rock_settings(registered_names)
end
