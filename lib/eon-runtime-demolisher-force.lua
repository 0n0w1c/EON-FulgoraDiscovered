local eon_runtime_demolisher_force = {}

local DEMOLISHER_FORCE_NAME = "eon-demolishers"

local demolisher_unit_names = {
    ["small-demolisher"] = true,
    ["medium-demolisher"] = true,
    ["big-demolisher"] = true,
}

---@param segmented_unit LuaSegmentedUnit|nil
---@return boolean
local function is_demolisher(segmented_unit)
    if not segmented_unit or not segmented_unit.valid then
        return false
    end

    local prototype = segmented_unit.prototype
    if not prototype then
        return false
    end

    return demolisher_unit_names[prototype.name] == true
end

---@param force LuaForce
local function make_ceasefire_with_enemy(force)
    local enemy_force = game.forces["enemy"]
    if not (force and force.valid and enemy_force and enemy_force.valid) then return end

    force.set_cease_fire(enemy_force, true)
    enemy_force.set_cease_fire(force, true)

    force.set_friend(enemy_force, true)
    enemy_force.set_friend(force, true)
end

---@return LuaForce
local function ensure_demolisher_force()
    local force = game.forces[DEMOLISHER_FORCE_NAME]
    if not force then
        force = game.create_force(DEMOLISHER_FORCE_NAME)
    end

    make_ceasefire_with_enemy(force)

    return force
end

---@param force LuaForce|string|nil
---@return string?
local function force_name(force)
    if type(force) == "string" then
        return force
    end

    if force and force.valid then
        return force.name
    end

    return nil
end

---@param segmented_unit LuaSegmentedUnit|nil
---@param force LuaForce|string|nil
local function set_demolisher_force(segmented_unit, force)
    if not segmented_unit then return end
    if not is_demolisher(segmented_unit) then return end

    local target_force_name = force_name(force)
    if not target_force_name then return end
    if segmented_unit.force.name == target_force_name then return end

    segmented_unit.force = target_force_name
end

---@param target_force LuaForce|string
local function assign_existing_demolishers_to_force(target_force)
    for _, surface in pairs(game.surfaces) do
        if surface and surface.valid then
            for _, segmented_unit in pairs(surface.get_segmented_units()) do
                set_demolisher_force(segmented_unit, target_force)
            end
        end
    end
end

---@return nil
function eon_runtime_demolisher_force.apply()
    assign_existing_demolishers_to_force(ensure_demolisher_force())
end

---@param event EventData.on_segmented_unit_created
---@return nil
function eon_runtime_demolisher_force.on_segmented_unit_created(event)
    set_demolisher_force(event.segmented_unit, ensure_demolisher_force())
end

return eon_runtime_demolisher_force
