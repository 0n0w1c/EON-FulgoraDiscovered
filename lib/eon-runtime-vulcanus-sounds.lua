local eon_mode = require("lib.eon-mode")
local eon_volcanus_registry = require("lib.eon-volcanus-registry")

local sounds = {}

local ENABLED = eon_mode.biome_weather
local TILE_NAMES = eon_volcanus_registry.biome_weather_sound_tile_set or eon_volcanus_registry.all_tile_set or {}

local SCAN_INTERVAL = 60
local RUMBLE_MIN_INTERVAL = 1500
local RUMBLE_MAX_INTERVAL = 2100

local next_rumble_tick = 0

local function schedule_next_rumble(from_tick)
    next_rumble_tick = from_tick + math.random(RUMBLE_MIN_INTERVAL, RUMBLE_MAX_INTERVAL)
end

local function player_tile_name_on_nauvis(player)
    if not (player and player.valid and player.connected) then return nil end
    if not (player.character and player.character.valid) then return nil end

    local surface = player.surface
    if not (surface and surface.valid and surface.name == "nauvis") then return nil end

    local tile = surface.get_tile(player.position)
    if not (tile and tile.valid) then return nil end

    return tile.name
end

local function play_rumble(event)
    if event.tick % SCAN_INTERVAL ~= 0 then return end
    if event.tick < next_rumble_tick then return end

    schedule_next_rumble(event.tick)

    for _, player in pairs(game.connected_players) do
        local tile_name = player_tile_name_on_nauvis(player)
        if tile_name and TILE_NAMES[tile_name] == true then
            player.play_sound {
                path = "eon-fd-vulcanus-distant-rumble",
                override_sound_type = "environment"
            }
        end
    end
end

function sounds.on_init()
    next_rumble_tick = 0
end

function sounds.on_configuration_changed()
    next_rumble_tick = 0
end

function sounds.on_tick(event)
    if not ENABLED then return end
    play_rumble(event)
end

return sounds
