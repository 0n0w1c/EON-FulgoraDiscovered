local eon_mode = require("lib.eon-mode")
local eon_aquilo_registry = require("lib.eon-aquilo-registry")

local snow = {}

local ENABLED = eon_mode.biome_weather
local TILE_NAMES = eon_aquilo_registry.masked_tile_set or eon_aquilo_registry.tile_set or {}

local SNOW_INTERVAL = 20
local SOUND_SCAN_INTERVAL = 60
local ICE_CRACK_MIN_INTERVAL = 600
local ICE_CRACK_MAX_INTERVAL = 1200
local WIND_GUST_MIN_INTERVAL = 900
local WIND_GUST_MAX_INTERVAL = 1800

local AUDIO_SURFACE_NAMES = {
    nauvis = true,
    fulgora = true
}

local function ensure_storage()
    storage.eon_fd_aquilo_snow = storage.eon_fd_aquilo_snow or {}
    local state = storage.eon_fd_aquilo_snow
    state.next_ice_crack_tick_by_player = state.next_ice_crack_tick_by_player or {}
    state.next_wind_gust_tick_by_player = state.next_wind_gust_tick_by_player or {}
    return state
end

local function player_tile_name(player)
    if not (player and player.valid and player.connected) then return nil end
    if not (player.character and player.character.valid) then return nil end

    local surface = player.surface
    if not (surface and surface.valid) then return nil end

    local tile = surface.get_tile(player.position)
    if not (tile and tile.valid) then return nil end

    return surface.name, tile.name
end

local function player_on_aquilo_tile_for_snow(player)
    local surface_name, tile_name = player_tile_name(player)
    return surface_name == "nauvis" and TILE_NAMES[tile_name] == true
end

local function player_on_aquilo_tile_for_audio(player)
    local surface_name, tile_name = player_tile_name(player)
    return AUDIO_SURFACE_NAMES[surface_name] == true and TILE_NAMES[tile_name] == true
end

local function spawn_snow(event)
    if event.tick % SNOW_INTERVAL ~= 0 then return end

    for _, player in pairs(game.connected_players) do
        if player_on_aquilo_tile_for_snow(player) then
            player.surface.create_entity {
                name = "eon-fd-aquilo-snow-effect",
                position = player.position
            }
        end
    end
end

local function play_snow_sounds(event)
    if event.tick % SOUND_SCAN_INTERVAL ~= 0 then return end

    local state = ensure_storage()
    local next_ice_crack_by_player = state.next_ice_crack_tick_by_player
    local next_wind_gust_by_player = state.next_wind_gust_tick_by_player

    for _, player in pairs(game.connected_players) do
        local index = player.index

        if player_on_aquilo_tile_for_audio(player) then
            if event.tick >= (next_ice_crack_by_player[index] or 0) then
                player.play_sound {
                    path = "eon-fd-aquilo-ice-cracks",
                    position = player.position,
                    override_sound_type = "environment"
                }
                next_ice_crack_by_player[index] = event.tick + math.random(ICE_CRACK_MIN_INTERVAL, ICE_CRACK_MAX_INTERVAL)
            end

            if event.tick >= (next_wind_gust_by_player[index] or 0) then
                player.play_sound {
                    path = "eon-fd-aquilo-cold-wind-gust",
                    position = player.position,
                    override_sound_type = "environment"
                }
                next_wind_gust_by_player[index] = event.tick + math.random(WIND_GUST_MIN_INTERVAL, WIND_GUST_MAX_INTERVAL)
            end
        else
            next_ice_crack_by_player[index] = nil
            next_wind_gust_by_player[index] = nil
        end
    end
end

function snow.on_init()
    if ENABLED then ensure_storage() end
end

function snow.on_configuration_changed()
    if ENABLED then ensure_storage() end
end

function snow.on_tick(event)
    if not ENABLED then return end
    spawn_snow(event)
    play_snow_sounds(event)
end

return snow
