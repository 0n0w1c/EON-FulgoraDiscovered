if not mods["space-age"] then return end

local eon_surface_condition_registry = require("lib.eon-surface-condition-registry")

local preserve_planet_surface_conditions_setting =
    settings.startup["eon-fd-preserve-planet-surface-conditions"]

local preserve_planet_surface_conditions =
    preserve_planet_surface_conditions_setting
    and preserve_planet_surface_conditions_setting.value

local preserve_aquilo_surface_conditions_setting =
    settings.startup["eon-fd-aquilo-on-fulgora"]

local preserve_aquilo_surface_conditions =
    preserve_planet_surface_conditions
    and preserve_aquilo_surface_conditions_setting
    and preserve_aquilo_surface_conditions_setting.value

local FULGORA_MAGNETIC_FIELD = 99
local AQUILO_SURFACE_CONDITION_PROPERTY = "pressure"
local AQUILO_SURFACE_CONDITION_MIN = 100
local AQUILO_SURFACE_CONDITION_MAX = 600

local function has_fulgora_magnetic_field_condition(surface_conditions)
    if not preserve_planet_surface_conditions then
        return false
    end

    if type(surface_conditions) ~= "table" then
        return false
    end

    for _, condition in pairs(surface_conditions) do
        if condition and condition.property == "magnetic-field" then
            -- Fulgora-only restrictions, for example:
            -- { property = "magnetic-field", min = 99 }
            if condition.min and condition.min >= FULGORA_MAGNETIC_FIELD then
                return true
            end

            -- Not-on-Fulgora restrictions, for example:
            -- { property = "magnetic-field", max = 90 }
            -- or the more precise { property = "magnetic-field", max = 98 }.
            if condition.max and condition.max < FULGORA_MAGNETIC_FIELD then
                return true
            end
        end
    end

    return false
end

local function has_aquilo_pressure_condition(surface_conditions)
    if not preserve_aquilo_surface_conditions then
        return false
    end

    if type(surface_conditions) ~= "table" then
        return false
    end

    for _, condition in pairs(surface_conditions) do
        if condition
            and condition.property == AQUILO_SURFACE_CONDITION_PROPERTY
            and condition.min == AQUILO_SURFACE_CONDITION_MIN
            and condition.max == AQUILO_SURFACE_CONDITION_MAX
        then
            -- This is the same Aquilo crafting surface condition used by the
            -- Space Age cryogenic-plant recipe in data.raw:
            -- { property = "pressure", min = 100, max = 600 }
            -- When EON moves the Aquilo biome to Fulgora, preserve matching
            -- recipe/entity surface restrictions instead of stripping them.
            return true
        end
    end

    return false
end

local function should_preserve_surface_conditions(surface_conditions)
    return has_fulgora_magnetic_field_condition(surface_conditions)
        or has_aquilo_pressure_condition(surface_conditions)
end

for _, prototype_type in pairs(data.raw) do
    for _, prototype in pairs(prototype_type) do
        -- Applies to every prototype type in data.raw. In Space Age this includes
        -- RecipePrototype.surface_conditions, which restrict crafting, and
        -- EntityPrototype.surface_conditions, which restrict placement.
        if prototype.surface_conditions
            and not eon_surface_condition_registry.should_keep_surface_conditions(prototype.name)
            and not should_preserve_surface_conditions(prototype.surface_conditions)
        then
            prototype.surface_conditions = nil
        end
    end
end
