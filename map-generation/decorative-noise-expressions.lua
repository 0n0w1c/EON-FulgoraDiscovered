local data_util = require("data-util")

---@param name string
---@param prototype_type string
---@return table
local function duplicate_noise_expression(name, prototype_type)
    local expression = {
        type = "noise-expression",
        name = data_util.generate_eon_name(name),
        expression = data.raw[prototype_type][name].autoplace.probability_expression
    }
    if data.raw[prototype_type][name].autoplace.local_expressions then
        expression.local_expressions = data.raw[prototype_type][name].autoplace.local_expressions
    end
    return expression
end

---@param name string
---@return table
local function duplicate_noise_function(name)
    local expression = table.deepcopy(data.raw["noise-function"][name])
    expression.name = data_util.generate_eon_name(name)
    return expression
end

local extended_noise_expression_names = {}

---@param prototypes table[]
---@return nil
local function extend_unique_noise_prototypes(prototypes)
    local unique = {}

    for _, prototype in pairs(prototypes) do
        if prototype and prototype.name and not extended_noise_expression_names[prototype.name] then
            extended_noise_expression_names[prototype.name] = true

            if not (data.raw[prototype.type] and data.raw[prototype.type][prototype.name]) then
                table.insert(unique, prototype)
            end
        end
    end

    if next(unique) then
        data:extend(unique)
    end
end

---@param decorative_name string
---@return table
local function duplicate_vulcanus_optimized_decorative_noise_expression(decorative_name)
    local result = duplicate_noise_expression(decorative_name, "optimized-decorative")
    local expression_name = result.expression
    local referenced_expression = type(expression_name) == "string"
        and data.raw["noise-expression"]
        and data.raw["noise-expression"][expression_name]

    if referenced_expression and referenced_expression.expression then
        result.expression = referenced_expression.expression
        if referenced_expression.local_expressions then
            result.local_expressions = table.deepcopy(referenced_expression.local_expressions)
        end
    end

    return result
end

extend_unique_noise_prototypes({
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

    duplicate_noise_expression("snow-flat", "tile"),
    duplicate_noise_expression("snow-crests", "tile"),
    duplicate_noise_expression("snow-lumpy", "tile"),
    duplicate_noise_expression("snow-patchy", "tile"),
    duplicate_noise_expression("ice-rough", "tile"),
    duplicate_noise_expression("ice-smooth", "tile"),
    duplicate_noise_expression("brash-ice", "tile"),

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

    duplicate_noise_expression("natural-yumako-soil", "tile"),
    duplicate_noise_expression("natural-jellynut-soil", "tile"),
    duplicate_noise_expression("wetland-yumako", "tile"),
    duplicate_noise_expression("wetland-jellynut", "tile"),
    duplicate_noise_expression("wetland-blue-slime", "tile"),
    duplicate_noise_expression("wetland-light-green-slime", "tile"),
    duplicate_noise_expression("wetland-green-slime", "tile"),
    duplicate_noise_expression("wetland-light-dead-skin", "tile"),
    duplicate_noise_expression("wetland-dead-skin", "tile"),
    duplicate_noise_expression("wetland-pink-tentacle", "tile"),
    duplicate_noise_expression("wetland-red-tentacle", "tile"),
    duplicate_noise_expression("gleba-deep-lake", "tile"),
    duplicate_noise_expression("lowland-brown-blubber", "tile"),
    duplicate_noise_expression("lowland-olive-blubber", "tile"),
    duplicate_noise_expression("lowland-olive-blubber-2", "tile"),
    duplicate_noise_expression("lowland-olive-blubber-3", "tile"),
    duplicate_noise_expression("lowland-pale-green", "tile"),
    duplicate_noise_expression("lowland-cream-cauliflower", "tile"),
    duplicate_noise_expression("lowland-cream-cauliflower-2", "tile"),
    duplicate_noise_expression("lowland-dead-skin", "tile"),
    duplicate_noise_expression("lowland-dead-skin-2", "tile"),
    duplicate_noise_expression("lowland-cream-red", "tile"),
    duplicate_noise_expression("lowland-red-vein", "tile"),
    duplicate_noise_expression("lowland-red-vein-2", "tile"),
    duplicate_noise_expression("lowland-red-vein-3", "tile"),
    duplicate_noise_expression("lowland-red-vein-4", "tile"),
    duplicate_noise_expression("lowland-red-vein-dead", "tile"),
    duplicate_noise_expression("lowland-red-infection", "tile"),
    duplicate_noise_expression("midland-turquoise-bark", "tile"),
    duplicate_noise_expression("midland-turquoise-bark-2", "tile"),
    duplicate_noise_expression("midland-cracked-lichen", "tile"),
    duplicate_noise_expression("midland-cracked-lichen-dull", "tile"),
    duplicate_noise_expression("midland-cracked-lichen-dark", "tile"),
    duplicate_noise_expression("midland-yellow-crust", "tile"),
    duplicate_noise_expression("midland-yellow-crust-2", "tile"),
    duplicate_noise_expression("midland-yellow-crust-3", "tile"),
    duplicate_noise_expression("midland-yellow-crust-4", "tile"),
    duplicate_noise_expression("highland-dark-rock", "tile"),
    duplicate_noise_expression("highland-dark-rock-2", "tile"),
    duplicate_noise_expression("highland-yellow-rock", "tile"),
    duplicate_noise_expression("pit-rock", "tile"),

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

    duplicate_noise_expression("volcanic-ash-flats", "tile"),
    duplicate_noise_expression("volcanic-ash-light", "tile"),
    duplicate_noise_expression("volcanic-ash-dark", "tile"),
    duplicate_noise_expression("volcanic-cracks", "tile"),
    duplicate_noise_expression("volcanic-cracks-warm", "tile"),
    duplicate_noise_expression("volcanic-folds-warm", "tile"),
    duplicate_noise_expression("volcanic-pumice-stones", "tile"),
    duplicate_noise_expression("volcanic-cracks-hot", "tile"),
    duplicate_noise_expression("volcanic-jagged-ground", "tile"),
    duplicate_noise_expression("volcanic-smooth-stone", "tile"),
    duplicate_noise_expression("volcanic-smooth-stone-warm", "tile"),
    duplicate_noise_expression("volcanic-ash-cracks", "tile"),

    duplicate_noise_expression("vulcanus-chimney", "simple-entity"),
    duplicate_noise_expression("vulcanus-chimney-faded", "simple-entity"),
    duplicate_noise_expression("vulcanus-chimney-cold", "simple-entity"),
    duplicate_noise_expression("vulcanus-chimney-short", "simple-entity"),
    duplicate_noise_expression("vulcanus-chimney-truncated", "simple-entity"),
    duplicate_noise_expression("huge-volcanic-rock", "simple-entity"),
    duplicate_noise_expression("big-volcanic-rock", "simple-entity"),
    duplicate_noise_expression("ashland-lichen-tree", "tree"),
    duplicate_noise_expression("ashland-lichen-tree-flaming", "tree"),

    duplicate_noise_expression("calcite", "resource"),
    duplicate_noise_expression("tungsten-ore", "resource"),

    duplicate_noise_function("water_base")
})

---@return table<string, table>|nil
local function eon_vulcanus_optimized_decorative_settings()
    local planet = data.raw.planet and data.raw.planet["vulcanus"]
    return planet
        and planet.map_gen_settings
        and planet.map_gen_settings.autoplace_settings
        and planet.map_gen_settings.autoplace_settings.decorative
        and planet.map_gen_settings.autoplace_settings.decorative.settings
end

---@return nil
local function eon_extend_vulcanus_optimized_decorative_noise_expressions()
    local settings = eon_vulcanus_optimized_decorative_settings()
    if not settings then return end

    local expressions = {}
    for decorative_name, _ in pairs(settings) do
        local decorative = data.raw["optimized-decorative"]
            and data.raw["optimized-decorative"][decorative_name]
        if decorative and decorative.autoplace and decorative.autoplace.probability_expression then
            table.insert(expressions, duplicate_vulcanus_optimized_decorative_noise_expression(decorative_name))
        end
    end

    if next(expressions) then
        extend_unique_noise_prototypes(expressions)
    end
end

eon_extend_vulcanus_optimized_decorative_noise_expressions()

extend_unique_noise_prototypes({
    duplicate_noise_expression("honeycomb-fungus", "optimized-decorative"),
    duplicate_noise_expression("honeycomb-fungus-1x1", "optimized-decorative"),
    duplicate_noise_expression("honeycomb-fungus-decayed", "optimized-decorative"),
})
