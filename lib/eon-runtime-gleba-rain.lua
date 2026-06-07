local eon_mode = require("lib.eon-mode")
local eon_gleba_registry = require("lib.eon-gleba-registry")

local rain = {}

local GLEBA_RAIN_ENABLED = eon_mode.biome_weather
local WET_TILE_NAMES = eon_gleba_registry.masked_tile_set or eon_gleba_registry.tile_set or {}

local RAIN_INTERVAL = 15
local SOUND_SCAN_INTERVAL = 60
local SOUND_REPEAT_INTERVAL = 480  -- 8 seconds at 60 UPS
local THUNDER_SCAN_INTERVAL = 1800 -- 30 seconds at 60 UPS

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
                player.play_sound {
                    path = "eon-fd-gleba-tile-thunder",
                    position = player.position
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
