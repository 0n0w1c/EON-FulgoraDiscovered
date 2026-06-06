local noise_expressions = {}

---@param value any
---@return table<string, string>?
function noise_expressions.normalize_local_expressions(value)
    if type(value) ~= "table" then
        return nil
    end

    local local_expressions = {}

    for name, expression in pairs(value) do
        if type(name) == "string" and type(expression) == "string" then
            local_expressions[name] = expression
        end
    end

    return next(local_expressions) and local_expressions or nil
end

---@param name string
---@param expression string
---@param local_expressions table<string, string>?
---@return nil
function noise_expressions.set_or_extend(name, expression, local_expressions)
    local noise_expression = data.raw["noise-expression"] and data.raw["noise-expression"][name]

    if noise_expression then
        noise_expression.expression = expression
        noise_expression.local_expressions = local_expressions
        return
    end

    data:extend({
        {
            type = "noise-expression",
            name = name,
            expression = expression,
            local_expressions = local_expressions,
        }
    })
end

return noise_expressions
