local eon_mode = require("lib.eon-mode")
local eon_runtime_gleba_rain = require("lib.eon-runtime-gleba-rain")
local eon_runtime_aquilo_snow = require("lib.eon-runtime-aquilo-snow")

local biome_weather = {}

local BIOME_WEATHER_ENABLED = eon_mode.biome_weather

local function on_tick(event)
    eon_runtime_gleba_rain.on_tick(event)
    eon_runtime_aquilo_snow.on_tick(event)
end

function biome_weather.register_events()
    if BIOME_WEATHER_ENABLED then script.on_event(defines.events.on_tick, on_tick) end
end

function biome_weather.on_init()
    eon_runtime_gleba_rain.on_init()
    eon_runtime_aquilo_snow.on_init()
end

function biome_weather.on_configuration_changed()
    eon_runtime_gleba_rain.on_configuration_changed()
    eon_runtime_aquilo_snow.on_configuration_changed()
end

return biome_weather
