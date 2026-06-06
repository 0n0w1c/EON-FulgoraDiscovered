local eon_guarded_nauvis_resource_mask_policy = {}

function eon_guarded_nauvis_resource_mask_policy.apply(args)
    args = args or {}
    local resources = args.resources or {}
    local apply_resource_territory_mask = args.apply_resource_territory_mask

    if not apply_resource_territory_mask then
        return
    end

    for _, resource_name in ipairs(resources) do
        apply_resource_territory_mask(resource_name)
    end
end

return eon_guarded_nauvis_resource_mask_policy
