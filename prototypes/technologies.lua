local technologies = data.raw["technology"]
local eon_technology_registry = require("lib.eon-technology-registry")

---@param value any
---@return any
local function eon_deepcopy(value)
    if type(value) ~= "table" then return value end

    local copy = {}
    for key, child in pairs(value) do
        copy[eon_deepcopy(key)] = eon_deepcopy(child)
    end
    return copy
end

data:extend({ eon_deepcopy(eon_technology_registry.solar_system_edge_discovery) })

for technology_name, prerequisites in pairs(eon_technology_registry.prerequisites_to_append) do
    local technology = technologies[technology_name]
    if technology then
        technology.prerequisites = technology.prerequisites or {}
        for _, prerequisite in ipairs(prerequisites) do
            table.insert(technology.prerequisites, prerequisite)
        end
    end
end

for technology_name, prerequisites in pairs(eon_technology_registry.prerequisite_replacements) do
    local technology = technologies[technology_name]
    if technology then
        technology.prerequisites = eon_deepcopy(prerequisites)
    end
end

for technology_name, patch in pairs(eon_technology_registry.unit_replacements) do
    local technology = technologies[technology_name]
    if technology then
        technology.prerequisites = eon_deepcopy(patch.prerequisites)
        if patch.research_trigger == false then
            technology.research_trigger = nil
        else
            technology.research_trigger = eon_deepcopy(patch.research_trigger)
        end
        technology.unit = eon_deepcopy(patch.unit)
    end
end
