local technologies = data.raw["technology"]
local eon_mode = require("lib.eon-mode")
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

local function eon_has_prerequisite(prerequisites, prerequisite_name)
    if type(prerequisites) ~= "table" then return false end

    for _, prerequisite in ipairs(prerequisites) do
        if prerequisite == prerequisite_name then
            return true
        end
    end

    return false
end

local function eon_append_prerequisites(prerequisites_to_append)
    for technology_name, prerequisites in pairs(prerequisites_to_append) do
        local technology = technologies[technology_name]
        if technology then
            technology.prerequisites = technology.prerequisites or {}
            for _, prerequisite in ipairs(prerequisites) do
                if not eon_has_prerequisite(technology.prerequisites, prerequisite) then
                    table.insert(technology.prerequisites, prerequisite)
                end
            end
        end
    end
end

local function eon_replace_removed_discovery_prerequisites(replacement_prerequisite)
    if type(replacement_prerequisite) ~= "string" or replacement_prerequisite == "" then return end

    local removed_discovery_prerequisites = {
        ["planet-discovery-aquilo"] = true,
        ["planet-discovery-gleba"] = true,
        ["planet-discovery-vulcanus"] = true,
    }

    for _, technology in pairs(technologies or {}) do
        if type(technology.prerequisites) == "table" then
            local new_prerequisites = {}
            local removed_any = false

            for _, prerequisite in ipairs(technology.prerequisites) do
                if removed_discovery_prerequisites[prerequisite] then
                    removed_any = true
                else
                    table.insert(new_prerequisites, prerequisite)
                end
            end

            if removed_any then
                if technology.name ~= replacement_prerequisite
                    and not eon_has_prerequisite(new_prerequisites, replacement_prerequisite)
                then
                    table.insert(new_prerequisites, replacement_prerequisite)
                end

                technology.prerequisites = new_prerequisites
            end
        end
    end
end

eon_append_prerequisites(eon_technology_registry.prerequisites_to_append)

if eon_mode.enable_technology_guard then
    eon_replace_removed_discovery_prerequisites(
        eon_technology_registry.technology_guard.removed_discovery_prerequisite_replacement
    )
    eon_append_prerequisites(eon_technology_registry.technology_guard.prerequisites_to_append)
else
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
end
