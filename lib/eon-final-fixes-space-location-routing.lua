local eon_planet_registry = require("lib.eon-planet-registry")

local eon_final_fixes_space_location_routing = {}

---Return a route endpoint prototype by name.
---@param endpoint_name string
---@return table?
local function route_endpoint_prototype(endpoint_name)
    if type(endpoint_name) ~= "string" then return nil end

    if data.raw.planet and data.raw.planet[endpoint_name] then
        return data.raw.planet[endpoint_name]
    end

    if data.raw["space-location"] and data.raw["space-location"][endpoint_name] then
        return data.raw["space-location"][endpoint_name]
    end

    return nil
end

---Return whether a route endpoint still exists after EON removes planets.
---@param endpoint_name string
---@return boolean
function eon_final_fixes_space_location_routing.is_existing_route_endpoint(endpoint_name)
    return route_endpoint_prototype(endpoint_name) ~= nil
end

---@param endpoint_name string
---@return boolean
local function is_planet_endpoint(endpoint_name)
    return type(endpoint_name) == "string" and data.raw.planet and data.raw.planet[endpoint_name] ~= nil
end

---@param endpoint_name string
---@return boolean
local function is_space_location_endpoint(endpoint_name)
    return type(endpoint_name) == "string"
        and data.raw["space-location"]
        and data.raw["space-location"][endpoint_name] ~= nil
end

---Return icon data for one side of an auto-created route icon.
---@param endpoint_name string
---@param shift table
---@return table?
local function endpoint_icon_data(endpoint_name, shift)
    local endpoint = route_endpoint_prototype(endpoint_name)
    if not endpoint then return nil end

    if endpoint.icon then
        return {
            icon = endpoint.icon,
            icon_size = endpoint.icon_size or 64,
            scale = 0.333,
            shift = shift,
        }
    end

    if type(endpoint.icons) == "table" and endpoint.icons[1] then
        local icon = table.deepcopy(endpoint.icons[1])
        icon.scale = 0.333
        icon.shift = shift
        return icon
    end

    return nil
end

---@param from_endpoint_name string
---@param to_endpoint_name string
---@return table
local function connection_icons(from_endpoint_name, to_endpoint_name)
    local icons = {
        {
            icon = eon_planet_registry.edge_route_icon,
        },
    }

    local from_icon = endpoint_icon_data(from_endpoint_name, { -6, -6 })
    local to_icon = endpoint_icon_data(to_endpoint_name, { 6, 6 })

    if from_icon then
        table.insert(icons, from_icon)
    end

    if to_icon then
        table.insert(icons, to_icon)
    end

    return icons
end

---@param connections table
---@param from_endpoint_name string
---@param to_endpoint_name string
---@return boolean
local function has_connection_between(connections, from_endpoint_name, to_endpoint_name)
    for _, connection in pairs(connections) do
        if (connection.from == from_endpoint_name and connection.to == to_endpoint_name)
            or (connection.from == to_endpoint_name and connection.to == from_endpoint_name)
        then
            return true
        end
    end

    return false
end

---@param connections table
---@param from_endpoint_name string
---@param to_endpoint_name string
---@return string
local function next_connection_name(connections, from_endpoint_name, to_endpoint_name)
    local base_name = from_endpoint_name .. "-" .. to_endpoint_name
    if not connections[base_name] then
        return base_name
    end

    local index = 2
    while connections[base_name .. "-" .. index] do
        index = index + 1
    end

    return base_name .. "-" .. index
end

---Choose the remaining route anchor for a stranded endpoint.
---@param endpoint_name string
---@return string
function eon_final_fixes_space_location_routing.reroute_anchor_for_endpoint(endpoint_name)
    if is_planet_endpoint(endpoint_name) then
        return eon_planet_registry.primary_remaining_planet
    end

    local endpoint = route_endpoint_prototype(endpoint_name)
    local fulgora = route_endpoint_prototype(eon_planet_registry.primary_remaining_planet)

    if endpoint and fulgora
        and type(endpoint.distance) == "number"
        and type(fulgora.distance) == "number"
        and endpoint.distance < fulgora.distance
        and eon_final_fixes_space_location_routing.is_existing_route_endpoint("nauvis")
    then
        return "nauvis"
    end

    return eon_planet_registry.primary_remaining_planet
end

---Create a replacement connection for a route endpoint stranded by planet removal.
---@param connections table
---@param route_anchor string
---@param endpoint_name string
---@param template table
---@return nil
function eon_final_fixes_space_location_routing.create_rerouted_connection(connections, route_anchor, endpoint_name,
                                                                           template)
    if not (route_anchor and endpoint_name and template) then return end
    if route_anchor == endpoint_name then return end
    if not eon_final_fixes_space_location_routing.is_existing_route_endpoint(route_anchor) then return end
    if not eon_final_fixes_space_location_routing.is_existing_route_endpoint(endpoint_name) then return end
    if has_connection_between(connections, route_anchor, endpoint_name) then return end

    local new_connection = table.deepcopy(template)
    new_connection.name = next_connection_name(connections, route_anchor, endpoint_name)
    new_connection.from = route_anchor
    new_connection.to = endpoint_name
    new_connection.icons = connection_icons(route_anchor, endpoint_name)
    new_connection.localised_name = nil
    new_connection.localised_description = nil

    data:extend({ new_connection })
end

---Replace discovery prerequisites that pointed at EON-removed planets.
---@param rerouted_endpoints table<string, string>
---@return nil
function eon_final_fixes_space_location_routing.repair_rerouted_discovery_technologies(rerouted_endpoints)
    if type(rerouted_endpoints) ~= "table" then return end

    local technologies = data.raw.technology
    if not technologies then return end

    local removed_discovery_prerequisites = eon_planet_registry.removed_discovery_prerequisite_set

    ---@param endpoint_name string
    ---@return string?
    local function replacement_prerequisite_for_endpoint(endpoint_name)
        if is_space_location_endpoint(endpoint_name) then
            if technologies["space-science-pack"] then
                return "space-science-pack"
            end

            return nil
        end

        local replacement_prerequisite = eon_planet_registry.discovery_replacement_prerequisite
        if technologies[replacement_prerequisite] then
            return replacement_prerequisite
        end

        return nil
    end

    ---@param technology table
    ---@param endpoint_name string
    ---@return boolean
    local function unlocks_space_location(technology, endpoint_name)
        if type(technology.effects) ~= "table" then return false end

        for _, effect in pairs(technology.effects) do
            if effect.type == "unlock-space-location" and effect.space_location == endpoint_name then
                return true
            end
        end

        return false
    end

    ---@param prerequisites table|nil
    ---@param prerequisite_name string
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
    ---@param replacement_prerequisite string?
    ---@return nil
    local function replace_removed_discovery_prerequisites(technology, replacement_prerequisite)
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

    for endpoint_name in pairs(rerouted_endpoints) do
        local replacement_prerequisite = replacement_prerequisite_for_endpoint(endpoint_name)

        for _, technology in pairs(technologies) do
            if unlocks_space_location(technology, endpoint_name) then
                replace_removed_discovery_prerequisites(technology, replacement_prerequisite)
            end
        end
    end
end

return eon_final_fixes_space_location_routing
