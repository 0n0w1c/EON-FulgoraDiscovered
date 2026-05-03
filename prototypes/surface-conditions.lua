if not mods["space-age"] then return end

local ore_ganizer = mods["ore-ganizer"]

local function eon_keep_surface_conditions(name)
    if ore_ganizer and name and string.sub(name, 1, 4) == "rmd-" then
        return true
    end
    return false
end

for _, prototype_type in pairs(data.raw) do
    for _, prototype in pairs(prototype_type) do
        if prototype.surface_conditions then
            if not eon_keep_surface_conditions(prototype.name) then
                prototype.surface_conditions = nil
            end
        end
    end
end
