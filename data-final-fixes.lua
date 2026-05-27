require("prototypes.remove-planets")
require("prototypes.surface-conditions")
require("prototypes.planet-sounds")

require("prototypes.patches")


---@param planet_name string
---@return any
local function eon_planet_has_unit_spawner_autoplace(planet_name)
    local planet = data.raw.planet and data.raw.planet[planet_name]
    local entity_settings = planet
        and planet.map_gen_settings
        and planet.map_gen_settings.autoplace_settings
        and planet.map_gen_settings.autoplace_settings.entity
        and planet.map_gen_settings.autoplace_settings.entity.settings

    if not entity_settings then return false end

    for entity_name, _ in pairs(entity_settings) do
        local spawner = data.raw["unit-spawner"] and data.raw["unit-spawner"][entity_name]
        if spawner and spawner.autoplace then
            return true
        end
    end

    return false
end

local fulgora = data.raw.planet and data.raw.planet["fulgora"]
if fulgora then
    fulgora.pollutant_type = eon_planet_has_unit_spawner_autoplace("fulgora") and "pollution" or nil
end

---@return nil
local function eon_remove_all_tree_autoplace_from_fulgora()
    local planet = data.raw.planet and data.raw.planet["fulgora"]
    local settings = planet
        and planet.map_gen_settings
        and planet.map_gen_settings.autoplace_settings
        and planet.map_gen_settings.autoplace_settings.entity
        and planet.map_gen_settings.autoplace_settings.entity.settings

    if not settings then return end

    for tree_name, _ in pairs(data.raw.tree or {}) do
        settings[tree_name] = nil
    end
end

eon_remove_all_tree_autoplace_from_fulgora()

---@param recipe_name string
---@return any
local function eon_is_craft_deco_recipe_name(recipe_name)
    return type(recipe_name) == "string" and string.sub(recipe_name, 1, 15) == "craftdeco-base-"
end

---@param technology table
---@return any
local function eon_technology_unlocks_craft_deco_recipe(technology)
    if type(technology.effects) ~= "table" then return false end

    for _, effect in pairs(technology.effects) do
        if effect.type == "unlock-recipe" and eon_is_craft_deco_recipe_name(effect.recipe) then
            return true
        end
    end

    return false
end

---@return nil
local function eon_hide_craft_deco_2_recipes()
    local setting = settings.startup["eon-fd-hide-craft-deco-2-technology"]
    if not (mods["craft-deco-2"] and setting and setting.value) then return end

    for technology_name, technology in pairs(data.raw.technology or {}) do
        if string.match(technology_name, "^craft%-deco.*%-landscaping$")
            or eon_technology_unlocks_craft_deco_recipe(technology)
        then
            technology.hidden = true
            technology.enabled = false
            technology.effects = nil
        end
    end

    for recipe_name, recipe in pairs(data.raw.recipe or {}) do
        if eon_is_craft_deco_recipe_name(recipe_name) then
            recipe.hidden = true
            recipe.enabled = false
        end
    end

    for item_name, item in pairs(data.raw.item or {}) do
        if eon_is_craft_deco_recipe_name(item_name) then
            item.hidden = true
            item.hidden_in_factoriopedia = true
        end
    end
end

eon_hide_craft_deco_2_recipes()
