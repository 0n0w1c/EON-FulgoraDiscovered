local data_util = require("data-util")
local mode = require("lib.eon-mode")

local masks = {}

local eon_aquilo_resource_tile_mask = "eon_mask_aquilo_resource_tiles"
local eon_aquilo_decorative_mask = "eon_mask_aquilo_territory"
local eon_aquilo_snow_decorative_mask = mode.aquilo_on_fulgora
    and "eon_identity"
    or "eon_mask_aquilo_territory"

local function set_probability(prototype_type, prototype_name, expression)
    local prototypes = data.raw[prototype_type]
    if not prototypes then return false, "missing prototype type " .. prototype_type end
    local prototype = prototypes[prototype_name]
    if not prototype then return false, "missing prototype " .. prototype_type .. "/" .. prototype_name end
    if not prototype.autoplace then return false, "missing autoplace " .. prototype_type .. "/" .. prototype_name end
    prototype.autoplace.probability_expression = expression
    return true
end

local wrappers = {
    mask_nauvis_territory = function(name, type_name)
        return "eon_mask_nauvis_territory(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_nauvis_territory = function(name, type_name)
        return "eon_mask_off_nauvis_territory(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_resource_territory = function(name, type_name)
        return "eon_mask_resource_territory(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_aquilo_territory = function(name, type_name)
        local mask = type_name == "resource" and eon_aquilo_resource_tile_mask or "eon_mask_aquilo_territory"
        return mask .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_aquilo_territory = function(name, type_name)
        return "eon_mask_off_aquilo_territory(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_fulgora_aquilo_territory = function(name, type_name)
        return "eon_mask_fulgora_aquilo_territory(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_fulgora_aquilo_territory = function(name, type_name)
        return "eon_mask_off_fulgora_aquilo_territory(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_ammonia_ocean = function(name, type_name)
        return "eon_mask_ammonia_ocean(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_aquilo_decorative_territory = function(name, type_name)
        return eon_aquilo_decorative_mask .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_aquilo_snow_decorative_territory = function(name, type_name)
        return eon_aquilo_snow_decorative_mask .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_ammonia_ocean = function(name, type_name)
        return "eon_mask_off_ammonia_ocean(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_gleba_territory = function(name, type_name)
        return "eon_mask_gleba_territory(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_gleba_territory = function(name, type_name)
        return "eon_mask_off_gleba_territory(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_vulcano_coverage = function(name, type_name)
        return "eon_mask_vulcano_coverage(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_vulcano_coverage = function(name, type_name)
        return "eon_mask_off_vulcano_coverage(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_vulcano_terrain = function(name, type_name)
        return "eon_mask_vulcano_terrain(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_vulcano_terrain = function(name, type_name)
        return "eon_mask_off_vulcano_terrain(" .. data_util.generate_eon_name(name) .. ")"
    end,
}

function masks.apply(policy_name, prototype_type, prototype_name)
    local wrapper = wrappers[policy_name]
    if not wrapper then error("Unknown EON autoplace mask policy: " .. tostring(policy_name)) end
    return set_probability(prototype_type, prototype_name, wrapper(prototype_name, prototype_type))
end

---@param policy_name string
---@param by_type table<string, string[]>
---@param allowed_types table<string, boolean>|nil
---@return table
function masks.apply_group(policy_name, by_type, allowed_types)
    local missing = {}
    if not by_type then return missing end

    for prototype_type, names in pairs(by_type) do
        if not allowed_types or allowed_types[prototype_type] then
            for _, prototype_name in ipairs(names) do
                local ok, err = masks.apply(policy_name, prototype_type, prototype_name)
                if not ok then table.insert(missing, err) end
            end
        end
    end

    return missing
end

---@param manifest table
---@param policy_name string
---@param allowed_types table<string, boolean>|nil
---@return table
function masks.apply_policy(manifest, policy_name, allowed_types)
    return masks.apply_group(policy_name, manifest and manifest[policy_name], allowed_types)
end

---@param manifest table
---@param policy_names string[]
---@param allowed_types table<string, boolean>|nil
---@return table
function masks.apply_policies(manifest, policy_names, allowed_types)
    local missing = {}
    for _, policy_name in ipairs(policy_names) do
        for _, err in ipairs(masks.apply_policy(manifest, policy_name, allowed_types)) do
            table.insert(missing, err)
        end
    end
    return missing
end

function masks.apply_manifest(manifest)
    local missing = {}
    for policy_name, by_type in pairs(manifest) do
        for prototype_type, names in pairs(by_type) do
            for _, prototype_name in ipairs(names) do
                local ok, err = masks.apply(policy_name, prototype_type, prototype_name)
                if not ok then table.insert(missing, err) end
            end
        end
    end
    return missing
end

return masks
