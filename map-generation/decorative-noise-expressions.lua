local data_util = require("data-util")

---Duplicate noise expression.
---@param name string
---@param type string
local function duplicate_noise_expression(name, type)
    local expression = {
        type = "noise-expression",
        name = data_util.generate_eon_name(name),
        expression = data.raw[type][name].autoplace.probability_expression
    }
    if data.raw[type][name].autoplace.local_expressions then
        expression.local_expressions = data.raw[type][name].autoplace.local_expressions
    end
    return expression
end

---Append prototype noise expressions.
---@param destination any
---@param prototype_type string
---@param prototype_names? string[]
local function append_prototype_noise_expressions(destination, prototype_type, prototype_names)
    local existing = {}
    for _, expression in pairs(destination or {}) do
        if expression and expression.name then
            existing[expression.name] = true
        end
    end

    for _, prototype_name in pairs(prototype_names or {}) do
        local prototype = data.raw[prototype_type] and data.raw[prototype_type][prototype_name]
        local eon_name = data_util.generate_eon_name(prototype_name)
        if prototype and prototype.autoplace and prototype.autoplace.probability_expression ~= nil and not existing[eon_name] then
            data_util.append(destination, { duplicate_noise_expression(prototype_name, prototype_type) })
            existing[eon_name] = true
        end
    end
end

---Append tile noise expressions for surface.
---@param destination any
---@param surface_name string
---@param excluded_names? string[]
local function append_tile_noise_expressions_for_surface(destination, surface_name, excluded_names)
    for _, tile_name in pairs(data_util.tiles_for_sprite_usage_surface(surface_name, nil, excluded_names)) do
        local tile = data.raw.tile and data.raw.tile[tile_name]
        if tile and tile.autoplace and tile.autoplace.probability_expression then
            data_util.append(destination, { duplicate_noise_expression(tile_name, "tile") })
        end
    end
end

---Duplicate noise function.
---@param name string
local function duplicate_noise_function(name)
    local expression = table.deepcopy(data.raw["noise-function"][name])
    expression.name = data_util.generate_eon_name(name)
    return expression
end

local eon_noise_expressions = {
    duplicate_noise_expression("iron-ore", "resource"),
    duplicate_noise_expression("copper-ore", "resource"),
    duplicate_noise_expression("stone", "resource"),
    duplicate_noise_expression("coal", "resource"),
    duplicate_noise_expression("uranium-ore", "resource"),
    duplicate_noise_expression("crude-oil", "resource"),

    duplicate_noise_expression("grass-1", "tile"),
    duplicate_noise_expression("grass-2", "tile"),
    duplicate_noise_expression("grass-3", "tile"),
    duplicate_noise_expression("grass-4", "tile"),
    duplicate_noise_expression("dry-dirt", "tile"),
    duplicate_noise_expression("dirt-1", "tile"),
    duplicate_noise_expression("dirt-2", "tile"),
    duplicate_noise_expression("dirt-3", "tile"),
    duplicate_noise_expression("dirt-4", "tile"),
    duplicate_noise_expression("dirt-5", "tile"),
    duplicate_noise_expression("dirt-6", "tile"),
    duplicate_noise_expression("dirt-7", "tile"),
    duplicate_noise_expression("sand-1", "tile"),
    duplicate_noise_expression("sand-2", "tile"),
    duplicate_noise_expression("sand-3", "tile"),
    duplicate_noise_expression("red-desert-0", "tile"),
    duplicate_noise_expression("red-desert-1", "tile"),
    duplicate_noise_expression("red-desert-2", "tile"),
    duplicate_noise_expression("red-desert-3", "tile"),
    duplicate_noise_expression("water", "tile"),
    duplicate_noise_expression("deepwater", "tile"),

    duplicate_noise_expression("big-rock", "simple-entity"),
    duplicate_noise_expression("big-sand-rock", "simple-entity"),
    duplicate_noise_expression("brown-asterisk", "optimized-decorative"),
    duplicate_noise_expression("brown-asterisk-mini", "optimized-decorative"),
    duplicate_noise_expression("brown-carpet-grass", "optimized-decorative"),
    duplicate_noise_expression("brown-fluff", "optimized-decorative"),
    duplicate_noise_expression("brown-fluff-dry", "optimized-decorative"),
    duplicate_noise_expression("brown-hairy-grass", "optimized-decorative"),
    duplicate_noise_expression("cracked-mud-decal", "optimized-decorative"),
    duplicate_noise_expression("dark-mud-decal", "optimized-decorative"),
    duplicate_noise_expression("garballo", "optimized-decorative"),
    duplicate_noise_expression("garballo-mini-dry", "optimized-decorative"),
    duplicate_noise_expression("green-asterisk", "optimized-decorative"),
    duplicate_noise_expression("green-asterisk-mini", "optimized-decorative"),
    duplicate_noise_expression("green-bush-mini", "optimized-decorative"),
    duplicate_noise_expression("green-carpet-grass", "optimized-decorative"),
    duplicate_noise_expression("green-croton", "optimized-decorative"),
    duplicate_noise_expression("green-desert-bush", "optimized-decorative"),
    duplicate_noise_expression("green-hairy-grass", "optimized-decorative"),
    duplicate_noise_expression("green-pita", "optimized-decorative"),
    duplicate_noise_expression("green-pita-mini", "optimized-decorative"),
    duplicate_noise_expression("green-small-grass", "optimized-decorative"),
    duplicate_noise_expression("huge-rock", "simple-entity"),
    duplicate_noise_expression("lichen-decal", "optimized-decorative"),
    duplicate_noise_expression("light-mud-decal", "optimized-decorative"),
    duplicate_noise_expression("medium-rock", "optimized-decorative"),
    duplicate_noise_expression("medium-sand-rock", "optimized-decorative"),
    duplicate_noise_expression("red-asterisk", "optimized-decorative"),
    duplicate_noise_expression("red-croton", "optimized-decorative"),
    duplicate_noise_expression("red-desert-bush", "optimized-decorative"),
    duplicate_noise_expression("red-desert-decal", "optimized-decorative"),
    duplicate_noise_expression("red-pita", "optimized-decorative"),
    duplicate_noise_expression("sand-decal", "optimized-decorative"),
    duplicate_noise_expression("sand-dune-decal", "optimized-decorative"),
    duplicate_noise_expression("shroom-decal", "optimized-decorative"),
    duplicate_noise_expression("small-rock", "optimized-decorative"),
    duplicate_noise_expression("small-sand-rock", "optimized-decorative"),
    duplicate_noise_expression("tiny-rock", "optimized-decorative"),
    duplicate_noise_expression("white-desert-bush", "optimized-decorative"),

    duplicate_noise_expression("lithium-iceberg-medium", "optimized-decorative"),
    duplicate_noise_expression("lithium-iceberg-small", "optimized-decorative"),
    duplicate_noise_expression("lithium-iceberg-tiny", "optimized-decorative"),
    duplicate_noise_expression("floating-iceberg-large", "optimized-decorative"),
    duplicate_noise_expression("floating-iceberg-small", "optimized-decorative"),
    duplicate_noise_expression("aqulio-ice-decal-blue", "optimized-decorative"),
    duplicate_noise_expression("aqulio-snowy-decal", "optimized-decorative"),
    duplicate_noise_expression("snow-drift-decal", "optimized-decorative"),

    duplicate_noise_expression("lithium-brine", "resource"),
    duplicate_noise_expression("fluorine-vent", "resource"),
    duplicate_noise_expression("lithium-iceberg-huge", "simple-entity"),
    duplicate_noise_expression("lithium-iceberg-big", "simple-entity"),

    duplicate_noise_expression("yellow-lettuce-lichen-1x1", "optimized-decorative"),
    duplicate_noise_expression("yellow-lettuce-lichen-3x3", "optimized-decorative"),
    duplicate_noise_expression("yellow-lettuce-lichen-6x6", "optimized-decorative"),
    duplicate_noise_expression("yellow-lettuce-lichen-cups-1x1", "optimized-decorative"),
    duplicate_noise_expression("yellow-lettuce-lichen-cups-3x3", "optimized-decorative"),
    duplicate_noise_expression("yellow-lettuce-lichen-cups-6x6", "optimized-decorative"),
    duplicate_noise_expression("green-lettuce-lichen-1x1", "optimized-decorative"),
    duplicate_noise_expression("green-lettuce-lichen-3x3", "optimized-decorative"),
    duplicate_noise_expression("green-lettuce-lichen-6x6", "optimized-decorative"),
    duplicate_noise_expression("green-lettuce-lichen-water-1x1", "optimized-decorative"),
    duplicate_noise_expression("green-lettuce-lichen-water-3x3", "optimized-decorative"),
    duplicate_noise_expression("green-lettuce-lichen-water-6x6", "optimized-decorative"),
    duplicate_noise_expression("split-gill-1x1", "optimized-decorative"),
    duplicate_noise_expression("split-gill-2x2", "optimized-decorative"),
    duplicate_noise_expression("split-gill-dying-1x1", "optimized-decorative"),
    duplicate_noise_expression("split-gill-dying-2x2", "optimized-decorative"),
    duplicate_noise_expression("split-gill-red-1x1", "optimized-decorative"),
    duplicate_noise_expression("split-gill-red-2x2", "optimized-decorative"),
    duplicate_noise_expression("veins", "optimized-decorative"),
    duplicate_noise_expression("veins-small", "optimized-decorative"),
    duplicate_noise_expression("mycelium", "optimized-decorative"),
    duplicate_noise_expression("coral-water", "optimized-decorative"),
    duplicate_noise_expression("coral-land", "optimized-decorative"),
    duplicate_noise_expression("black-sceptre", "optimized-decorative"),
    duplicate_noise_expression("pink-phalanges", "optimized-decorative"),
    duplicate_noise_expression("pink-lichen-decal", "optimized-decorative"),
    duplicate_noise_expression("red-lichen-decal", "optimized-decorative"),
    duplicate_noise_expression("green-cup", "optimized-decorative"),
    duplicate_noise_expression("brown-cup", "optimized-decorative"),
    duplicate_noise_expression("blood-grape", "optimized-decorative"),
    duplicate_noise_expression("blood-grape-vibrant", "optimized-decorative"),
    duplicate_noise_expression("brambles", "optimized-decorative"),
    duplicate_noise_expression("polycephalum-slime", "optimized-decorative"),
    duplicate_noise_expression("polycephalum-balloon", "optimized-decorative"),
    duplicate_noise_expression("fuchsia-pita", "optimized-decorative"),
    duplicate_noise_expression("wispy-lichen", "optimized-decorative"),
    duplicate_noise_expression("grey-cracked-mud-decal", "optimized-decorative"),
    duplicate_noise_expression("barnacles-decal", "optimized-decorative"),
    duplicate_noise_expression("coral-stunted", "optimized-decorative"),
    duplicate_noise_expression("coral-stunted-grey", "optimized-decorative"),
    duplicate_noise_expression("nerve-roots-dense", "optimized-decorative"),
    duplicate_noise_expression("nerve-roots-sparse", "optimized-decorative"),
    duplicate_noise_expression("yellow-coral", "optimized-decorative"),
    duplicate_noise_expression("solo-barnacle", "optimized-decorative"),
    duplicate_noise_expression("curly-roots-orange", "optimized-decorative"),
    duplicate_noise_expression("knobbly-roots", "optimized-decorative"),
    duplicate_noise_expression("knobbly-roots-orange", "optimized-decorative"),
    duplicate_noise_expression("matches-small", "optimized-decorative"),
    duplicate_noise_expression("pale-lettuce-lichen-cups-1x1", "optimized-decorative"),
    duplicate_noise_expression("pale-lettuce-lichen-cups-3x3", "optimized-decorative"),
    duplicate_noise_expression("pale-lettuce-lichen-cups-6x6", "optimized-decorative"),
    duplicate_noise_expression("pale-lettuce-lichen-1x1", "optimized-decorative"),
    duplicate_noise_expression("pale-lettuce-lichen-3x3", "optimized-decorative"),
    duplicate_noise_expression("pale-lettuce-lichen-6x6", "optimized-decorative"),
    duplicate_noise_expression("pale-lettuce-lichen-water-1x1", "optimized-decorative"),
    duplicate_noise_expression("pale-lettuce-lichen-water-3x3", "optimized-decorative"),
    duplicate_noise_expression("pale-lettuce-lichen-water-6x6", "optimized-decorative"),
    duplicate_noise_expression("white-carpet-grass", "optimized-decorative"),
    duplicate_noise_expression("green-carpet-grass", "optimized-decorative"),
    duplicate_noise_expression("green-hairy-grass", "optimized-decorative"),
    duplicate_noise_expression("light-mud-decal", "optimized-decorative"),
    duplicate_noise_expression("dark-mud-decal", "optimized-decorative"),
    duplicate_noise_expression("cracked-mud-decal", "optimized-decorative"),
    duplicate_noise_expression("red-desert-bush", "optimized-decorative"),
    duplicate_noise_expression("white-desert-bush", "optimized-decorative"),
    duplicate_noise_expression("red-pita", "optimized-decorative"),
    duplicate_noise_expression("green-bush-mini", "optimized-decorative"),
    duplicate_noise_expression("green-croton", "optimized-decorative"),
    duplicate_noise_expression("green-pita", "optimized-decorative"),
    duplicate_noise_expression("green-pita-mini", "optimized-decorative"),
    duplicate_noise_expression("lichen-decal", "optimized-decorative"),
    duplicate_noise_expression("shroom-decal", "optimized-decorative"),

    duplicate_noise_expression("iron-stromatolite", "simple-entity"),
    duplicate_noise_expression("copper-stromatolite", "simple-entity"),

    duplicate_noise_expression("cuttlepop", "tree"),
    duplicate_noise_expression("slipstack", "tree"),
    duplicate_noise_expression("funneltrunk", "tree"),
    duplicate_noise_expression("hairyclubnub", "tree"),
    duplicate_noise_expression("teflilly", "tree"),
    duplicate_noise_expression("lickmaw", "tree"),
    duplicate_noise_expression("stingfrond", "tree"),
    duplicate_noise_expression("boompuff", "tree"),
    duplicate_noise_expression("sunnycomb", "tree"),
    duplicate_noise_expression("water-cane", "tree"),

    duplicate_noise_expression("vulcanus-chimney", "simple-entity"),
    duplicate_noise_expression("vulcanus-chimney-faded", "simple-entity"),
    duplicate_noise_expression("vulcanus-chimney-cold", "simple-entity"),
    duplicate_noise_expression("vulcanus-chimney-short", "simple-entity"),
    duplicate_noise_expression("vulcanus-chimney-truncated", "simple-entity"),
    duplicate_noise_expression("huge-volcanic-rock", "simple-entity"),
    duplicate_noise_expression("big-volcanic-rock", "simple-entity"),
    duplicate_noise_expression("ashland-lichen-tree", "tree"),
    duplicate_noise_expression("ashland-lichen-tree-flaming", "tree"),
    duplicate_noise_expression("v-brown-carpet-grass", "optimized-decorative"),
    duplicate_noise_expression("v-green-hairy-grass", "optimized-decorative"),
    duplicate_noise_expression("v-brown-hairy-grass", "optimized-decorative"),
    duplicate_noise_expression("v-red-pita", "optimized-decorative"),
    duplicate_noise_expression("vulcanus-rock-decal-large", "optimized-decorative"),
    duplicate_noise_expression("vulcanus-crack-decal", "optimized-decorative"),
    duplicate_noise_expression("vulcanus-crack-decal-large", "optimized-decorative"),
    duplicate_noise_expression("vulcanus-crack-decal-huge-warm", "optimized-decorative"),
    duplicate_noise_expression("vulcanus-crack-decal-warm", "optimized-decorative"),
    duplicate_noise_expression("calcite-stain", "optimized-decorative"),
    duplicate_noise_expression("calcite-stain-small", "optimized-decorative"),
    duplicate_noise_expression("sulfur-stain", "optimized-decorative"),
    duplicate_noise_expression("sulfur-stain-small", "optimized-decorative"),
    duplicate_noise_expression("sulfuric-acid-puddle", "optimized-decorative"),
    duplicate_noise_expression("sulfuric-acid-puddle-small", "optimized-decorative"),
    duplicate_noise_expression("crater-small", "optimized-decorative"),
    duplicate_noise_expression("crater-large", "optimized-decorative"),
    duplicate_noise_expression("pumice-relief-decal", "optimized-decorative"),
    duplicate_noise_expression("vulcanus-sand-decal", "optimized-decorative"),
    duplicate_noise_expression("vulcanus-dune-decal", "optimized-decorative"),
    duplicate_noise_expression("waves-decal", "optimized-decorative"),
    duplicate_noise_expression("medium-volcanic-rock", "optimized-decorative"),
    duplicate_noise_expression("small-volcanic-rock", "optimized-decorative"),
    duplicate_noise_expression("tiny-volcanic-rock", "optimized-decorative"),
    duplicate_noise_expression("tiny-rock-cluster", "optimized-decorative"),
    duplicate_noise_expression("small-sulfur-rock", "optimized-decorative"),
    duplicate_noise_expression("tiny-sulfur-rock", "optimized-decorative"),
    duplicate_noise_expression("sulfur-rock-cluster", "optimized-decorative"),
    duplicate_noise_expression("vulcanus-lava-fire", "optimized-decorative"),

    duplicate_noise_expression("calcite", "resource"),
    duplicate_noise_expression("tungsten-ore", "resource"),

    duplicate_noise_function("water_base")
}

append_tile_noise_expressions_for_surface(eon_noise_expressions, "aquilo", {
    ["frozen-concrete"] = true,
    ["frozen-hazard-concrete-left"] = true,
    ["frozen-hazard-concrete-right"] = true,
    ["frozen-refined-concrete"] = true,
    ["frozen-refined-hazard-concrete-left"] = true,
    ["frozen-refined-hazard-concrete-right"] = true,
    ["frozen-stone-path"] = true,
    ["ice-platform"] = true,
})
append_tile_noise_expressions_for_surface(eon_noise_expressions, "gleba")
append_tile_noise_expressions_for_surface(eon_noise_expressions, "vulcanus", {
    ["volcanic-soil-dark"] = true,
    ["volcanic-soil-light"] = true,
    ["volcanic-ash-soil"] = true,
    ["volcanic-folds"] = true,
    ["volcanic-folds-flat"] = true,
    ["lava"] = true,
    ["lava-hot"] = true,
})

local eon_generated_tiles = data_util.generated_tiles_by_surface()
local eon_generated_worldgen = data_util.generated_worldgen_prototypes_by_surface()

append_prototype_noise_expressions(eon_noise_expressions, "tile", eon_generated_tiles.nauvis)

append_prototype_noise_expressions(eon_noise_expressions, "optimized-decorative",
    eon_generated_worldgen.nauvis.decoratives)
append_prototype_noise_expressions(eon_noise_expressions, "simple-entity", eon_generated_worldgen.nauvis.entities)
append_prototype_noise_expressions(eon_noise_expressions, "tree", eon_generated_worldgen.nauvis.trees)
append_prototype_noise_expressions(eon_noise_expressions, "plant", eon_generated_worldgen.nauvis.plants)

append_prototype_noise_expressions(eon_noise_expressions, "optimized-decorative",
    eon_generated_worldgen.aquilo.decoratives)
append_prototype_noise_expressions(eon_noise_expressions, "simple-entity", eon_generated_worldgen.aquilo.entities)

append_prototype_noise_expressions(eon_noise_expressions, "optimized-decorative",
    eon_generated_worldgen.gleba.decoratives)
append_prototype_noise_expressions(eon_noise_expressions, "simple-entity", eon_generated_worldgen.gleba.entities)
append_prototype_noise_expressions(eon_noise_expressions, "tree", eon_generated_worldgen.gleba.trees)
append_prototype_noise_expressions(eon_noise_expressions, "plant", eon_generated_worldgen.gleba.plants)

append_prototype_noise_expressions(eon_noise_expressions, "optimized-decorative",
    eon_generated_worldgen.vulcanus.decoratives)
append_prototype_noise_expressions(eon_noise_expressions, "simple-entity", eon_generated_worldgen.vulcanus.entities)
append_prototype_noise_expressions(eon_noise_expressions, "tree", eon_generated_worldgen.vulcanus.trees)

data:extend(eon_noise_expressions)

if not mods["Spaghetorio"] then
    data:extend({
        duplicate_noise_expression("honeycomb-fungus", "optimized-decorative"),
        duplicate_noise_expression("honeycomb-fungus-1x1", "optimized-decorative"),
        duplicate_noise_expression("honeycomb-fungus-decayed", "optimized-decorative"),
    })
end
