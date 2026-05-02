local move_aquilo =
    settings.startup["eon-fd-aquilo-on-fulgora"] and
    settings.startup["eon-fd-aquilo-on-fulgora"].value

if move_aquilo then
    local recipes = data.raw["recipe"]
    local recipe = recipes["solid-fuel-from-ammonia"]

    if recipe and recipe.ingredients then
        for _, ingredient in pairs(recipe.ingredients) do
            if ingredient.type == "fluid" and ingredient.name == "crude-oil" then
                ingredient.name = "heavy-oil"
            end
        end
    end

    local fulgora = data.raw["planet"]["fulgora"]
    if fulgora then
        fulgora.entities_require_heating = true
    end
end

require("prototypes.technologies")
require("prototypes.tiles")

require("map-generation.enemies")
require("map-generation.resources-updates")
require("map-generation.terrain")
