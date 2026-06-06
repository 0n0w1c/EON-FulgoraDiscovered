local registry = {}

registry.keep_mods = {
    ["ore-ganizer"] = true,
}

registry.keep_name_prefixes_by_mod = {
    ["ore-ganizer"] = {
        "rmd-",
    },
}

---@param name string|nil
---@return boolean
function registry.should_keep_surface_conditions(name)
    if type(name) ~= "string" then return false end

    for mod_name, enabled in pairs(registry.keep_mods) do
        if enabled and mods[mod_name] then
            for _, prefix in ipairs(registry.keep_name_prefixes_by_mod[mod_name] or {}) do
                if string.sub(name, 1, #prefix) == prefix then
                    return true
                end
            end
        end
    end

    return false
end

return registry
