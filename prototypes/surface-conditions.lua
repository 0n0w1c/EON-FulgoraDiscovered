local aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value

local AQUILO_PRESSURE = 300

local function is_fulgora_magnetic_condition(condition)
    return condition.property == "magnetic-field"
        and condition.min ~= nil
        and condition.min >= 99
end

local function pressure_condition_allows(condition, pressure)
    if condition.property ~= "pressure" then return false end

    local minimum = condition.min or -math.huge
    local maximum = condition.max or math.huge

    return minimum <= pressure and pressure <= maximum
end

local function is_aquilo_pressure_condition(condition)
    return pressure_condition_allows(condition, AQUILO_PRESSURE)
end

local function fulgora_surface_condition()
    return {
        property = "magnetic-field",
        min = 99
    }
end

local function normalize_surface_conditions(surface_conditions)
    local normalized = {}
    local has_fulgora_condition = false

    for _, condition in pairs(surface_conditions) do
        if is_fulgora_magnetic_condition(condition) then
            table.insert(normalized, table.deepcopy(condition))
            has_fulgora_condition = true
        elseif aquilo_on_fulgora and is_aquilo_pressure_condition(condition) then
            if not has_fulgora_condition then
                table.insert(normalized, fulgora_surface_condition())
                has_fulgora_condition = true
            end
        end
    end

    if #normalized > 0 then
        return normalized
    end

    return nil
end

for _, prototype_type in pairs(data.raw) do
    for _, prototype in pairs(prototype_type) do
        if prototype.surface_conditions then
            prototype.surface_conditions = normalize_surface_conditions(prototype.surface_conditions)
        end
    end
end
