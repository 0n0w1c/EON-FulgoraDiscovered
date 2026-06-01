local compat = {}

local ORIGINALS = EON_ORIGINAL_AUTOPLACE or {}
EON_ORIGINAL_AUTOPLACE = ORIGINALS

local prototype_types = {
    "tile",
    "optimized-decorative",
    "resource",
    "simple-entity",
    "tree",
    "cliff",
    "unit-spawner",
    "turret",
    "lightning-attractor",
}

local category_prototype_types = {
    tile = { "tile" },
    decorative = { "optimized-decorative" },
    entity = {
        "resource",
        "simple-entity",
        "tree",
        "cliff",
        "unit-spawner",
        "turret",
        "lightning-attractor",
    },
}

local controlled_planets = {
    nauvis = true,
    fulgora = true,
}

---@param value string
---@return string
local function safe_name(value)
    local result = string.gsub(value, "[^%w_]", "_")
    return result
end

---@param prototype_type string
---@param prototype_name string
---@return string
local function key(prototype_type, prototype_name)
    return prototype_type .. "/" .. prototype_name
end

---@param category string
---@return string
local function property_prefix(category)
    if category == "tile" then return "tile" end
    if category == "decorative" then return "decorative" end
    return "entity"
end

---@param category string
---@param prototype_name string
---@return string|nil, table|nil
local function find_prototype(category, prototype_name)
    for _, prototype_type in pairs(category_prototype_types[category] or {}) do
        local prototype = data.raw[prototype_type] and data.raw[prototype_type][prototype_name]
        if prototype and prototype.autoplace then
            return prototype_type, prototype
        end
    end
    return nil, nil
end

---@param expression_name string
---@param expression any
---@return string|nil
local function add_original_expression(expression_name, expression)
    if type(expression) ~= "string" or expression == "" then return nil end

    if data.raw["noise-expression"] and data.raw["noise-expression"][expression_name] then
        return expression_name
    end

    data:extend({
        {
            type = "noise-expression",
            name = expression_name,
            expression = expression,
        }
    })

    return expression_name
end

---@return nil
function compat.capture_original_autoplace()
    if ORIGINALS.__captured then return end
    ORIGINALS.__captured = true

    for _, prototype_type in pairs(prototype_types) do
        for prototype_name, prototype in pairs(data.raw[prototype_type] or {}) do
            local autoplace = prototype.autoplace
            if autoplace then
                local record = {}

                record.probability_expression_name = add_original_expression(
                    "eon_original_" .. safe_name(prototype_type) .. "_" .. safe_name(prototype_name) .. "_probability",
                    autoplace.probability_expression
                )

                record.richness_expression_name = add_original_expression(
                    "eon_original_" .. safe_name(prototype_type) .. "_" .. safe_name(prototype_name) .. "_richness",
                    autoplace.richness_expression
                )

                if record.probability_expression_name or record.richness_expression_name then
                    ORIGINALS[key(prototype_type, prototype_name)] = record
                end
            end
        end
    end
end

---@return nil
function compat.restore_external_planets()
    local restored_planets = 0
    local restored_expressions = 0

    for planet_name, planet in pairs(data.raw.planet or {}) do
        if not controlled_planets[planet_name] then
            local map_gen = planet.map_gen_settings
            local autoplace_settings = map_gen and map_gen.autoplace_settings

            if map_gen and autoplace_settings then
                map_gen.property_expression_names = map_gen.property_expression_names or {}
                local planet_restored = 0

                for category, category_settings in pairs(autoplace_settings) do
                    local settings = category_settings and category_settings.settings
                    if settings then
                        for prototype_name, _ in pairs(settings) do
                            local prototype_type = find_prototype(category, prototype_name)
                            local original = prototype_type and ORIGINALS[key(prototype_type, prototype_name)]

                            if original then
                                local prefix = property_prefix(category)

                                if original.probability_expression_name then
                                    map_gen.property_expression_names[
                                    prefix .. ":" .. prototype_name .. ":probability"
                                    ] = original.probability_expression_name
                                    planet_restored = planet_restored + 1
                                end

                                if prefix == "entity" and original.richness_expression_name then
                                    map_gen.property_expression_names[
                                    prefix .. ":" .. prototype_name .. ":richness"
                                    ] = original.richness_expression_name
                                    planet_restored = planet_restored + 1
                                end
                            end
                        end
                    end
                end

                if planet_restored > 0 then
                    restored_planets = restored_planets + 1
                    restored_expressions = restored_expressions + planet_restored
                end
            end
        end
    end
end

return compat
