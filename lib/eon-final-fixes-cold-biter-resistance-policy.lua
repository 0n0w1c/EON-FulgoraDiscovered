local eon_mode = require("lib.eon-mode")
local eon_enemy_registry = require("lib.eon-enemy-registry")

local eon_final_fixes_cold_biter_resistance_policy = {}

---@param resistance_owner table|nil
---@return boolean
local function eon_set_full_electric_resistance(resistance_owner)
    if not resistance_owner then return false end

    resistance_owner.resistances = resistance_owner.resistances or {}

    for _, resistance in pairs(resistance_owner.resistances) do
        if resistance.type == "electric" then
            resistance.percent = 100
            return true
        end
    end

    table.insert(resistance_owner.resistances, { type = "electric", percent = 100 })
    return true
end

---@param prototype_type string
---@param prototype_name string
---@return boolean
local function eon_is_cold_biter_enemy_prototype(prototype_type, prototype_name)
    return eon_enemy_registry.is_cold_biter_prototype(prototype_type, prototype_name)
end

---@return nil
local function eon_make_cold_biters_electric_immune_on_fulgora_aquilo()
    if not eon_mode.aquilo_on_fulgora then return end
    if not (mods["Cold_biters"] or mods["Frost_biters"]) then return end

    local patched = 0
    for _, prototype_type in pairs(eon_enemy_registry.final_fixes.resistance_patch_types) do
        for prototype_name, prototype in pairs(data.raw[prototype_type] or {}) do
            if eon_is_cold_biter_enemy_prototype(prototype_type, prototype_name)
                and eon_set_full_electric_resistance(prototype)
            then
                patched = patched + 1
            end
        end
    end
end

---@return nil
function eon_final_fixes_cold_biter_resistance_policy.apply()
    eon_make_cold_biters_electric_immune_on_fulgora_aquilo()
end

return eon_final_fixes_cold_biter_resistance_policy
