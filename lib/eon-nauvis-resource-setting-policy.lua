local eon_nauvis_resource_setting_policy = {}

local function nauvis_entity_settings()
    local nauvis = data.raw.planet["nauvis"]
    return nauvis
        and nauvis.map_gen_settings
        and nauvis.map_gen_settings.autoplace_settings
        and nauvis.map_gen_settings.autoplace_settings.entity
        and nauvis.map_gen_settings.autoplace_settings.entity.settings
end

function eon_nauvis_resource_setting_policy.apply_unrestricted_vulcanus_resource_boost(options)
    local nauvis_settings = nauvis_entity_settings()
    if not (options and options.enabled and nauvis_settings) then return end

    options.boost_policy.apply({
        nauvis_settings = nauvis_settings,
        resource_configs = options.resource_configs,
    })
end

function eon_nauvis_resource_setting_policy.mask_off_ammonia_ocean(options)
    local nauvis_settings = nauvis_entity_settings()
    if not (options and options.enabled and nauvis_settings) then return end

    options.ocean_policy.mask_nauvis_resource_probabilities({
        nauvis_settings = nauvis_settings,
        mask_off_ammonia_ocean = options.mask_off_ammonia_ocean,
    })
end

return eon_nauvis_resource_setting_policy
