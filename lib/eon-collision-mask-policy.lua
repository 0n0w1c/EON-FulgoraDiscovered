local eon_collision_mask_policy = {}

---@param mask table|nil Collision mask table from a prototype, if present.
---@param layer string Collision layer name to test.
---@return boolean has_layer True when the layer is present and enabled.
function eon_collision_mask_policy.has_layer(mask, layer)
    if type(mask) ~= "table" then return false end

    if type(mask.layers) == "table" then
        return mask.layers[layer] == true
    end

    for _, mask_layer in pairs(mask) do
        if mask_layer == layer then return true end
    end

    return false
end

---@param proto table|nil Prototype with a collision_mask field.
---@param layer string Collision layer to add.
---@return boolean changed True when the layer was newly added.
function eon_collision_mask_policy.add_layer(proto, layer)
    if type(proto) ~= "table" or type(layer) ~= "string" then return false end

    proto.collision_mask = proto.collision_mask or { layers = {} }

    if type(proto.collision_mask.layers) ~= "table" then
        local converted = { layers = {} }
        for _, mask_layer in pairs(proto.collision_mask) do
            if type(mask_layer) == "string" then
                converted.layers[mask_layer] = true
            end
        end
        proto.collision_mask = converted
    end

    if proto.collision_mask.layers[layer] == true then return false end
    proto.collision_mask.layers[layer] = true
    return true
end

---@param layers string[]
---@return table collision_mask
function eon_collision_mask_policy.make(layers)
    local mask = { layers = {} }
    for _, layer in ipairs(layers or {}) do
        mask.layers[layer] = true
    end
    return mask
end

return eon_collision_mask_policy
