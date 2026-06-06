local eon_enemy_registry = require("lib.eon-enemy-registry")

local eon_runtime_existing_surface_setup = {}

local explosive_biter_autoplace_entities =
    eon_enemy_registry.runtime.explosive_biter_existing_surface_autoplace_entities

---@param control table|nil
---@return table
local function eon_copy_autoplace_control(control)
    if not control then return {} end

    local copy = {}
    for key, value in pairs(control) do
        copy[key] = value
    end
    return copy
end

---@return nil
function eon_runtime_existing_surface_setup.enable_explosive_biters_on_existing_nauvis()
    if not script.active_mods["Explosive_biters"] then return end

    local surface = game.surfaces["nauvis"]
    if not surface then return end

    local map_gen_settings = surface.map_gen_settings
    map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}

    if not map_gen_settings.autoplace_controls["hot_enemy_base"] then
        map_gen_settings.autoplace_controls["hot_enemy_base"] =
            eon_copy_autoplace_control(map_gen_settings.autoplace_controls["enemy-base"])
    end

    map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
    map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or { settings = {} }
    map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

    for _, entity_name in pairs(explosive_biter_autoplace_entities) do
        if prototypes.entity[entity_name] and prototypes.entity[entity_name].autoplace_specification then
            map_gen_settings.autoplace_settings.entity.settings[entity_name] =
                map_gen_settings.autoplace_settings.entity.settings[entity_name] or {}
        end
    end

    surface.map_gen_settings = map_gen_settings
end

return eon_runtime_existing_surface_setup
