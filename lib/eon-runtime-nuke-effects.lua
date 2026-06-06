local EON_NUKE_EFFECT_ID = "eon-atomic-rocket-biome-effect"
local EON_NUKE_CRATER_EFFECT_ID = "eon-atomic-rocket-nauvis-crater-effect"

---@param tile LuaTile|nil
---@return string|nil
local function eon_tile_subgroup_name(tile)
    if not (tile and tile.valid and tile.prototype and tile.prototype.subgroup) then
        return nil
    end

    return tile.prototype.subgroup.name
end

---@param effect_name string|nil
---@return boolean
local function eon_entity_prototype_exists(effect_name)
    return type(effect_name) == "string"
        and prototypes
        and prototypes.entity
        and prototypes.entity[effect_name] ~= nil
end

---@param preferred_effect string|nil
---@param fallback_effect string|nil
---@return string|nil
local function eon_existing_effect_or_fallback(preferred_effect, fallback_effect)
    if eon_entity_prototype_exists(preferred_effect) then
        return preferred_effect
    end

    if eon_entity_prototype_exists(fallback_effect) then
        return fallback_effect
    end

    return nil
end

---Chooses the biome-specific nuke effect for a surface tile.
---@param surface LuaSurface
---@param tile LuaTile|nil
---@return string|nil
local function eon_choose_nuke_effect(surface, tile)
    if surface.platform then
        return eon_existing_effect_or_fallback("nuke-effects-space", "nuke-effects-nauvis")
    end

    local subgroup_name = eon_tile_subgroup_name(tile)

    if subgroup_name == "vulcanus-tiles" then
        return eon_existing_effect_or_fallback("eon-nuke-effects-vulcanus-swapped", "nuke-effects-vulcanus")
    end

    if subgroup_name == "aquilo-tiles" then
        return eon_existing_effect_or_fallback("nuke-effects-aquilo", "nuke-effects-nauvis")
    end

    if subgroup_name == "fulgora-tiles" then
        return eon_existing_effect_or_fallback("eon-nuke-effects-fulgora", "nuke-effects-nauvis")
    end

    if type(subgroup_name) == "string" then
        local planet_name = string.match(subgroup_name, "^(.+)%-tiles$")
        local planet_effect = planet_name and ("nuke-effects-" .. planet_name) or nil
        if eon_entity_prototype_exists(planet_effect) then
            return planet_effect
        end
    end

    return eon_existing_effect_or_fallback("nuke-effects-nauvis", nil)
end

---@param surface_index uint
---@param position MapPosition
---@return string
local function eon_nuke_position_key(surface_index, position)
    return surface_index
        .. ":" .. math.floor(position.x * 100 + 0.5)
        .. ":" .. math.floor(position.y * 100 + 0.5)
end

local function eon_pending_nuke_effects()
    storage.eon_pending_nuke_effects = storage.eon_pending_nuke_effects or {}
    return storage.eon_pending_nuke_effects
end

---@param event EventData.on_script_trigger_effect
local function on_script_trigger_effect(event)
    if event.effect_id ~= EON_NUKE_EFFECT_ID and event.effect_id ~= EON_NUKE_CRATER_EFFECT_ID then return end

    local surface = game.surfaces[event.surface_index]
    if not (surface and surface.valid) then return end

    local position = event.target_position or event.source_position
    if not position then return end

    local key = eon_nuke_position_key(event.surface_index, position)

    if event.effect_id == EON_NUKE_EFFECT_ID then
        local tile = surface.get_tile(position.x, position.y)
        local effect_name = eon_choose_nuke_effect(surface, tile)
        eon_pending_nuke_effects()[key] = effect_name

        if effect_name then
            surface.create_entity({
                name = effect_name,
                position = position,
                force = "neutral",
            })
        end

        return
    end

    if event.effect_id == EON_NUKE_CRATER_EFFECT_ID then
        local effect_name = eon_pending_nuke_effects()[key]
        eon_pending_nuke_effects()[key] = nil

        if effect_name ~= "nuke-effects-nauvis" then return end

        if eon_entity_prototype_exists("eon-nuke-crater-nauvis") then
            surface.create_entity({
                name = "eon-nuke-crater-nauvis",
                position = position,
                force = "neutral",
            })
        end
    end
end

return {
    on_script_trigger_effect = on_script_trigger_effect,
}
