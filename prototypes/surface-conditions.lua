if not mods["space-age"] then return end

local eon_surface_condition_registry = require("lib.eon-surface-condition-registry")

for _, prototype_type in pairs(data.raw) do
    for _, prototype in pairs(prototype_type) do
        if prototype.surface_conditions
            and not eon_surface_condition_registry.should_keep_surface_conditions(prototype.name)
        then
            prototype.surface_conditions = nil
        end
    end
end
