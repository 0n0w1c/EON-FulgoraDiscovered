local eon_mode = require("lib.eon-mode")
local eon_aquilo_registry = require("lib.eon-aquilo-registry")

local snow = {}

local AQUILO_SNOW_ENABLED = eon_mode.biome_weather
local SNOW_TILE_NAMES = eon_aquilo_registry.tile_set or {}

local SNOW_INTERVAL = 20

local function player_on_aquilo_tile(player)
    if not (player and player.valid and player.connected) then return false end
    if not (player.character and player.character.valid) then return false end
    local surface = player.surface
    if not (surface and surface.valid and surface.name == "nauvis") then return false end

    local tile = surface.get_tile(player.position)
    return tile and tile.valid and SNOW_TILE_NAMES[tile.name] == true
end

local function spawn_snow(event)
    if event.tick % SNOW_INTERVAL ~= 0 then return end

    for _, player in pairs(game.connected_players) do
        if player_on_aquilo_tile(player) then
            player.surface.create_entity {
                name = "eon-fd-aquilo-snow-effect",
                position = player.position
            }
        end
    end
end

function snow.on_init()
    -- No persistent snow state is needed right now.
end

function snow.on_configuration_changed()
    -- No persistent snow state is needed right now.
end

function snow.on_tick(event)
    if not AQUILO_SNOW_ENABLED then return end
    spawn_snow(event)
end

return snow
