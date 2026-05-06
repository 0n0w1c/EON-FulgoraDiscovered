
data.raw.tile["natural-yumako-soil"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["natural-jellynut-soil"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-brown-blubber"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-olive-blubber"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-olive-blubber-2"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-olive-blubber-3"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-pale-green"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-cream-cauliflower"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-cream-cauliflower-2"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-dead-skin"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-dead-skin-2"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-cream-red"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["lowland-red-vein"].absorptions_per_second = {pollution = 0.00003}
data.raw.tile["lowland-red-vein-2"].absorptions_per_second = {pollution = 0.00003}
data.raw.tile["lowland-red-vein-3"].absorptions_per_second = {pollution = 0.00003}
data.raw.tile["lowland-red-vein-4"].absorptions_per_second = {pollution = 0.00003}
data.raw.tile["lowland-red-vein-dead"].absorptions_per_second = {pollution = 0.00003}
data.raw.tile["lowland-red-infection"].absorptions_per_second = {pollution = 0.00003}
data.raw.tile["midland-turquoise-bark"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["midland-turquoise-bark-2"].absorptions_per_second = {pollution = 0.00004}
data.raw.tile["midland-cracked-lichen"].absorptions_per_second = {pollution = 0.00002}
data.raw.tile["midland-cracked-lichen-dull"].absorptions_per_second = {pollution = 0.00002}
data.raw.tile["midland-cracked-lichen-dark"].absorptions_per_second = {pollution = 0.00002}
data.raw.tile["midland-yellow-crust"].absorptions_per_second = {pollution = 0.000025}
data.raw.tile["midland-yellow-crust-2"].absorptions_per_second = {pollution = 0.000025}
data.raw.tile["midland-yellow-crust-3"].absorptions_per_second = {pollution = 0.000025}
data.raw.tile["midland-yellow-crust-4"].absorptions_per_second = {pollution = 0.000025}
data.raw.tile["highland-dark-rock"].absorptions_per_second = {pollution = 0.00002}
data.raw.tile["highland-dark-rock-2"].absorptions_per_second = {pollution = 0.00002}
data.raw.tile["highland-yellow-rock"].absorptions_per_second = {pollution = 0.00002}
data.raw.tile["pit-rock"].absorptions_per_second = {pollution = 0.000015}

-- When the Aquilo biome is moved to Fulgora, the Aquilo snow/ice tiles can border
-- Fulgora oil-ocean-shallow tiles. These tiles already have the correct water/ocean
-- transition in the regular water transition group. However, some copied tile
-- definitions also include oil-ocean-shallow in the out-of-map transition group,
-- which makes the boundary render as a void edge. Remove only that invalid target.
local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value

local function eon_remove_value_from_list(list, value)
    if type(list) ~= "table" then return end
    for i = #list, 1, -1 do
        if list[i] == value then
            table.remove(list, i)
        end
    end
end

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


-- When Vulcanus terrain is generated on Nauvis/Fulgora-adjacent water, lava-hot
-- should use the same transition mask graphics as regular lava. In base Space Age,
-- lava-hot has variants.empty_transitions = true, so it renders without those masks.
-- Copy only the tile variant transition mask definition from lava; do not modify
-- autoplace, collision, effects, sounds, runtime code, or unrelated transitions.
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

-- Keep lava-hot adjacency transitions visualized through Vulcanus crack tiles.
-- The variant transition mask above handles the lava-hot edge graphics. These extra
-- transition entries deliberately target volcanic-cracks-hot/warm, not Nauvis water
-- or deepwater, so the intermediate visual tile remains Vulcanus-themed.
local function eon_list_contains(list, value)
    if type(list) ~= "table" then return false end
    for _, item in pairs(list) do
        if item == value then return true end
    end
    return false
end

local function eon_transition_targets_any(transition, tile_names)
    if type(transition) ~= "table" or type(transition.to_tiles) ~= "table" then return false end

    for _, tile_name in pairs(tile_names) do
        if eon_list_contains(transition.to_tiles, tile_name) then
            return true
        end
    end

    return false
end

local function eon_transition_signature(transition)
    if type(transition) ~= "table" or type(transition.to_tiles) ~= "table" then return nil end

    local names = {}
    for _, tile_name in pairs(transition.to_tiles) do
        names[#names + 1] = tile_name
    end
    table.sort(names)

    return tostring(transition.transition_group or "") .. ":" .. table.concat(names, ",")
end

local function eon_copy_lava_water_transition_style_to_lava_hot_cracks()
    local lava = data.raw.tile and data.raw.tile["lava"]
    local lava_hot = data.raw.tile and data.raw.tile["lava-hot"]
    if not lava or not lava_hot or type(lava.transitions) ~= "table" then return end

    local water_tiles = {"water", "deepwater"}
    local crack_tiles = {"volcanic-cracks-hot", "volcanic-cracks-warm"}

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


-- Do not add direct visual transitions between Fulgora oil ocean and Aquilo ocean
-- tiles here. Those transitions make oil-ocean-shallow/oil-ocean-deep render as a
-- brown shore around brash-ice/ammoniacal-ocean. The desired separation is handled
-- in map-generation/terrain.lua by preventing Fulgora oil ocean tiles from spawning
-- in the Aquilo ocean edge band and letting ice-smooth occupy that band.

