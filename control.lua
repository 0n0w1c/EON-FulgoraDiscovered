local eon_mode = require("lib.eon-mode")
local eon_aquilo_on_fulgora = eon_mode.aquilo_on_fulgora

local eon_enemy_registry = require("lib.eon-enemy-registry")
local eon_runtime_cliffs = require("lib.eon-runtime-cliffs")
local eon_runtime_enemies = require("lib.eon-runtime-enemies")
local eon_runtime_existing_surface_setup = require("lib.eon-runtime-existing-surface-setup")
local eon_runtime_nuke_effects = require("lib.eon-runtime-nuke-effects")
local eon_runtime_biome_weather = require("lib.eon-runtime-biome-weather")

local surface_names = eon_enemy_registry.surface_names_for_mode(eon_aquilo_on_fulgora)
local eon_enemy_handlers = eon_runtime_enemies.create_handlers({
    aquilo_on_fulgora = eon_aquilo_on_fulgora,
})

script.on_event(defines.events.on_script_trigger_effect, eon_runtime_nuke_effects.on_script_trigger_effect)
eon_runtime_biome_weather.register_events()
script.on_event(defines.events.on_unit_group_finished_gathering, eon_enemy_handlers.on_unit_group_finished_gathering)
script.on_event(defines.events.on_biter_base_built, function(event)
    eon_enemy_handlers.enforce_enemy_base_entity(event.entity)
end)
script.on_event(defines.events.script_raised_built, function(event)
    eon_enemy_handlers.enforce_enemy_base_entity(event.entity)
end)

script.on_event(defines.events.on_chunk_generated, function(event)
    local surface = event.surface
    if not (surface and surface.valid) then return end

    if surface_names[surface.name] then
        eon_runtime_cliffs.process_area(surface, event.area, {
            aquilo_on_fulgora = eon_aquilo_on_fulgora,
        })
    end
end)

script.on_init(function()
    eon_runtime_existing_surface_setup.enable_explosive_biters_on_existing_nauvis()
    eon_runtime_biome_weather.on_init()
end)

script.on_configuration_changed(function()
    eon_runtime_existing_surface_setup.enable_explosive_biters_on_existing_nauvis()
    eon_runtime_biome_weather.on_configuration_changed()
end)
