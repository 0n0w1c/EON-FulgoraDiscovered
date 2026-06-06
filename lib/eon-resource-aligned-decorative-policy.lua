local resource_aligned_decorative_policy = {}

---@class EonResourceAlignedDecorativeApplyConfig
---@field guarded_resources_enabled boolean
---@field entries_by_mode table<string, EonResourceAlignedDecorativeEntry[]>
---@field mask_off_ammonia_ocean fun(expression:string):string
---@field mask_vulcanus_resource_terrain fun(expression:string):string

---@class EonResourceAlignedDecorativeEntry
---@field name string
---@field expression string

---@param decorative_name string
---@param expression string
---@param unrestricted boolean
---@param mask_off_ammonia_ocean fun(expression:string):string
---@param mask_vulcanus_resource_terrain fun(expression:string):string
---@return nil
local function set_resource_aligned_decorative_probability(
    decorative_name,
    expression,
    unrestricted,
    mask_off_ammonia_ocean,
    mask_vulcanus_resource_terrain
)
    local decorative = data.raw["optimized-decorative"] and data.raw["optimized-decorative"][decorative_name]
    if not (decorative and decorative.autoplace) then return end

    if unrestricted then
        decorative.autoplace.tile_restriction = nil
        decorative.autoplace.probability_expression = mask_off_ammonia_ocean(expression)
    else
        decorative.autoplace.probability_expression = mask_vulcanus_resource_terrain(expression)
    end
end

---@param config EonResourceAlignedDecorativeApplyConfig
---@return nil
function resource_aligned_decorative_policy.apply(config)
    local mode_name = config.guarded_resources_enabled and "guarded" or "unrestricted"
    local unrestricted = not config.guarded_resources_enabled
    local entries_by_mode = config.entries_by_mode

    local mask_off_ammonia_ocean = config.mask_off_ammonia_ocean
    local mask_vulcanus_resource_terrain = config.mask_vulcanus_resource_terrain

    for _, entry in ipairs(entries_by_mode[mode_name] or {}) do
        set_resource_aligned_decorative_probability(
            entry.name,
            entry.expression,
            unrestricted,
            mask_off_ammonia_ocean,
            mask_vulcanus_resource_terrain
        )
    end
end

return resource_aligned_decorative_policy
