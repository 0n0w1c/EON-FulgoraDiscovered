local data_util = {}

---@param type any
---@param name string
---@return nil
function data_util.hide_prototype(type, name)
    if data.raw[type][name] then
        data.raw[type][name].hidden = true
    end
end

---@param type any
---@param name string
---@return nil
function data_util.delete_prototype(type, name)
    if data.raw[type][name] then
        data.raw[type][name] = nil
    end
end

---@param name string
---@return any
function data_util.generate_eon_name(name)
    return "eon_" .. string.gsub(name, "-", "_")
end

return data_util
