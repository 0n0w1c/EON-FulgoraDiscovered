local eon_mode = require("lib.eon-mode")
local eon_aquilo_on_fulgora = eon_mode.aquilo_on_fulgora

local eon_enemy_registry = require("lib.eon-enemy-registry")
local eon_runtime_cliffs = require("lib.eon-runtime-cliffs")
local eon_runtime_enemies = require("lib.eon-runtime-enemies")
local eon_runtime_existing_surface_setup = require("lib.eon-runtime-existing-surface-setup")
local eon_runtime_demolisher_force = require("lib.eon-runtime-demolisher-force")
local eon_runtime_nuke_effects = require("lib.eon-runtime-nuke-effects")
local eon_runtime_biome_weather = require("lib.eon-runtime-biome-weather")

local surface_names = eon_enemy_registry.surface_names_for_mode(eon_aquilo_on_fulgora)
local eon_enemy_handlers = eon_runtime_enemies.create_handlers({
    aquilo_on_fulgora = eon_aquilo_on_fulgora,
})

---@param event EventData.on_biter_base_built
local function on_biter_base_built(event)
    eon_enemy_handlers.enforce_enemy_base_entity(event.entity)
end

---@param event EventData.script_raised_built
local function on_script_raised_built(event)
    eon_enemy_handlers.enforce_enemy_base_entity(event.entity)
end

---@param event EventData.on_chunk_generated
local function on_chunk_generated(event)
    local surface = event.surface
    if not (surface and surface.valid) then return end

    if surface_names[surface.name] then
        eon_runtime_cliffs.process_area(surface, event.area, {
            aquilo_on_fulgora = eon_aquilo_on_fulgora,
        })
    end
end

local function on_init()
    eon_runtime_existing_surface_setup.enable_explosive_biters_on_existing_nauvis()
    eon_runtime_demolisher_force.apply()
    eon_runtime_biome_weather.on_init()
end

local function on_configuration_changed()
    eon_runtime_existing_surface_setup.enable_explosive_biters_on_existing_nauvis()
    eon_runtime_demolisher_force.apply()
    eon_runtime_biome_weather.on_configuration_changed()
end

script.on_event(defines.events.on_script_trigger_effect, eon_runtime_nuke_effects.on_script_trigger_effect)
script.on_event(defines.events.on_unit_group_finished_gathering, eon_enemy_handlers.on_unit_group_finished_gathering)
script.on_event(defines.events.on_segmented_unit_created, eon_runtime_demolisher_force.on_segmented_unit_created)
script.on_event(defines.events.on_biter_base_built, on_biter_base_built)
script.on_event(defines.events.script_raised_built, on_script_raised_built)
script.on_event(defines.events.on_chunk_generated, on_chunk_generated)

script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)

eon_runtime_biome_weather.register_events()
