local water = {}

water.group_order = {
    "nauvis_water",
    "vulcanus_lava",
    "aquilo_ocean",
    "fulgora_oil_ocean",
}

water.groups = {
    nauvis_water = {
        "water",
        "deepwater",
    },
    vulcanus_lava = {
        "lava",
        "lava-hot",
    },
    aquilo_ocean = {
        "ammoniacal-ocean",
        "ammoniacal-ocean-2",
        "brash-ice",
    },
    fulgora_oil_ocean = {
        "oil-ocean-shallow",
        "oil-ocean-deep",
    },
}

water.names = {}
water.set = {}
water.group_sets = {}

for _, group_name in ipairs(water.group_order) do
    local names = water.groups[group_name]
    local group_set = {}
    water.group_sets[group_name] = group_set

    for _, tile_name in ipairs(names) do
        water.names[#water.names + 1] = tile_name
        water.set[tile_name] = true
        group_set[tile_name] = true
    end
end

---@param tile_name string
---@return boolean
function water.is_water_tile(tile_name)
    return water.set[tile_name] == true
end

---@param group_name string
---@return string[]
function water.names_for_group(group_name)
    return water.groups[group_name] or {}
end

---@param group_name string
---@return table<string, boolean>
function water.set_for_group(group_name)
    return water.group_sets[group_name] or {}
end

---@param tile_names string[]
---@return string[]
function water.filter_land_tiles(tile_names)
    local result = {}
    for _, tile_name in ipairs(tile_names or {}) do
        if not water.is_water_tile(tile_name) then
            result[#result + 1] = tile_name
        end
    end
    return result
end

---@param tile_names string[]
---@return string[]
function water.filter_water_tiles(tile_names)
    local result = {}
    for _, tile_name in ipairs(tile_names or {}) do
        if water.is_water_tile(tile_name) then
            result[#result + 1] = tile_name
        end
    end
    return result
end

return water
