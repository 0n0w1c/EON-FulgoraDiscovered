local eon_aquilo_registry = require("lib.eon-aquilo-registry")
local eon_terrain_map_gen = require("lib.eon-terrain-map-gen")

local eon_aquilo_map_gen_setup = {}

---@class EonAquiloMapGenSetupOptions
---@field aquilo_on_fulgora boolean Whether Aquilo is routed to Fulgora instead of Nauvis.
---@field aquilo_planet_name string Active planet prototype receiving Aquilo map-generation settings.

---@param options EonAquiloMapGenSetupOptions
---@return nil
function eon_aquilo_map_gen_setup.apply(options)
    local aquilo_on_fulgora = options.aquilo_on_fulgora
    local aquilo_planet_name = options.aquilo_planet_name

    local aquilo_planet = data.raw.planet[aquilo_planet_name]
    local aquilo_map_gen = aquilo_planet and aquilo_planet.map_gen_settings
    local inactive_aquilo_planet_name = eon_aquilo_registry.inactive_planet_name({ aquilo_on_fulgora = aquilo_on_fulgora })
    local inactive_aquilo_planet = data.raw.planet[inactive_aquilo_planet_name]
    local inactive_aquilo_map_gen = inactive_aquilo_planet and inactive_aquilo_planet.map_gen_settings

    local aquilo_autoplace_controls = eon_aquilo_registry.autoplace_controls

    for resource_name, control_name in pairs(eon_aquilo_registry.resource_controls) do
        if data.raw.resource[resource_name] and data.raw.resource[resource_name].autoplace then
            data.raw.resource[resource_name].autoplace.control = control_name
        end
    end

    if aquilo_map_gen then
        eon_terrain_map_gen.enable_autoplace_controls(aquilo_map_gen, aquilo_autoplace_controls)
        eon_terrain_map_gen.disable_autoplace_controls(inactive_aquilo_map_gen, aquilo_autoplace_controls)

        for _, tile_name in ipairs(eon_aquilo_registry.tiles) do
            aquilo_map_gen.autoplace_settings.tile.settings[tile_name] = {}
        end

        for _, decorative_name in ipairs(eon_aquilo_registry.decoratives) do
            aquilo_map_gen.autoplace_settings.decorative.settings[decorative_name] = {}
        end

        for _, entity_name in ipairs(eon_aquilo_registry.entities) do
            aquilo_map_gen.autoplace_settings.entity.settings[entity_name] = {}
        end
    end

    if not aquilo_on_fulgora then
        local lithium_brine = data.raw.resource["lithium-brine"]
        if lithium_brine and lithium_brine.autoplace then
            eon_terrain_map_gen.set_resource_property_expression_if_string(
                "nauvis",
                "lithium-brine",
                "probability",
                lithium_brine.autoplace.probability_expression
            )
            eon_terrain_map_gen.set_resource_property_expression_if_string(
                "nauvis",
                "lithium-brine",
                "richness",
                lithium_brine.autoplace.richness_expression
            )
        end

        local fluorine_vent = data.raw.resource["fluorine-vent"]
        if fluorine_vent and fluorine_vent.autoplace then
            eon_terrain_map_gen.set_resource_property_expression_if_string(
                "nauvis",
                "fluorine-vent",
                "probability",
                fluorine_vent.autoplace.probability_expression
            )
            eon_terrain_map_gen.set_resource_property_expression_if_string(
                "nauvis",
                "fluorine-vent",
                "richness",
                fluorine_vent.autoplace.richness_expression
            )
        end
    end
end

return eon_aquilo_map_gen_setup
