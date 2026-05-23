require("prototypes.remove-planets")
require("prototypes.surface-conditions")
require("prototypes.planet-sounds")

require("prototypes.patches")

-- ---------------------------------------------------------------------------
-- Enable Fulgora pollution only when enemy spawners are generated there
-- ---------------------------------------------------------------------------
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
