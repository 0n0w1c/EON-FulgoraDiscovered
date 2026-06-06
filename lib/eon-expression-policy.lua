local eon_expression_policy = {}

---@param expression string
---@param wrapper_name string
---@return string
function eon_expression_policy.wrap(expression, wrapper_name)
    return wrapper_name .. "(" .. expression .. ")"
end

---@param expressions string[]
---@return string|nil expression
function eon_expression_policy.combine_max(expressions)
    if #expressions == 0 then return nil end
    if #expressions == 1 then return expressions[1] end
    return "max(" .. table.concat(expressions, ", ") .. ")"
end

---@param expressions string[]
---@param expression string
---@param wrapper_name string
---@return nil
function eon_expression_policy.add_wrapped(expressions, expression, wrapper_name)
    table.insert(expressions, eon_expression_policy.wrap(expression, wrapper_name))
end

---@param value string
---@return string
function eon_expression_policy.sanitized_identifier(value)
    return (tostring(value):gsub("[^%w_]", "_"))
end

---@param prefix string
---@param prototype_name string
---@param property_name string
---@return string
function eon_expression_policy.prototype_property_expression_name(prefix, prototype_name, property_name)
    return prefix .. "_" .. eon_expression_policy.sanitized_identifier(prototype_name) .. "_" .. property_name
end

---@param control_name string
---@param property_name string
---@return string
function eon_expression_policy.control_variable(control_name, property_name)
    return "var('control:" .. control_name .. ":" .. property_name .. "')"
end

---@param base_expression string
---@param mask_name string
---@param additive_expression string
---@return string
function eon_expression_policy.max_with_masked(base_expression, mask_name, additive_expression)
    return "max(" .. base_expression .. ", " .. eon_expression_policy.wrap(additive_expression, mask_name) .. ")"
end

---@param config table Resource patch config containing the vanilla resource_autoplace_all_patches parameters.
---@return string
function eon_expression_policy.resource_autoplace_all_patches(config)
    return "resource_autoplace_all_patches{base_density = " .. config.base_density ..
        ", base_spots_per_km2 = " .. config.base_spots_per_km2 ..
        ", candidate_spot_count = " .. config.candidate_spot_count ..
        ", frequency_multiplier = " .. eon_expression_policy.control_variable(config.control, "frequency") ..
        ", has_starting_area_placement = 0" ..
        ", random_spot_size_minimum = " .. config.random_spot_size_minimum ..
        ", random_spot_size_maximum = " .. config.random_spot_size_maximum ..
        ", regular_blob_amplitude_multiplier = 0.125" ..
        ", regular_patch_set_count = default_regular_resource_patch_set_count" ..
        ", regular_patch_set_index = " .. config.regular_patch_set_index ..
        ", regular_rq_factor = " .. config.regular_rq_factor ..
        ", seed1 = " .. config.seed ..
        ", size_multiplier = " ..
        eon_expression_policy.control_variable(config.control, "size") .. " * " .. config.size_multiplier ..
        ", starting_blob_amplitude_multiplier = 0.125" ..
        ", starting_patch_set_count = default_starting_resource_patch_set_count" ..
        ", starting_patch_set_index = 0" ..
        ", starting_rq_factor = " .. config.starting_rq .. "}"
end

---@param config table
---@param patches_name string
---@return string
function eon_expression_policy.resource_probability_from_patches(config, patches_name)
    local probability = "(" ..
        eon_expression_policy.control_variable(config.control, "size") .. " > 0) * clamp(" .. patches_name .. ", 0, 1)"

    if config.fluid then
        probability = probability .. " * random_penalty{x = x, y = y, source = 1, amplitude = 1 / 0.020833333333333}"
    end

    return probability
end

---@param config table
---@param patches_name string
---@return string
function eon_expression_policy.resource_richness_from_patches(config, patches_name)
    local size = eon_expression_policy.control_variable(config.control, "size")
    local richness = eon_expression_policy.control_variable(config.control, "richness")

    if config.fluid then
        return "(" .. size .. " > 0) * " .. richness .. " * (" ..
            patches_name .. " / 0.020833333333333 + 220000) * max((1000 + distance) / 2600, 1)"
    end

    return "(" .. size .. " > 0) * " .. richness .. " * " ..
        config.richness .. " * " .. patches_name .. " * max((1000 + distance) / 2600, 1)"
end

return eon_expression_policy
