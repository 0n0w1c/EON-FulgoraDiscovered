local function should_keep_surface_conditions(surface_conditions)
    for _, condition in pairs(surface_conditions) do
        if condition.property == "magnetic-field" and condition.min ~= nil and condition.min >= 99 then
            return true
        end
    end

    return false
end

-- Remove surface conditions for everything except prototypes that explicitly
-- require magnetic-field >= 99.
for _, prototype_type in pairs(data.raw) do
    for _, prototype in pairs(prototype_type) do
        if prototype.surface_conditions and not should_keep_surface_conditions(prototype.surface_conditions) then
            prototype.surface_conditions = nil
        end
    end
end
