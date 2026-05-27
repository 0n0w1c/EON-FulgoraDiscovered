---@param value any
---@return any
local function eon_copy_table(value)
    if type(value) ~= "table" then return value end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = entry
    end

    return copy
end

---@param tile_name string
---@param source_tile_name string
---@param fallback_rate number
---@return nil
local function eon_set_tile_absorption(tile_name, source_tile_name, fallback_rate)
    local tile = data.raw.tile and data.raw.tile[tile_name]
    if not tile then return end

    local source = data.raw.tile[source_tile_name]
    if source and source.absorptions_per_second then
        tile.absorptions_per_second = eon_copy_table(source.absorptions_per_second)
    else
        tile.absorptions_per_second = { pollution = fallback_rate }
    end

    if tile.absorptions_per_second then
        tile.absorptions_per_second.spores = nil
        if tile.absorptions_per_second.pollution == nil then
            tile.absorptions_per_second.pollution = fallback_rate
        end
    end
end

---@param tile_names string[]
---@param source_tile_name string
---@param fallback_rate number
---@return nil
local function eon_set_tile_group_absorption(tile_names, source_tile_name, fallback_rate)
    for _, tile_name in ipairs(tile_names) do
        eon_set_tile_absorption(tile_name, source_tile_name, fallback_rate)
    end
end

local eon_water_like_tiles = {
    "wetland-yumako",
    "wetland-jellynut",
    "wetland-blue-slime",
    "wetland-light-green-slime",
    "wetland-green-slime",
    "wetland-light-dead-skin",
    "wetland-dead-skin",
    "wetland-pink-tentacle",
    "wetland-red-tentacle",
    "lava",
    "oil-ocean-shallow",
    "brash-ice",
    "ammoniacal-ocean",
}

local eon_deepwater_like_tiles = {
    "gleba-deep-lake",
    "lava-hot",
    "oil-ocean-deep",
    "ammoniacal-ocean-2",
}

local eon_grass_like_tiles = {
    "natural-yumako-soil",
    "natural-jellynut-soil",
    "lowland-brown-blubber",
    "lowland-olive-blubber",
    "lowland-olive-blubber-2",
    "lowland-olive-blubber-3",
    "lowland-pale-green",
    "lowland-cream-cauliflower",
    "lowland-cream-cauliflower-2",
    "lowland-dead-skin",
    "lowland-dead-skin-2",
    "lowland-cream-red",
    "lowland-red-vein",
    "lowland-red-vein-2",
    "lowland-red-vein-3",
    "lowland-red-vein-4",
    "lowland-red-vein-dead",
    "lowland-red-infection",
    "midland-turquoise-bark",
    "midland-turquoise-bark-2",
    "midland-cracked-lichen",
    "midland-cracked-lichen-dull",
    "midland-cracked-lichen-dark",
    "midland-yellow-crust",
    "midland-yellow-crust-2",
    "midland-yellow-crust-3",
    "midland-yellow-crust-4",
    "highland-dark-rock",
    "highland-dark-rock-2",
    "highland-yellow-rock",
    "pit-rock",
}

local eon_sand_like_tiles = {
    "fulgoran-rock",
    "fulgoran-dust",
    "fulgoran-sand",
    "fulgoran-dunes",
    "fulgoran-walls",
    "fulgoran-paving",
    "fulgoran-conduit",
    "fulgoran-machinery",
    "volcanic-ash-flats",
    "volcanic-ash-light",
    "volcanic-ash-dark",
    "volcanic-cracks",
    "volcanic-cracks-warm",
    "volcanic-folds",
    "volcanic-folds-flat",
    "volcanic-folds-warm",
    "volcanic-pumice-stones",
    "volcanic-cracks-hot",
    "volcanic-jagged-ground",
    "volcanic-smooth-stone",
    "volcanic-smooth-stone-warm",
    "volcanic-ash-cracks",
    "snow-flat",
    "snow-crests",
    "snow-lumpy",
    "snow-patchy",
    "ice-rough",
    "ice-smooth",
}

eon_set_tile_group_absorption(eon_water_like_tiles, "water", 0.000005)
eon_set_tile_group_absorption(eon_deepwater_like_tiles, "deepwater", 0.000005)
eon_set_tile_group_absorption(eon_grass_like_tiles, "grass-1", 0.0000075)
eon_set_tile_group_absorption(eon_sand_like_tiles, "sand-1", 0.000005)

---@param table_value table
---@return nil
local function eon_move_spores_to_pollution(table_value)
    if type(table_value) ~= "table" or table_value.spores == nil then return end
    if table_value.pollution == nil then
        table_value.pollution = eon_copy_table(table_value.spores)
    end
    table_value.spores = nil
end

for _, tile in pairs(data.raw.tile or {}) do
    eon_move_spores_to_pollution(tile.absorptions_per_second)
end

---@param names string[]
---@return data.TreePrototype?
local function eon_first_existing_tree(names)
    for _, name in ipairs(names) do
        local tree = data.raw.tree and data.raw.tree[name]
        if tree then return tree end
    end

    return nil
end

---@param tree_name string
---@param source_tree any
---@return nil
local function eon_copy_tree_pollution_absorption(tree_name, source_tree)
    local tree = data.raw.tree and data.raw.tree[tree_name]
    if not tree then return end

    if source_tree and source_tree.emissions_per_second then
        tree.emissions_per_second = eon_copy_table(source_tree.emissions_per_second)
    end

    eon_move_spores_to_pollution(tree.emissions_per_second)
end

local eon_nauvis_tree = eon_first_existing_tree({
    "tree-01",
    "tree-02",
    "tree-03",
    "tree-04",
    "tree-05",
    "tree-06",
    "tree-07",
    "tree-08",
    "tree-09",
})

for _, tree_name in pairs({
    "cuttlepop",
    "slipstack",
    "funneltrunk",
    "hairyclubnub",
    "teflilly",
    "lickmaw",
    "stingfrond",
    "boompuff",
    "sunnycomb",
    "water-cane",
    "ashland-lichen-tree",
    "ashland-lichen-tree-flaming",
}) do
    eon_copy_tree_pollution_absorption(tree_name, eon_nauvis_tree)
end

local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value

---@param list table
---@param value string
---@return nil
local function eon_remove_value_from_list(list, value)
    if type(list) ~= "table" then return end
    for i = #list, 1, -1 do
        if list[i] == value then
            table.remove(list, i)
        end
    end
end

---@param transition table
---@return any
local function eon_transition_targets_out_of_map(transition)
    if type(transition) ~= "table" or type(transition.to_tiles) ~= "table" then return false end

    local has_out_of_map = false
    local has_empty_space = false
    for _, to_tile in pairs(transition.to_tiles) do
        if to_tile == "out-of-map" then has_out_of_map = true end
        if to_tile == "empty-space" then has_empty_space = true end
    end

    return has_out_of_map and has_empty_space
end

---@param tile_name string
---@return nil
local function eon_remove_oil_ocean_from_out_of_map_transition(tile_name)
    local tile = data.raw.tile and data.raw.tile[tile_name]
    if not tile or type(tile.transitions) ~= "table" then return end

    for _, transition in pairs(tile.transitions) do
        if transition.transition_group == 2 and eon_transition_targets_out_of_map(transition) then
            eon_remove_value_from_list(transition.to_tiles, "oil-ocean-shallow")
        end
    end
end

if eon_aquilo_on_fulgora then
    for _, tile_name in pairs({
        "snow-flat",
        "snow-crests",
        "snow-lumpy",
        "snow-patchy",
        "ice-rough",
        "ice-smooth",
        "brash-ice",
    }) do
        eon_remove_oil_ocean_from_out_of_map_transition(tile_name)
    end
end

---@return nil
local function eon_copy_lava_transition_masks_to_lava_hot()
    local lava = data.raw.tile and data.raw.tile["lava"]
    local lava_hot = data.raw.tile and data.raw.tile["lava-hot"]
    if not lava or not lava_hot then return end
    if type(lava.variants) ~= "table" or type(lava.variants.transition) ~= "table" then return end

    if type(lava_hot.variants) ~= "table" then
        lava_hot.variants = {}
    end

    lava_hot.variants.empty_transitions = nil
    lava_hot.variants.transition = table.deepcopy(lava.variants.transition)
end

if eon_aquilo_on_fulgora then
    eon_copy_lava_transition_masks_to_lava_hot()
end

---@param list table
---@param value string
---@return any
local function eon_list_contains(list, value)
    if type(list) ~= "table" then return false end
    for _, item in pairs(list) do
        if item == value then return true end
    end
    return false
end

---@param transition table
---@param tile_names table
---@return any
local function eon_transition_targets_any(transition, tile_names)
    if type(transition) ~= "table" or type(transition.to_tiles) ~= "table" then return false end

    for _, tile_name in ipairs(tile_names) do
        if eon_list_contains(transition.to_tiles, tile_name) then
            return true
        end
    end

    return false
end

---@param transition table
---@return any
local function eon_transition_signature(transition)
    if type(transition) ~= "table" or type(transition.to_tiles) ~= "table" then return nil end

    local names = {}
    for _, tile_name in pairs(transition.to_tiles) do
        names[#names + 1] = tile_name
    end
    table.sort(names)

    return tostring(transition.transition_group or "") .. ":" .. table.concat(names, ",")
end

---@return nil
local function eon_copy_lava_water_transition_style_to_lava_hot_cracks()
    local lava = data.raw.tile and data.raw.tile["lava"]
    local lava_hot = data.raw.tile and data.raw.tile["lava-hot"]
    if not lava or not lava_hot or type(lava.transitions) ~= "table" then return end

    local water_tiles = { "water", "deepwater" }
    local crack_tiles = { "volcanic-cracks-hot", "volcanic-cracks-warm" }

    if type(lava_hot.transitions) ~= "table" then
        lava_hot.transitions = {}
    end

    local existing = {}
    for _, transition in pairs(lava_hot.transitions) do
        local signature = eon_transition_signature(transition)
        if signature then
            existing[signature] = true
        end
    end

    for _, transition in pairs(lava.transitions) do
        if eon_transition_targets_any(transition, water_tiles) then
            local copied_transition = table.deepcopy(transition)
            copied_transition.to_tiles = table.deepcopy(crack_tiles)

            local signature = eon_transition_signature(copied_transition)
            if signature and not existing[signature] then
                lava_hot.transitions[#lava_hot.transitions + 1] = copied_transition
                existing[signature] = true
            end
        end
    end

    if type(lava_hot.allowed_neighbors) == "table" then
        for _, tile_name in pairs(crack_tiles) do
            if data.raw.tile[tile_name] and not eon_list_contains(lava_hot.allowed_neighbors, tile_name) then
                lava_hot.allowed_neighbors[#lava_hot.allowed_neighbors + 1] = tile_name
            end
        end
    end
end

if eon_aquilo_on_fulgora then
    eon_copy_lava_water_transition_style_to_lava_hot_cracks()
end
