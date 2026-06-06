local mode = {}

---@param name string
---@return boolean
local function startup_bool(name)
    local setting = settings.startup[name]
    return setting ~= nil and setting.value == true
end

mode.planet_sounds = startup_bool("eon-fd-planet-sounds")
mode.gleba_enemies_react_to_pollution = startup_bool("eon-fd-gleba-enemies-react-to-pollution")
mode.use_tungsten_plate = startup_bool("eon-fd-use-tungsten-plate")
mode.guarded_resources = startup_bool("eon-fd-guarded-resources")
mode.aquilo_on_fulgora = startup_bool("eon-fd-aquilo-on-fulgora")
mode.hide_craft_deco_2_technology = startup_bool("eon-fd-hide-craft-deco-2-technology")

mode.aquilo_surface = mode.aquilo_on_fulgora and "fulgora" or "nauvis"
mode.vulcanus_mode = mode.aquilo_on_fulgora and "northern_region" or "volcano_spots"
mode.enable_fulgora_freezing = mode.aquilo_on_fulgora

return mode
