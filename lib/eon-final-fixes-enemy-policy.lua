local eon_mode = require("lib.eon-mode")
local eon_autoplace_policy = require("lib.eon-autoplace-policy")
local eon_enemy_registry = require("lib.eon-enemy-registry")
local eon_tile_registry = require("lib.eon-tile-registry")

local eon_final_fixes_enemy_policy = {}

local eon_enemy_autoplace_policy = eon_tile_registry.enemy_autoplace
local eon_commander_enemy_collision_mask = eon_autoplace_policy.make_collision_mask(
    eon_enemy_autoplace_policy.commander_collision_layers
)
local eon_gleba_wetland_spawner_tiles = eon_enemy_autoplace_policy.gleba_wetland_spawner_tiles

---@type string[]
local eon_land_spawner_tiles = eon_autoplace_policy.collect_solid_land_tile_names()

---@param proto table|nil Candidate unit-spawner or turret prototype.
---@return boolean is_candidate True when the prototype has an autoplace control.
local function eon_is_autoplaced_enemy_candidate(proto)
    return proto ~= nil
        and proto.autoplace ~= nil
        and proto.autoplace.control ~= nil
end

---@param proto table Unit-spawner or turret prototype to adjust in-place.
---@return nil
local function eon_normalize_autoplaced_enemy_candidate(proto)
    if not eon_is_autoplaced_enemy_candidate(proto) then return end

    proto.collision_mask = table.deepcopy(eon_commander_enemy_collision_mask)

    if proto.name == "gleba-spawner" or proto.name == "gleba-spawner-small" then
        eon_autoplace_policy.set_autoplace_tile_restriction(proto, eon_gleba_wetland_spawner_tiles)
        return
    end

    eon_autoplace_policy.set_autoplace_tile_restriction(proto, eon_land_spawner_tiles)
end

---@param prototype_type string
---@param prototype_name string
---@return boolean
local function eon_is_cold_biter_enemy_prototype(prototype_type, prototype_name)
    return eon_enemy_registry.is_cold_biter_prototype(prototype_type, prototype_name)
end

local eon_fulgora_oil_ocean_group = eon_tile_registry.water_exclusion.fulgora_enemy_group

---@param proto table|nil Candidate spawner or worm prototype.
---@return boolean changed True when the tile restriction was changed.
local function eon_exclude_fulgora_oil_ocean_from_autoplace(proto)
    return eon_autoplace_policy.exclude_water_like_tiles_from_existing_restriction(
        proto,
        eon_land_spawner_tiles,
        eon_fulgora_oil_ocean_group
    )
end

---@return nil
local function eon_normalize_autoplaced_enemy_candidates()
    for _, prototype_type in pairs(eon_enemy_registry.final_fixes.base_autoplace_types) do
        for _, proto in pairs(data.raw[prototype_type] or {}) do
            eon_normalize_autoplaced_enemy_candidate(proto)
        end
    end
end

---@param spawner table|nil
---@param unit_name string
---@return table|nil
local function eon_get_result_unit_points(spawner, unit_name)
    if not (spawner and spawner.result_units) then return nil end

    for _, result_unit in pairs(spawner.result_units) do
        if result_unit[1] == unit_name then
            return result_unit[2]
        end
    end

    return nil
end

---@param result_units table[]|nil
---@param unit_points_by_name table
---@return nil
local function eon_apply_nauvis_evolution_to_pentapods(result_units, unit_points_by_name)
    if not result_units then return end

    for _, result_unit in pairs(result_units) do
        local unit_name = result_unit[1]
        local points = unit_points_by_name[unit_name]
        if points then
            result_unit[2] = table.deepcopy(points)
        end
    end
end

---@return nil
local function eon_align_nauvis_pentapod_evolution()
    local spawners = data.raw["unit-spawner"]
    if not spawners then return end

    local biter_spawner = spawners["biter-spawner"]

    local biter_small = eon_get_result_unit_points(biter_spawner, "small-biter")
    local biter_medium = eon_get_result_unit_points(biter_spawner, "medium-biter")
    local biter_big = eon_get_result_unit_points(biter_spawner, "big-biter")

    if not (biter_small and biter_medium and biter_big) then return end

    local unit_points_by_name = {
        ["small-wriggler-pentapod"] = biter_small,
        ["medium-wriggler-pentapod"] = biter_medium,
        ["big-wriggler-pentapod"] = biter_big,

        ["small-stomper-pentapod"] = biter_small,
        ["medium-stomper-pentapod"] = biter_medium,
        ["big-stomper-pentapod"] = biter_big,

        ["small-strafer-pentapod"] = biter_small,
        ["medium-strafer-pentapod"] = biter_medium,
        ["big-strafer-pentapod"] = biter_big,
    }

    eon_apply_nauvis_evolution_to_pentapods(
        spawners["gleba-spawner"] and spawners["gleba-spawner"].result_units,
        unit_points_by_name
    )
    eon_apply_nauvis_evolution_to_pentapods(
        spawners["gleba-spawner-small"] and spawners["gleba-spawner-small"].result_units,
        unit_points_by_name
    )
end

---@return nil
local function eon_make_deep_oil_ocean_collide_with_players()
    for _, tile_name in pairs({ "oil-ocean-deep", "oil-ocean-deep-2" }) do
        local tile = data.raw["tile"] and data.raw["tile"][tile_name]
        if tile then
            eon_autoplace_policy.add_collision_mask_layer(tile, "player")
        end
    end
end

---@return nil
local function eon_prevent_cold_biter_bases_on_fulgora_oil_ocean()
    if not eon_mode.aquilo_on_fulgora then return end
    if not mods["Cold_biters"] then return end

    local collision_patched = 0
    local restriction_patched = 0
    for _, prototype_type in pairs(eon_enemy_registry.final_fixes.base_autoplace_types) do
        for prototype_name, prototype in pairs(data.raw[prototype_type] or {}) do
            if eon_is_cold_biter_enemy_prototype(prototype_type, prototype_name) then
                if eon_autoplace_policy.add_collision_mask_layer(prototype, "water_tile") then
                    collision_patched = collision_patched + 1
                end
                if eon_exclude_fulgora_oil_ocean_from_autoplace(prototype) then
                    restriction_patched = restriction_patched + 1
                end
            end
        end
    end
end

---@param prototype_type string
---@param prototype_name string
---@return boolean
local function eon_is_fulgoran_enemy_base_prototype(prototype_type, prototype_name)
    return eon_enemy_registry.is_fulgoran_enemy_base_prototype(prototype_type, prototype_name)
end

---@return nil
local function eon_prevent_fulgoran_enemy_bases_on_fulgora_oil_ocean()
    if not mods["Electric_flying_enemies"] then return end

    local collision_patched = 0
    local restriction_patched = 0
    for _, prototype_type in pairs(eon_enemy_registry.final_fixes.base_autoplace_types) do
        for prototype_name, prototype in pairs(data.raw[prototype_type] or {}) do
            if eon_is_fulgoran_enemy_base_prototype(prototype_type, prototype_name) then
                if eon_autoplace_policy.add_collision_mask_layer(prototype, "water_tile") then
                    collision_patched = collision_patched + 1
                end
                if eon_exclude_fulgora_oil_ocean_from_autoplace(prototype) then
                    restriction_patched = restriction_patched + 1
                end
            end
        end
    end
end

---@return nil
local function eon_order_cold_biter_enemies_after_gleba_enemy_bases()
    if not mods["Cold_biters"] then return end

    local control = data.raw["autoplace-control"] and data.raw["autoplace-control"]["frost_enemy_base"]
    if not control then return end

    control.order = "z-a"
    control.category = "enemy"
end

---@return nil
local function eon_order_fulgoran_enemies_after_cold_biter_enemies()
    if not mods["Electric_flying_enemies"] then return end

    local control = data.raw["autoplace-control"] and data.raw["autoplace-control"]["electric_enemies"]
    if not control then return end

    control.order = "z-b"
    control.category = "enemy"
end

---@return nil
function eon_final_fixes_enemy_policy.apply()
    eon_normalize_autoplaced_enemy_candidates()
    eon_align_nauvis_pentapod_evolution()
    eon_make_deep_oil_ocean_collide_with_players()
    eon_prevent_cold_biter_bases_on_fulgora_oil_ocean()
    eon_prevent_fulgoran_enemy_bases_on_fulgora_oil_ocean()
    eon_order_cold_biter_enemies_after_gleba_enemy_bases()
    eon_order_fulgoran_enemies_after_cold_biter_enemies()
end

return eon_final_fixes_enemy_policy
