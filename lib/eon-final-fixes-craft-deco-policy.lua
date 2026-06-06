local eon_mode = require("lib.eon-mode")

local eon_final_fixes_craft_deco_policy = {}

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
    if not (mods["craft-deco-2"] and eon_mode.hide_craft_deco_2_technology) then return end

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

---@return nil
function eon_final_fixes_craft_deco_policy.apply()
    eon_hide_craft_deco_2_recipes()
end

return eon_final_fixes_craft_deco_policy
