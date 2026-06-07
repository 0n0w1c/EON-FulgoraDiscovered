local data_util = require("data-util")
local mode = require("lib.eon-mode")
local biomes = require("lib.eon-biome-registry")

local masks = {}

local aquilo_masks = biomes.get("aquilo").masks
local fulgora_masks = biomes.get("fulgora").masks
local gleba_masks = biomes.get("gleba").masks
local nauvis_masks = biomes.get("nauvis").masks
local vulcanus_masks = biomes.get("vulcanus").masks

local eon_aquilo_resource_tile_mask = aquilo_masks.resource_tiles
local eon_aquilo_decorative_mask = aquilo_masks.decorative_territory
local eon_aquilo_snow_decorative_mask = mode.aquilo_on_fulgora
    and "eon_identity"
    or aquilo_masks.snow_decorative_territory

local function set_probability(prototype_type, prototype_name, expression)
    local prototypes = data.raw[prototype_type]
    if not prototypes then return false, "missing prototype type " .. prototype_type end
    local prototype = prototypes[prototype_name]
    if not prototype then return false, "missing prototype " .. prototype_type .. "/" .. prototype_name end
    if not prototype.autoplace then return false, "missing autoplace " .. prototype_type .. "/" .. prototype_name end
    prototype.autoplace.probability_expression = expression
    return true
end

local function wrap(mask_name, name)
    return mask_name .. "(" .. data_util.generate_eon_name(name) .. ")"
end

local function wrap_aquilo_territory_on_fulgora(name)
    return wrap(aquilo_masks.territory_on_fulgora, name)
end

local function wrap_off_aquilo_territory_on_fulgora(name)
    return wrap(aquilo_masks.off_territory_on_fulgora, name)
end

local wrappers = {
    mask_nauvis_territory = function(name, type_name)
        return nauvis_masks.territory .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_nauvis_territory = function(name, type_name)
        return nauvis_masks.off_territory .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_resource_territory = function(name, type_name)
        return wrap(nauvis_masks.resource_territory, name)
    end,
    mask_aquilo_territory = function(name, type_name)
        local mask = type_name == "resource" and eon_aquilo_resource_tile_mask or aquilo_masks.territory
        return mask .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_aquilo_territory = function(name, type_name)
        return aquilo_masks.off_territory .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_aquilo_territory_on_fulgora = function(name, type_name)
        return wrap_aquilo_territory_on_fulgora(name)
    end,
    mask_off_aquilo_territory_on_fulgora = function(name, type_name)
        return wrap_off_aquilo_territory_on_fulgora(name)
    end,
    mask_fulgora_territory = function(name, type_name)
        return wrap(fulgora_masks.territory, name)
    end,
    mask_off_fulgora_territory = function(name, type_name)
        return wrap(fulgora_masks.off_territory, name)
    end,
    mask_fulgora_aquilo_territory = function(name, type_name)
        return wrap_aquilo_territory_on_fulgora(name)
    end,
    mask_off_fulgora_aquilo_territory = function(name, type_name)
        return wrap_off_aquilo_territory_on_fulgora(name)
    end,
    mask_ammonia_ocean = function(name, type_name)
        return wrap(aquilo_masks.ammonia_ocean, name)
    end,
    mask_aquilo_decorative_territory = function(name, type_name)
        return eon_aquilo_decorative_mask .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_aquilo_snow_decorative_territory = function(name, type_name)
        return eon_aquilo_snow_decorative_mask .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_ammonia_ocean = function(name, type_name)
        return wrap(aquilo_masks.off_ammonia_ocean, name)
    end,
    mask_gleba_territory = function(name, type_name)
        return gleba_masks.territory .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_gleba_territory = function(name, type_name)
        return gleba_masks.off_territory .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_vulcano_coverage = function(name, type_name)
        return vulcanus_masks.coverage .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_vulcano_coverage = function(name, type_name)
        return vulcanus_masks.off_coverage .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_vulcano_terrain = function(name, type_name)
        return vulcanus_masks.terrain .. "(" .. data_util.generate_eon_name(name) .. ")"
    end,
    mask_off_vulcano_terrain = function(name, type_name)
        return vulcanus_masks.off_terrain .. "(" .. data_util.generate_eon_name(name) .. ")"
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
