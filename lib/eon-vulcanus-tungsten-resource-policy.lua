---@class EonTungstenGuardedPolicy
---@field resource_name string
---@field probability string
---@field richness string|number
---@field region_expression string

---@class EonTungstenGuardedResourceProbabilityConfig
---@field resource_name string
---@field probability string
---@field mask_off_aquilo_territory fun(expression:string):string
---@field mask_off_ammonia_ocean fun(expression:string):string
---@field mask_vulcanus_coverage fun(expression:string):string

---@class EonTungstenConfigureConfig
---@field guarded_resources_enabled boolean
---@field guarded_policy EonTungstenGuardedPolicy
---@field tungsten_richness_expression string
---@field mask_off_aquilo_territory fun(expression:string):string
---@field mask_off_ammonia_ocean fun(expression:string):string
---@field mask_vulcanus_coverage fun(expression:string):string
---@field apply_resource_territory_mask fun(resource_name:string)

local tungsten_policy = {}

---@param resource_name string
---@param expression string
---@return nil
local function set_resource_probability(resource_name, expression)
    data.raw.resource[resource_name].autoplace.probability_expression = expression
end

---@param expression string
---@param mask_off_aquilo_territory fun(expression:string):string
---@param mask_off_ammonia_ocean fun(expression:string):string
---@param mask_vulcanus_coverage fun(expression:string):string
---@return string
local function guarded_probability_expression(
    expression,
    mask_off_aquilo_territory,
    mask_off_ammonia_ocean,
    mask_vulcanus_coverage
)
    return mask_off_aquilo_territory(mask_off_ammonia_ocean(mask_vulcanus_coverage(expression)))
end

---@param config EonTungstenGuardedResourceProbabilityConfig
---@return nil
function tungsten_policy.set_guarded_resource_probability(config)
    local resource_name = config.resource_name
    local probability = config.probability

    ---@type fun(expression:string):string
    local mask_off_aquilo_territory = config.mask_off_aquilo_territory

    ---@type fun(expression:string):string
    local mask_off_ammonia_ocean = config.mask_off_ammonia_ocean

    ---@type fun(expression:string):string
    local mask_vulcanus_coverage = config.mask_vulcanus_coverage

    set_resource_probability(resource_name, guarded_probability_expression(
        probability,
        mask_off_aquilo_territory,
        mask_off_ammonia_ocean,
        mask_vulcanus_coverage
    ))
end

---@param config EonTungstenConfigureConfig
---@return nil
function tungsten_policy.configure(config)
    ---@type fun(expression:string):string
    local mask_off_aquilo_territory = config.mask_off_aquilo_territory

    ---@type fun(expression:string):string
    local mask_off_ammonia_ocean = config.mask_off_ammonia_ocean

    ---@type fun(expression:string):string
    local mask_vulcanus_coverage = config.mask_vulcanus_coverage

    if config.guarded_resources_enabled then
        local tungsten = config.guarded_policy

        tungsten_policy.set_guarded_resource_probability({
            resource_name = tungsten.resource_name,
            probability = tungsten.probability,
            mask_off_aquilo_territory = mask_off_aquilo_territory,
            mask_off_ammonia_ocean = mask_off_ammonia_ocean,
            mask_vulcanus_coverage = mask_vulcanus_coverage,
        })

        data.raw.resource[tungsten.resource_name].autoplace.richness_expression =
            string.format(config.tungsten_richness_expression, tungsten.richness)

        data.raw["noise-expression"]["vulcanus_tungsten_ore_region"].expression = tungsten.region_expression
    else
        data.raw["noise-expression"]["vulcanus_tungsten_ore_probability"].expression =
            mask_off_aquilo_territory(mask_off_ammonia_ocean(
                "(control:tungsten_ore:size > 0) * (1000 * ((0.7 + vulcanus_tungsten_ore_region) * random_penalty_between(0.9, 1, 1) - 1))"
            ))

        config.apply_resource_territory_mask("tungsten-ore")
    end
end

return tungsten_policy
