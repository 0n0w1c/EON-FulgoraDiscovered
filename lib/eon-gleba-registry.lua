local gleba = {}

local function make_set(names)
    local set = {}
    for _, name in ipairs(names) do
        set[name] = true
    end
    return set
end

gleba.autoplace_controls = {
    "gleba_plants",
    "gleba_water",
}

gleba.tiles = {
    "natural-yumako-soil",
    "natural-jellynut-soil",
    "wetland-yumako",
    "wetland-jellynut",
    "wetland-light-green-slime",
    "wetland-green-slime",
    "wetland-light-dead-skin",
    "wetland-dead-skin",
    "wetland-pink-tentacle",
    "wetland-red-tentacle",
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

gleba.decoratives = {
    "yellow-lettuce-lichen-1x1",
    "yellow-lettuce-lichen-3x3",
    "yellow-lettuce-lichen-6x6",
    "yellow-lettuce-lichen-cups-1x1",
    "yellow-lettuce-lichen-cups-3x3",
    "yellow-lettuce-lichen-cups-6x6",
    "green-lettuce-lichen-1x1",
    "green-lettuce-lichen-3x3",
    "green-lettuce-lichen-6x6",
    "green-lettuce-lichen-water-1x1",
    "green-lettuce-lichen-water-3x3",
    "green-lettuce-lichen-water-6x6",
    "split-gill-1x1",
    "split-gill-2x2",
    "split-gill-dying-1x1",
    "split-gill-dying-2x2",
    "split-gill-red-1x1",
    "split-gill-red-2x2",
    "veins",
    "veins-small",
    "mycelium",
    "coral-water",
    "coral-land",
    "black-sceptre",
    "pink-phalanges",
    "pink-lichen-decal",
    "red-lichen-decal",
    "green-cup",
    "brown-cup",
    "blood-grape",
    "blood-grape-vibrant",
    "brambles",
    "polycephalum-slime",
    "polycephalum-balloon",
    "fuchsia-pita",
    "wispy-lichen",
    "grey-cracked-mud-decal",
    "barnacles-decal",
    "coral-stunted",
    "coral-stunted-grey",
    "nerve-roots-dense",
    "nerve-roots-sparse",
    "yellow-coral",
    "solo-barnacle",
    "curly-roots-orange",
    "knobbly-roots",
    "knobbly-roots-orange",
    "matches-small",
    "pale-lettuce-lichen-cups-1x1",
    "pale-lettuce-lichen-cups-3x3",
    "pale-lettuce-lichen-cups-6x6",
    "pale-lettuce-lichen-1x1",
    "pale-lettuce-lichen-3x3",
    "pale-lettuce-lichen-6x6",
    "pale-lettuce-lichen-water-1x1",
    "pale-lettuce-lichen-water-3x3",
    "pale-lettuce-lichen-water-6x6",
    "white-carpet-grass",
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
    "honeycomb-fungus",
    "honeycomb-fungus-1x1",
    "honeycomb-fungus-decayed",
}

gleba.entities = {
    "iron-stromatolite",
    "copper-stromatolite",
}

gleba.trees = {
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
}

gleba.masked_tiles = {
    "natural-yumako-soil",
    "natural-jellynut-soil",
    "wetland-yumako",
    "wetland-jellynut",
    "wetland-blue-slime",
    "wetland-light-green-slime",
    "wetland-green-slime",
    "wetland-light-dead-skin",
    "wetland-dead-skin",
    "wetland-pink-tentacle",
    "wetland-red-tentacle",
    "gleba-deep-lake",
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

gleba.tile_set = make_set(gleba.tiles)
gleba.decorative_set = make_set(gleba.decoratives)
gleba.entity_set = make_set(gleba.entities)
gleba.tree_set = make_set(gleba.trees)
gleba.masked_tile_set = make_set(gleba.masked_tiles)

gleba.territory_mask_autoplace_by_type = {
    ["optimized-decorative"] = gleba.decoratives,
    ["simple-entity"] = gleba.entities,
    tile = gleba.masked_tiles,
    tree = gleba.trees,
}

gleba.agriculture_probability_expressions = {
    ["wetland-jellynut"] = "eon_jellynut_spots",
    ["wetland-yumako"] = "eon_yumako_spots",
    ["natural-jellynut-soil"] = "eon_jellynut_soil",
    ["natural-yumako-soil"] = "eon_yumako_soil",
}

function gleba.register_on_nauvis()
    local settings = data.raw.planet["nauvis"].map_gen_settings
    if not settings then return end

    for _, control_name in pairs(gleba.autoplace_controls) do
        settings.autoplace_controls[control_name] = {}
    end

    for _, tile_name in pairs(gleba.tiles) do
        settings.autoplace_settings.tile.settings[tile_name] = {}
    end

    for _, decorative_name in pairs(gleba.decoratives) do
        settings.autoplace_settings.decorative.settings[decorative_name] = {}
    end

    for _, entity_name in pairs(gleba.entities) do
        settings.autoplace_settings.entity.settings[entity_name] = {}
    end
end

function gleba.apply_agriculture_probability_expressions()
    for tile_name, expression_name in pairs(gleba.agriculture_probability_expressions) do
        if data.raw.tile[tile_name] and data.raw.tile[tile_name].autoplace then
            data.raw.tile[tile_name].autoplace.probability_expression = expression_name
        end
    end
end

return gleba
