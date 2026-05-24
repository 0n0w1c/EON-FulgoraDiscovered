local data_util = {}

local tile_cache = {}

---@alias EONPrototypeName string
---@alias EONPrototypeList EONPrototypeName[]
---@alias EONPrototypeSet table<EONPrototypeName, boolean>

---Cache key.
---@param surface_names? EONPrototypeList
---@param extra_names? EONPrototypeList
---@param excluded_names? EONPrototypeSet
local function cache_key(surface_names, extra_names, excluded_names)
    local parts = {}

    for _, value in ipairs(surface_names or {}) do
        table.insert(parts, "surface:" .. value)
    end

    for _, value in ipairs(extra_names or {}) do
        table.insert(parts, "extra:" .. value)
    end

    for value in pairs(excluded_names or {}) do
        table.insert(parts, "exclude:" .. value)
    end

    table.sort(parts)
    return table.concat(parts, "|")
end

---Copy values.
---@param values EONPrototypeList
local function copy_values(values)
    local result = {}
    for _, value in ipairs(values or {}) do
        table.insert(result, value)
    end
    return result
end

local prototype_cache = {}

---Prototype cache key.
---@param kind string
---@param prototype_type string
---@param values EONPrototypeList
---@param extra_names? EONPrototypeList
---@param excluded_names? EONPrototypeSet
local function prototype_cache_key(kind, prototype_type, values, extra_names, excluded_names)
    local parts = { "kind:" .. kind, "type:" .. prototype_type }

    for _, value in ipairs(values or {}) do
        table.insert(parts, "value:" .. value)
    end

    for _, value in ipairs(extra_names or {}) do
        table.insert(parts, "extra:" .. value)
    end

    for value in pairs(excluded_names or {}) do
        table.insert(parts, "exclude:" .. value)
    end

    table.sort(parts)
    return table.concat(parts, "|")
end

---Add existing autoplace prototype.
---@param result EONPrototypeList
---@param seen EONPrototypeSet
---@param prototype_type string
---@param prototype_name string
---@param excluded EONPrototypeSet
local function add_existing_autoplace_prototype(result, seen, prototype_type, prototype_name, excluded)
    local prototypes = data.raw[prototype_type]
    local prototype = prototypes and prototypes[prototype_name]
    if prototype and prototype.autoplace and not excluded[prototype_name] and not seen[prototype_name] then
        seen[prototype_name] = true
        table.insert(result, prototype_name)
    end
end

---Cached prototype group.
---@param kind string
---@param prototype_type string
---@param values EONPrototypeList
---@param extra_names? EONPrototypeList
---@param excluded_names? EONPrototypeSet
---@param predicate fun(name:string, prototype:table):boolean
local function cached_prototype_group(kind, prototype_type, values, extra_names, excluded_names, predicate)
    local key = prototype_cache_key(kind, prototype_type, values, extra_names, excluded_names)
    if prototype_cache[key] then
        return copy_values(prototype_cache[key])
    end

    local result = {}
    local seen = {}
    local excluded = excluded_names or {}

    for prototype_name, prototype in pairs(data.raw[prototype_type] or {}) do
        if prototype.autoplace and not excluded[prototype_name] and predicate(prototype_name, prototype) then
            seen[prototype_name] = true
            table.insert(result, prototype_name)
        end
    end

    for _, prototype_name in ipairs(extra_names or {}) do
        add_existing_autoplace_prototype(result, seen, prototype_type, prototype_name, excluded)
    end

    table.sort(result)
    prototype_cache[key] = copy_values(result)
    return result
end

---Hide an existing prototype.
---@param type string
---@param name string
function data_util.hide_prototype(type, name)
    if data.raw[type][name] then
        data.raw[type][name].hidden = true
    end
end

---Delete an existing prototype.
---@param type string
---@param name string
function data_util.delete_prototype(type, name)
    if data.raw[type][name] then
        data.raw[type][name] = nil
    end
end

---Return the EON noise-expression name for a prototype.
---@param name string
---@return string
function data_util.generate_eon_name(name)
    return "eon_" .. string.gsub(name, "-", "_")
end

---Check whether a tile participates in map generation.
---@param tile_name string
---@return boolean
function data_util.tile_has_autoplace(tile_name)
    return data.raw.tile and data.raw.tile[tile_name] and data.raw.tile[tile_name].autoplace ~= nil
end

---Collect generated tiles for one or more sprite usage surfaces.
---@param surface_names EONPrototypeList
---@param extra_names? EONPrototypeList
---@param excluded_names? EONPrototypeSet
---@return EONPrototypeList
function data_util.tiles_for_sprite_usage_surfaces(surface_names, extra_names, excluded_names)
    local key = cache_key(surface_names, extra_names, excluded_names)
    if tile_cache[key] then
        return copy_values(tile_cache[key])
    end

    local result = {}
    local seen = {}
    local excluded = excluded_names or {}

    for _, surface_name in ipairs(surface_names or {}) do
        for tile_name, tile in pairs(data.raw.tile or {}) do
            if tile.sprite_usage_surface == surface_name and tile.autoplace and not excluded[tile_name] and not seen[tile_name] then
                seen[tile_name] = true
                table.insert(result, tile_name)
            end
        end
    end

    for _, tile_name in ipairs(extra_names or {}) do
        if data_util.tile_has_autoplace(tile_name) and not seen[tile_name] and not excluded[tile_name] then
            seen[tile_name] = true
            table.insert(result, tile_name)
        end
    end

    table.sort(result)
    tile_cache[key] = copy_values(result)
    return result
end

---Collect generated tiles for one sprite usage surface.
---@param surface_name string
---@param extra_names? EONPrototypeList
---@param excluded_names? EONPrototypeSet
---@return EONPrototypeList
function data_util.tiles_for_sprite_usage_surface(surface_name, extra_names, excluded_names)
    return data_util.tiles_for_sprite_usage_surfaces({ surface_name }, extra_names, excluded_names)
end

---Collect generated Nauvis tiles.
---@param extra_names? EONPrototypeList
---@param excluded_names? EONPrototypeSet
---@return EONPrototypeList
function data_util.generated_nauvis_tiles(extra_names, excluded_names)
    local excluded = excluded_names or {}
    local key = cache_key({ "nauvis" }, extra_names, excluded)
    if tile_cache[key] then
        return copy_values(tile_cache[key])
    end

    local result = {}
    local seen = {}

    for tile_name, tile in pairs(data.raw.tile or {}) do
        if tile.autoplace and not tile.sprite_usage_surface and not excluded[tile_name] and not seen[tile_name] then
            seen[tile_name] = true
            table.insert(result, tile_name)
        end
    end

    for _, tile_name in ipairs(extra_names or {}) do
        if data_util.tile_has_autoplace(tile_name) and not seen[tile_name] and not excluded[tile_name] then
            seen[tile_name] = true
            table.insert(result, tile_name)
        end
    end

    table.sort(result)
    tile_cache[key] = copy_values(result)
    return result
end

---Apply a mask to generated prototypes.
---@param args { names: EONPrototypeList, prototype_type: string, mask: fun(name: string, prototype_type: string) }
function data_util.apply_mask_group(args)
    local prototype_type = args.prototype_type
    local prototype_names = args.names or {}
    local mask = args.mask
    local prototypes = data.raw[prototype_type]

    if not (prototypes and mask) then return end

    for _, prototype_name in ipairs(prototype_names) do
        local prototype = prototypes[prototype_name]
        if prototype and prototype.autoplace then
            mask(prototype_name, prototype_type)
        end
    end
end

---Build cached generated tile groups by surface.
---@return table<string, EONPrototypeList>
function data_util.generated_tiles_by_surface()
    return {
        nauvis = data_util.generated_nauvis_tiles(nil, {
            ["water"] = true,
            ["deepwater"] = true,
            ["empty-space"] = true,
            ["ammoniacal-ocean"] = true,
            ["ammoniacal-ocean-2"] = true,
        }),
        aquilo = data_util.tiles_for_sprite_usage_surface("aquilo"),
        fulgora = data_util.tiles_for_sprite_usage_surface("fulgora"),
        gleba = data_util.tiles_for_sprite_usage_surface("gleba"),
        vulcanus = data_util.tiles_for_sprite_usage_surface("vulcanus"),
    }
end

local eon_known_worldgen_planets = { "fulgora", "gleba", "vulcanus", "aquilo" }

local eon_known_worldgen_planet_names = {
    nauvis = true,
    fulgora = true,
    gleba = true,
    vulcanus = true,
    aquilo = true,
}

---Check whether a prototype belongs to a non-vanilla/modded planet.
---@param prototype table
---@return boolean
local function prototype_matches_modded_worldgen_planet(prototype)
    local simulation = prototype.factoriopedia_simulation
    if simulation and simulation.planet and not eon_known_worldgen_planet_names[simulation.planet] then
        return true
    end

    local expression = prototype.autoplace and prototype.autoplace.probability_expression
    if expression then
        expression = tostring(expression)
        for planet_name in pairs(data.raw.planet or {}) do
            if not eon_known_worldgen_planet_names[planet_name] then
                if string.find(expression, planet_name .. "_", 1, true) or string.find(expression, planet_name .. "-", 1, true) then
                    return true
                end
            end
        end
    end

    local restrictions = prototype.autoplace and prototype.autoplace.tile_restriction
    if restrictions then
        for _, tile_name in ipairs(restrictions) do
            local tile = data.raw.tile and data.raw.tile[tile_name]
            local surface_name = tile and tile.sprite_usage_surface
            if surface_name and not eon_known_worldgen_planet_names[surface_name] then
                return true
            end
        end
    end

    return false
end

---Collect generated prototypes whose autoplace expression contains keywords.
---@param prototype_type string
---@param keywords EONPrototypeList
---@param extra_names? EONPrototypeList
---@param excluded_names? EONPrototypeSet
---@return EONPrototypeList
function data_util.prototypes_for_autoplace_probability_keywords(prototype_type, keywords, extra_names, excluded_names)
    return cached_prototype_group("autoplace-probability-keyword", prototype_type, keywords, extra_names, excluded_names,
        function(_, prototype)
            if prototype_matches_modded_worldgen_planet(prototype) then return false end

            local expression = prototype.autoplace and prototype.autoplace.probability_expression
            if not expression then return false end
            expression = tostring(expression)
            for _, keyword in ipairs(keywords or {}) do
                if string.find(expression, keyword, 1, true) then
                    return true
                end
            end
            return false
        end)
end

---Prototype matches worldgen planet.
---@param prototype table
---@param planet_name string
local function prototype_matches_worldgen_planet(prototype, planet_name)
    if not prototype.autoplace then return false end

    local simulation = prototype.factoriopedia_simulation
    if simulation and simulation.planet == planet_name then
        return true
    end

    local expression = prototype.autoplace.probability_expression
    if expression then
        expression = tostring(expression)
        if string.find(expression, planet_name .. "_", 1, true) or string.find(expression, planet_name .. "-", 1, true) then
            return true
        end
    end

    local restrictions = prototype.autoplace.tile_restriction
    if restrictions then
        local planet_tiles = data_util.tiles_for_sprite_usage_surface(planet_name)
        local planet_tile_lookup = {}
        for _, tile_name in ipairs(planet_tiles) do
            planet_tile_lookup[tile_name] = true
        end
        for _, tile_name in ipairs(restrictions) do
            if planet_tile_lookup[tile_name] then
                return true
            end
        end
    end

    return false
end

---Collect generated prototypes associated with a planet.
---@param prototype_type string
---@param planet_name string
---@param extra_names? EONPrototypeList
---@param excluded_names? EONPrototypeSet
---@return EONPrototypeList
function data_util.prototypes_for_worldgen_planet(prototype_type, planet_name, extra_names, excluded_names)
    return cached_prototype_group("worldgen-planet", prototype_type, { planet_name }, extra_names, excluded_names,
        function(_, prototype)
            if prototype_matches_modded_worldgen_planet(prototype) then return false end
            return prototype_matches_worldgen_planet(prototype, planet_name)
        end)
end

---Collect generated prototypes not associated with Space Age planets.
---@param prototype_type string
---@param extra_names? EONPrototypeList
---@param excluded_names? EONPrototypeSet
---@return EONPrototypeList
function data_util.prototypes_for_nauvis_worldgen(prototype_type, extra_names, excluded_names)
    return cached_prototype_group("nauvis-worldgen", prototype_type, { "nauvis" }, extra_names, excluded_names,
        function(_, prototype)
            if not prototype.autoplace then return false end
            if prototype_matches_modded_worldgen_planet(prototype) then return false end

            for _, planet_name in ipairs(eon_known_worldgen_planets) do
                if prototype_matches_worldgen_planet(prototype, planet_name) then
                    return false
                end
            end

            return true
        end)
end

local generated_worldgen_cache

---Build cached generated prototype groups by surface.
---@return table<string, table<string, EONPrototypeList>>
function data_util.generated_worldgen_prototypes_by_surface()
    if generated_worldgen_cache then
        return generated_worldgen_cache
    end

    generated_worldgen_cache = {
        nauvis = {
            decoratives = data_util.prototypes_for_nauvis_worldgen("optimized-decorative"),
            entities = data_util.prototypes_for_nauvis_worldgen("simple-entity"),
            trees = data_util.prototypes_for_nauvis_worldgen("tree"),
            plants = data_util.prototypes_for_nauvis_worldgen("plant"),
        },
        aquilo = {
            decoratives = data_util.prototypes_for_autoplace_probability_keywords("optimized-decorative", { "aquilo_" }),
            entities = data_util.prototypes_for_autoplace_probability_keywords("simple-entity", { "aquilo_" }),
        },
        gleba = {
            decoratives = data_util.prototypes_for_autoplace_probability_keywords("optimized-decorative", { "gleba_" }),
            entities = data_util.prototypes_for_autoplace_probability_keywords("simple-entity", { "gleba_" }),
            trees = data_util.prototypes_for_worldgen_planet("tree", "gleba"),
            plants = data_util.prototypes_for_worldgen_planet("plant", "gleba"),
        },
        vulcanus = {
            decoratives = data_util.prototypes_for_autoplace_probability_keywords("optimized-decorative", { "vulcanus_" }),
            entities = data_util.prototypes_for_autoplace_probability_keywords("simple-entity", { "vulcanus_" }, nil, {
                ["small-demolisher-corpse"] = true,
                ["medium-demolisher-corpse"] = true,
                ["big-demolisher-corpse"] = true,
            }),
            trees = data_util.prototypes_for_worldgen_planet("tree", "vulcanus"),
        },
    }

    return generated_worldgen_cache
end

---Append values to a list.
---@param destination table
---@param values? table
function data_util.append(destination, values)
    for _, value in ipairs(values or {}) do
        table.insert(destination, value)
    end
end

return data_util
