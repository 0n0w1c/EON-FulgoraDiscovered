
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
