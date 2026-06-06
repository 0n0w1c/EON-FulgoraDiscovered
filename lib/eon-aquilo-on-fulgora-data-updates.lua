local eon_aquilo_on_fulgora_data_updates = {}

local function replace_solid_fuel_ammonia_crude_oil_with_heavy_oil()
    local recipes = data.raw["recipe"]
    local recipe = recipes and recipes["solid-fuel-from-ammonia"]

    if recipe and recipe.ingredients then
        for _, ingredient in pairs(recipe.ingredients) do
            if ingredient.type == "fluid" and ingredient.name == "crude-oil" then
                ingredient.name = "heavy-oil"
            end
        end
    end
end

local function copy_aquilo_player_effects_to_fulgora(fulgora, aquilo)
    if fulgora and aquilo then
        fulgora.player_effects = table.deepcopy(aquilo.player_effects)
        fulgora.ticks_between_player_effects = aquilo.ticks_between_player_effects
    end
end

local function copy_aquilo_surface_properties_to_fulgora(fulgora, aquilo)
    if not fulgora then
        return
    end

    if aquilo then
        local fulgora_magnetic_field = nil

        if fulgora.surface_properties then
            fulgora_magnetic_field = fulgora.surface_properties["magnetic-field"]
        end

        if aquilo.surface_properties then
            fulgora.surface_properties = table.deepcopy(aquilo.surface_properties)

            if fulgora_magnetic_field ~= nil then
                fulgora.surface_properties["magnetic-field"] = fulgora_magnetic_field
            end
        end

        fulgora.gravity_pull = aquilo.gravity_pull
    end

    fulgora.entities_require_heating = true
end

function eon_aquilo_on_fulgora_data_updates.apply()
    replace_solid_fuel_ammonia_crude_oil_with_heavy_oil()

    local planets = data.raw["planet"]
    local fulgora = planets and planets["fulgora"]
    local aquilo = planets and planets["aquilo"]

    copy_aquilo_player_effects_to_fulgora(fulgora, aquilo)
    copy_aquilo_surface_properties_to_fulgora(fulgora, aquilo)
end

return eon_aquilo_on_fulgora_data_updates
