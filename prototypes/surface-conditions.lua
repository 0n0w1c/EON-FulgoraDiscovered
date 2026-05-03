local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value

if eon_aquilo_on_fulgora then
    local eon_aquilo_specific_names = {
        ["cryogenic-plant"] = true,
        ["fusion-generator"] = true,
        ["fusion-reactor"] = true,
        ["cryogenic-science-pack"] = true,
        ["quantum-processor"] = true,
    }

    local function eon_retarget_aquilo_surface_conditions_to_fulgora(prototype)
        if not prototype.surface_conditions then return end
        if not eon_aquilo_specific_names[prototype.name] then return end

        local updated_conditions = {}
        local converted_pressure_condition = false

        for _, condition in pairs(prototype.surface_conditions) do
            if condition.property == "pressure" then
                if not converted_pressure_condition then
                    table.insert(updated_conditions, {
                        property = "magnetic-field",
                        min = 99
                    })
                    converted_pressure_condition = true
                end
            else
                table.insert(updated_conditions, table.deepcopy(condition))
            end
        end

        if converted_pressure_condition then
            prototype.surface_conditions = updated_conditions
        end
    end

    for _, prototype_type in pairs(data.raw) do
        for _, prototype in pairs(prototype_type) do
            eon_retarget_aquilo_surface_conditions_to_fulgora(prototype)
        end
    end
end
