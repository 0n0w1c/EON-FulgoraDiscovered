local data_util = require("data-util")
local eon_mode = require("lib.eon-mode")
local eon_planet_registry = require("lib.eon-planet-registry")

local move_aquilo_to_fulgora = eon_mode.aquilo_on_fulgora

---@return nil
local function copy_nauvis_aquilo_connection_to_fulgora()
    if not move_aquilo_to_fulgora then
        return
    end

    local source_connection = data.raw["space-connection"][eon_planet_registry.aquilo_connection_to_copy]
    local nauvis_fulgora = data.raw["space-connection"][eon_planet_registry.nauvis_fulgora_connection]

    if not source_connection or not nauvis_fulgora then
        return
    end

    nauvis_fulgora.asteroid_spawn_definitions =
        table.deepcopy(source_connection.asteroid_spawn_definitions)
end

for _, planet_name in ipairs(eon_planet_registry.removed_planets) do
    if data.raw.planet[planet_name] then
        data.raw.planet[planet_name].map_gen_settings = nil
        data.raw.planet[planet_name].hidden = true
    end
end

for _, connection_name in ipairs(eon_planet_registry.space_connections_to_delete) do
    if connection_name ~= eon_planet_registry.aquilo_connection_to_copy then
        data_util.delete_prototype("space-connection", connection_name)
    end
end
copy_nauvis_aquilo_connection_to_fulgora()
data_util.delete_prototype("space-connection", eon_planet_registry.aquilo_connection_to_copy)

local edge = data.raw["space-connection"][eon_planet_registry.edge_connection_to_clone]

if edge then
    local fulgora_edge = table.deepcopy(edge)

    fulgora_edge.name = eon_planet_registry.fulgora_edge_connection_name
    fulgora_edge.from = "fulgora"

    fulgora_edge.icons = {
        {
            icon = eon_planet_registry.edge_route_icon
        },
        {
            icon = eon_planet_registry.fulgora_icon,
            icon_size = 64,
            scale = 0.333,
            shift = { -6, -6 }
        },
        {
            icon = eon_planet_registry.solar_system_edge_icon,
            icon_size = 64,
            scale = 0.333,
            shift = { 6, 6 }
        }
    }

    data:extend({ fulgora_edge })

    data_util.delete_prototype("space-connection", eon_planet_registry.edge_connection_to_clone)
end

for _, technology_name in ipairs(eon_planet_registry.removed_discovery_technologies) do
    data_util.hide_prototype("technology", technology_name)
end

for _, control_name in ipairs(eon_planet_registry.autoplace_controls_to_hide) do
    if data.raw["autoplace-control"][control_name] then
        data.raw["autoplace-control"][control_name].hidden = true
    end
end
