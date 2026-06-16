local registry = {}

registry.removed_planets = {
    "vulcanus",
    "aquilo",
    "gleba",
}

registry.removed_planet_set = {
    vulcanus = true,
    aquilo = true,
    gleba = true,
}

registry.primary_remaining_planet = "fulgora"
registry.discovery_replacement_prerequisite = "planet-discovery-fulgora"

registry.removed_discovery_technologies = {
    "planet-discovery-aquilo",
    "planet-discovery-gleba",
    "planet-discovery-vulcanus",
}

registry.removed_discovery_prerequisite_set = {
    ["planet-discovery-aquilo"] = true,
    ["planet-discovery-gleba"] = true,
    ["planet-discovery-vulcanus"] = true,
}

registry.space_connections_to_delete = {
    "nauvis-vulcanus",
    "nauvis-gleba",
    "vulcanus-gleba",
    "gleba-aquilo",
    "gleba-fulgora",
    "fulgora-aquilo",
}

registry.aquilo_connection_to_copy = "fulgora-aquilo"
registry.nauvis_fulgora_connection = "nauvis-fulgora"
registry.edge_connection_to_clone = "aquilo-solar-system-edge"
registry.fulgora_edge_connection_name = "fulgora-solar-system-edge"
registry.edge_route_icon = "__space-age__/graphics/icons/planet-route.png"
registry.fulgora_icon = "__space-age__/graphics/icons/fulgora.png"
registry.solar_system_edge_icon = "__space-age__/graphics/icons/solar-system-edge.png"

registry.autoplace_controls_to_hide = {
    "aquilo_crude_oil",
    "gleba_stone",
    "gleba_cliff",
    "vulcanus_coal",
}

---@param name string
---@return boolean
function registry.is_removed_planet(name)
    return type(name) == "string" and registry.removed_planet_set[name] == true
end

return registry
