local biomes = require("lib.eon-biome-registry")
local eon_autoplace_policy = require("lib.eon-autoplace-policy")
local aquilo_resource_tile_policy = {}
local aquilo_masks = biomes.get("aquilo").masks

---@param name string
---@param expression string
---@return nil
local function set_or_extend_noise_expression(name, expression)
    local existing = data.raw["noise-expression"] and data.raw["noise-expression"][name]

    if existing then
        existing.expression = expression
    else
        data:extend({
            {
                type = "noise-expression",
                name = name,
                expression = expression
            }
        })
    end
end

---@param expression string
---@return string
function aquilo_resource_tile_policy.mask_off_invalid_aquilo_resource_tiles(expression)
    return aquilo_masks.off_resource_tiles .. "(" .. expression .. ")"
end

---@param expression string
---@return boolean
function aquilo_resource_tile_policy.has_aquilo_resource_tile_mask(expression)
    return string.find(expression, aquilo_masks.off_resource_tiles .. "(", 1, true) ~= nil
        or string.find(expression, aquilo_masks.resource_tiles .. "(", 1, true) ~= nil
end

---@param resource_name string
---@param property_name string
---@return string
function aquilo_resource_tile_policy.masked_resource_property_expression_name(resource_name, property_name)
    return eon_autoplace_policy.prototype_property_expression_name(
        "eon",
        resource_name,
        "aquilo_resource_tile_safe_" .. property_name
    )
end

---@return nil
function aquilo_resource_tile_policy.apply_resource_probability_masks()
    local nauvis = data.raw.planet["nauvis"]
    local map_gen = nauvis and nauvis.map_gen_settings
    local property_names = map_gen and map_gen.property_expression_names

    for resource_name, resource in pairs(data.raw.resource or {}) do
        aquilo_resource_tile_policy.mask_resource_autoplace_off_invalid_aquilo_tiles(
            resource_name,
            resource,
            property_names
        )
    end
end

---@param resource_name string
---@param resource table
---@param property_names table<string, boolean|string|number>|nil
---@return nil
function aquilo_resource_tile_policy.mask_resource_autoplace_off_invalid_aquilo_tiles(resource_name, resource,
                                                                                      property_names)
    if not resource.autoplace then return end

    local expression = resource.autoplace.probability_expression
    if type(expression) == "string"
        and expression ~= ""
        and not aquilo_resource_tile_policy.has_aquilo_resource_tile_mask(expression)
    then
        resource.autoplace.probability_expression =
            aquilo_resource_tile_policy.mask_off_invalid_aquilo_resource_tiles(expression)
    end

    if not property_names then return end

    local property_key = "entity:" .. resource_name .. ":probability"
    local property_expression = property_names[property_key]

    if type(property_expression) ~= "string" or property_expression == "" then return end
    if aquilo_resource_tile_policy.has_aquilo_resource_tile_mask(property_expression) then return end

    local masked_name = aquilo_resource_tile_policy.masked_resource_property_expression_name(resource_name, "probability")

    set_or_extend_noise_expression(
        masked_name,
        aquilo_resource_tile_policy.mask_off_invalid_aquilo_resource_tiles(property_expression)
    )

    property_names[property_key] = masked_name
end

return aquilo_resource_tile_policy
