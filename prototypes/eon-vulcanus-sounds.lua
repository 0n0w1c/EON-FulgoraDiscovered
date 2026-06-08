local eon_mode = require("lib.eon-mode")
if not eon_mode.biome_weather then return end

data:extend({
    {
        type = "sound",
        name = "eon-fd-vulcanus-distant-rumble",
        variations = {
            { filename = "__space-age__/sound/world/semi-persistent/distant-rumble-1.ogg", volume = 2.4 },
            { filename = "__space-age__/sound/world/semi-persistent/distant-rumble-2.ogg", volume = 2.4 },
            { filename = "__space-age__/sound/world/semi-persistent/distant-rumble-3.ogg", volume = 2.4 },
        },
        category = "environment",
        audible_distance_modifier = 4.0,
        priority = 100
    }
})
