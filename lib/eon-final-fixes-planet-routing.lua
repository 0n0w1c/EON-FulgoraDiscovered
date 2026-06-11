local eon_planet_registry = require("lib.eon-planet-registry")
local eon_space_location_routing = require("lib.eon-final-fixes-space-location-routing")

local eon_final_fixes_planet_routing = {}

---@class EonStrandedSpaceRouteEndpoint
---@field template table
---@field anchor string

---@return nil
local function eon_remove_hidden_planet_space_connections()
    local connections = data.raw["space-connection"]
    if not connections then return end

    ---@param connection table
    ---@return boolean
    local function connection_touches_removed_planet(connection)
        return connection
            and (eon_planet_registry.is_removed_planet(connection.from)
                or eon_planet_registry.is_removed_planet(connection.to))
    end

    ---@param connection table
    ---@return string?
    local function remaining_endpoint_from_removed_connection(connection)
        if eon_planet_registry.is_removed_planet(connection.from) then
            return connection.to
        end

        if eon_planet_registry.is_removed_planet(connection.to) then
            return connection.from
        end

        return nil
    end

    ---@type table<string, EonStrandedSpaceRouteEndpoint>
    local stranded_endpoints = {}
    ---@type table<string, string>
    local rerouted_endpoints = {}

    for connection_name_to_remove, connection in pairs(table.deepcopy(connections)) do
        if connection_touches_removed_planet(connection) then
            local remaining_endpoint = remaining_endpoint_from_removed_connection(connection)

            if remaining_endpoint
                and remaining_endpoint ~= eon_planet_registry.primary_remaining_planet
                and not eon_planet_registry.is_removed_planet(remaining_endpoint)
                and eon_space_location_routing.is_existing_route_endpoint(remaining_endpoint)
            then
                stranded_endpoints[remaining_endpoint] = stranded_endpoints[remaining_endpoint] or {
                    template = table.deepcopy(connection),
                    anchor = eon_space_location_routing.reroute_anchor_for_endpoint(remaining_endpoint),
                }
            end

            connections[connection_name_to_remove] = nil
        end
    end

    for endpoint_name, stranded_endpoint in pairs(stranded_endpoints) do
        local route_anchor = stranded_endpoint.anchor
        rerouted_endpoints[endpoint_name] = route_anchor

        eon_space_location_routing.create_rerouted_connection(
            connections,
            route_anchor,
            endpoint_name,
            stranded_endpoint.template
        )
    end

    eon_space_location_routing.repair_rerouted_discovery_technologies(rerouted_endpoints)
end

---@return nil
function eon_final_fixes_planet_routing.apply()
    eon_remove_hidden_planet_space_connections()
end

return eon_final_fixes_planet_routing
