local eon_mode = require("lib.eon-mode")
local eon_gleba_registry = require("lib.eon-gleba-registry")

local rain = {}

local GLEBA_RAIN_ENABLED = eon_mode.biome_weather
local WET_TILE_NAMES = eon_gleba_registry.masked_tile_set or eon_gleba_registry.tile_set or {}

local RAIN_INTERVAL = 15
local SOUND_SCAN_INTERVAL = 60
local SOUND_REPEAT_INTERVAL = 480  -- 8 seconds at 60 UPS
local THUNDER_SCAN_INTERVAL = 1800 -- 30 seconds at 60 UPS
local THUNDER_FLASH_DISTANCE = 64
local THUNDER_FLASH_SCALE = 96
local THUNDER_FLASH_INTENSITY = 2
local THUNDER_FLASH_TTL = 12

local function ensure_storage()
    storage.eon_fd_gleba_rain = storage.eon_fd_gleba_rain or {}
    local state = storage.eon_fd_gleba_rain
    state.next_rain_sound_tick_by_player = state.next_rain_sound_tick_by_player or {}
    return state
end

function rain.on_init()
    if GLEBA_RAIN_ENABLED then ensure_storage() end
end

function rain.on_configuration_changed()
    if GLEBA_RAIN_ENABLED then ensure_storage() end
end

local function player_on_gleba_tile(player)
    if not (player and player.valid and player.connected) then return false end
    if not (player.character and player.character.valid) then return false end
    local surface = player.surface
    if not (surface and surface.valid and surface.name == "nauvis") then return false end

    local tile = surface.get_tile(player.position)
    return tile and tile.valid and WET_TILE_NAMES[tile.name] == true
end

local function spawn_rain(event)
    if event.tick % RAIN_INTERVAL ~= 0 then return end

    for _, player in pairs(game.connected_players) do
        if player_on_gleba_tile(player) then
            player.surface.create_entity {
                name = "eon-fd-gleba-rain-effect",
                position = player.position
            }
        end
    end
end

local function draw_flash_light(surface, position, scale, intensity)
    rendering.draw_light {
        sprite = "utility/light_medium",
        surface = surface,
        target = position,
        scale = scale,
        intensity = intensity,
        minimum_darkness = 0,
        color = { r = 0.5, g = 0.5, b = 1, a = 1 },
        render_mode = "game",
        time_to_live = THUNDER_FLASH_TTL,
        blink_interval = math.floor(math.max(4, math.random() * 8))
    }
end

local function draw_thunder_flash(player)
    local position = {
        player.position.x + math.random(-THUNDER_FLASH_DISTANCE, THUNDER_FLASH_DISTANCE),
        player.position.y + math.random(-THUNDER_FLASH_DISTANCE, THUNDER_FLASH_DISTANCE)
    }

    -- Keep the flash distant, matching the style used by dynamic-rain.
    draw_flash_light(player.surface, position, THUNDER_FLASH_SCALE, THUNDER_FLASH_INTENSITY)

    return position
end

local function play_rain_sound(event)
    if event.tick % SOUND_SCAN_INTERVAL ~= 0 then return end

    local state = ensure_storage()
    local next_by_player = state.next_rain_sound_tick_by_player
    for _, player in pairs(game.connected_players) do
        if player_on_gleba_tile(player) then
            local index = player.index

            if event.tick >= (next_by_player[index] or 0) then
                player.play_sound {
                    path = "eon-fd-gleba-rain-sound",
                    position = player.position
                }
                next_by_player[index] = event.tick + SOUND_REPEAT_INTERVAL
            end

            if event.tick % THUNDER_SCAN_INTERVAL == 0 then
                local thunder_position = draw_thunder_flash(player)

                player.play_sound {
                    path = "eon-fd-gleba-tile-thunder",
                    position = thunder_position
                }
            end
        else
            next_by_player[player.index] = nil
        end
    end
end

function rain.on_tick(event)
    if not GLEBA_RAIN_ENABLED then return end
    spawn_rain(event)
    play_rain_sound(event)
end

return rain
