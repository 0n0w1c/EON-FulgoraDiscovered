local eon_planet_registry = require("lib.eon-planet-registry")

local eon_final_fixes_planet_routing = {}

local eon_repair_rerouted_planet_discovery_technologies

---@return nil
local function eon_remove_hidden_planet_space_connections()
    local connections = data.raw["space-connection"]
    if not connections then return end

    local function is_removed_planet(name)
        return eon_planet_registry.is_removed_planet(name)
    end

    local function is_existing_planet(name)
        return type(name) == "string" and data.raw.planet and data.raw.planet[name] ~= nil
    end

    local function connection_touches_planet(connection, planet_name)
        return connection and (connection.from == planet_name or connection.to == planet_name)
    end

    local function connection_touches_removed_planet(connection)
        return connection and (is_removed_planet(connection.from) or is_removed_planet(connection.to))
    end

    local function other_endpoint_from_removed_connection(connection)
        if is_removed_planet(connection.from) then
            return connection.to
        end

        if is_removed_planet(connection.to) then
            return connection.from
        end

        return nil
    end

    local function has_valid_remaining_connection(planet_name)
        for _, connection in pairs(connections) do
            if connection_touches_planet(connection, planet_name)
                and not is_removed_planet(connection.from)
                and not is_removed_planet(connection.to)
            then
                return true
            end
        end

        return false
    end

    local function has_connection_between(from_name, to_name)
        for _, connection in pairs(connections) do
            if (connection.from == from_name and connection.to == to_name)
                or (connection.from == to_name and connection.to == from_name)
            then
                return true
            end
        end

        return false
    end

    local function planet_icon_data(planet_name, shift)
        local planet = data.raw.planet and data.raw.planet[planet_name]
        if not planet then return nil end

        if planet.icon then
            return {
                icon = planet.icon,
                icon_size = planet.icon_size or 64,
                scale = 0.333,
                shift = shift,
            }
        end

        if type(planet.icons) == "table" and planet.icons[1] then
            local icon = table.deepcopy(planet.icons[1])
            icon.scale = 0.333
            icon.shift = shift
            return icon
        end

        return nil
    end

    local function connection_icons(to_planet_name)
        local icons = {
            {
                icon = eon_planet_registry.edge_route_icon,
            },
        }

        local fulgora_icon = planet_icon_data(eon_planet_registry.primary_remaining_planet, { -6, -6 })
        local to_icon = planet_icon_data(to_planet_name, { 6, 6 })

        if fulgora_icon then
            table.insert(icons, fulgora_icon)
        end

        if to_icon then
            table.insert(icons, to_icon)
        end

        return icons
    end

    local function connection_name(to_planet_name)
        local base_name = eon_planet_registry.primary_remaining_planet .. "-" .. to_planet_name
        if not connections[base_name] then
            return base_name
        end

        local index = 2
        while connections[base_name .. "-" .. index] do
            index = index + 1
        end

        return base_name .. "-" .. index
    end

    local stranded_planets = {}
    local rerouted_planets = {}

    for connection_name_to_remove, connection in pairs(table.deepcopy(connections)) do
        if connection_touches_removed_planet(connection) then
            local other_endpoint = other_endpoint_from_removed_connection(connection)

            if other_endpoint and other_endpoint ~= eon_planet_registry.primary_remaining_planet
                and not is_removed_planet(other_endpoint)
                and is_existing_planet(other_endpoint)
            then
                stranded_planets[other_endpoint] = stranded_planets[other_endpoint] or table.deepcopy(connection)
            end

            connections[connection_name_to_remove] = nil
        end
    end

    for planet_name, template in pairs(stranded_planets) do
        if not has_valid_remaining_connection(planet_name) then
            rerouted_planets[planet_name] = true

            if not has_connection_between(eon_planet_registry.primary_remaining_planet, planet_name) then
                local new_connection = table.deepcopy(template)
                new_connection.name = connection_name(planet_name)
                new_connection.from = eon_planet_registry.primary_remaining_planet
                new_connection.to = planet_name
                new_connection.icons = connection_icons(planet_name)
                new_connection.localised_name = nil
                new_connection.localised_description = nil

                data:extend({ new_connection })
            end
        end
    end

    eon_repair_rerouted_planet_discovery_technologies(rerouted_planets)
end

---@param rerouted_planets table<string, boolean>
---@return nil
eon_repair_rerouted_planet_discovery_technologies = function(rerouted_planets)
    if type(rerouted_planets) ~= "table" then return end

    local technologies = data.raw.technology
    if not technologies then return end

    local removed_discovery_prerequisites = eon_planet_registry.removed_discovery_prerequisite_set

    ---@type string?
    local replacement_prerequisite = eon_planet_registry.discovery_replacement_prerequisite
    if not technologies[replacement_prerequisite] then
        replacement_prerequisite = nil
    end

    ---@param technology table
    ---@param location_name string
    ---@return boolean
    local function unlocks_space_location(technology, location_name)
        if type(technology.effects) ~= "table" then return false end

        for _, effect in pairs(technology.effects) do
            if effect.type == "unlock-space-location" and effect.space_location == location_name then
                return true
            end
        end

        return false
    end

    ---@param prerequisites table|nil
    ---@return boolean
    local function has_prerequisite(prerequisites, prerequisite_name)
        if type(prerequisites) ~= "table" then return false end

        for _, prerequisite in pairs(prerequisites) do
            if prerequisite == prerequisite_name then
                return true
            end
        end

        return false
    end

    ---@param technology table
    ---@return nil
    local function replace_removed_discovery_prerequisites(technology)
        if type(technology.prerequisites) ~= "table" then return end

        local new_prerequisites = {}
        local removed_any = false

        for _, prerequisite in ipairs(technology.prerequisites) do
            if removed_discovery_prerequisites[prerequisite] then
                removed_any = true
            else
                table.insert(new_prerequisites, prerequisite)
            end
        end

        if not removed_any then return end

        if replacement_prerequisite
            and technology.name ~= replacement_prerequisite
            and not has_prerequisite(new_prerequisites, replacement_prerequisite)
        then
            table.insert(new_prerequisites, replacement_prerequisite)
        end

        technology.prerequisites = new_prerequisites
    end

    for planet_name, should_repair in pairs(rerouted_planets) do
        if should_repair then
            for _, technology in pairs(technologies) do
                if unlocks_space_location(technology, planet_name) then
                    replace_removed_discovery_prerequisites(technology)
                end
            end
        end
    end
end

---@return nil
function eon_final_fixes_planet_routing.apply()
    eon_remove_hidden_planet_space_connections()
end

return eon_final_fixes_planet_routing
