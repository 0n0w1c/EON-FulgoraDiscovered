local fulgora_setup = {}

---@param planet_name string
---@return any
local function planet_has_unit_spawner_autoplace(planet_name)
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

---@return nil
local function remove_all_tree_autoplace_from_fulgora()
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

---@return nil
function fulgora_setup.apply()
    local fulgora = data.raw.planet and data.raw.planet["fulgora"]
    if fulgora then
        fulgora.pollutant_type = planet_has_unit_spawner_autoplace("fulgora") and "pollution" or nil
    end

    remove_all_tree_autoplace_from_fulgora()
end

return fulgora_setup
