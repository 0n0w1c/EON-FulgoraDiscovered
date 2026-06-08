local eon_mode = require("lib.eon-mode")
local eon_runtime_gleba_rain = require("lib.eon-runtime-gleba-rain")
local eon_runtime_aquilo_snow = require("lib.eon-runtime-aquilo-snow")
local eon_runtime_vulcanus_sounds = require("lib.eon-runtime-vulcanus-sounds")

local weather = {}

local ENABLED = eon_mode.biome_weather

local modules = {
    eon_runtime_gleba_rain,
    eon_runtime_aquilo_snow,
    eon_runtime_vulcanus_sounds,
}

local function call_all(function_name, event)
    for _, module in pairs(modules) do
        local handler = module[function_name]
        if handler then
            handler(event)
        end
    end
end

function weather.on_init()
    if ENABLED then
        call_all("on_init")
    end
end

function weather.on_configuration_changed()
    if ENABLED then
        call_all("on_configuration_changed")
    end
end

function weather.register_events()
    if not ENABLED then return end

    script.on_event(defines.events.on_tick, function(event)
        call_all("on_tick", event)
    end)
end

return weather
