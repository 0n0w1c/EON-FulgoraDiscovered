local eon_mode = require("lib.eon-mode")
if not eon_mode.biome_weather then return end

local function add_planet_player_effect_smoke(name, planet_name)
    local planet = data.raw.planet and data.raw.planet[planet_name]
    local action = planet and planet.player_effects
    if not action then return end

    data:extend({
        {
            type = "smoke-with-trigger",
            name = name,
            flags = { "not-on-map" },
            show_when_smoke_off = false,
            affected_by_wind = false,
            duration = 2,
            fade_away_duration = 0,
            spread_duration = 0,
            action_cooldown = 1,
            action = table.deepcopy(action),
            animation = {
                filename = "__core__/graphics/empty.png",
                priority = "extra-high",
                width = 1,
                height = 1,
                frame_count = 1
            }
        }
    })
end

add_planet_player_effect_smoke("eon-fd-gleba-rain-effect", "gleba")

data:extend({
    {
        type = "sound",
        name = "eon-fd-gleba-rain-sound",
        filename = "__space-age__/sound/world/weather/rain.ogg",
        category = "environment",
        volume = 0.25,
        audible_distance_modifier = 0.75,
        priority = 100
    },
    {
        type = "sound",
        name = "eon-fd-gleba-tile-thunder",
        variations = {
            { filename = "__space-age__/sound/world/semi-persistent/distant-thunder-1.ogg", volume = 1.5 },
            { filename = "__space-age__/sound/world/semi-persistent/distant-thunder-2.ogg", volume = 1.5 },
            { filename = "__space-age__/sound/world/semi-persistent/distant-thunder-3.ogg", volume = 1.5 },
            { filename = "__space-age__/sound/world/semi-persistent/distant-thunder-4.ogg", volume = 1.5 },
        },
        category = "environment",
        audible_distance_modifier = 3.0,
        priority = 100
    }
})
