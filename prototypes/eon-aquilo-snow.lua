local eon_mode = require("lib.eon-mode")
if not eon_mode.biome_weather then return end

data:extend({
    {
        type = "trivial-smoke",
        name = "eon-fd-aquilo-snow-smoke",
        duration = 600,
        fade_in_duration = 120,
        fade_away_duration = 180,
        spread_duration = 360,
        start_scale = 1,
        end_scale = 1,
        color = { 0.92, 0.97, 1.0 },
        cyclic = true,
        affected_by_wind = true,
        animation = {
            width = 64,
            height = 64,
            line_length = 16,
            frame_count = 16,
            shift = { -0.53125, -0.4375 },
            priority = "high",
            animation_speed = 0.0001,
            filename = "__space-age__/graphics/entity/snow/snow.png",
            flags = { "smoke" }
        }
    },
    {
        type = "smoke-with-trigger",
        name = "eon-fd-aquilo-snow-effect",
        flags = { "not-on-map" },
        show_when_smoke_off = false,
        affected_by_wind = false,
        duration = 2,
        fade_away_duration = 0,
        spread_duration = 0,
        action_cooldown = 1,
        action = {
            type = "cluster",
            cluster_count = 14,
            distance = 6,
            distance_deviation = 8,
            action_delivery = {
                type = "instant",
                source_effects = {
                    type = "create-trivial-smoke",
                    smoke_name = "eon-fd-aquilo-snow-smoke",
                    speed = { 0, 0.10 },
                    initial_height = 0.5,
                    speed_multiplier = 1,
                    speed_multiplier_deviation = 0.3,
                    starting_frame = 8,
                    starting_frame_deviation = 8,
                    offset_deviation = { { -96, -48 }, { 96, 48 } },
                    speed_from_center = 0.025,
                    speed_from_center_deviation = 0.08
                }
            }
        },
        animation = {
            filename = "__core__/graphics/empty.png",
            priority = "extra-high",
            width = 1,
            height = 1,
            frame_count = 1
        }
    }
})
