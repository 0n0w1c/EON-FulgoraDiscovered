local eon_mode = require("lib.eon-mode")
local eon_autoplace_policy = require("lib.eon-autoplace-policy")
local eon_enemy_registry = require("lib.eon-enemy-registry")
local eon_tile_registry = require("lib.eon-tile-registry")

local eon_final_fixes_enemy_policy = {}

---Normalizes Commander enemy candidates on Nauvis.
---Collision masks are shared; tile restrictions define wetland or land placement.
local eon_enemy_autoplace_policy = eon_tile_registry.enemy_autoplace
local eon_commander_enemy_collision_mask = eon_autoplace_policy.make_collision_mask(
    eon_enemy_autoplace_policy.commander_collision_layers
)
local eon_gleba_wetland_spawner_tiles = eon_enemy_autoplace_policy.gleba_wetland_spawner_tiles

---@type string[]
local eon_land_spawner_tiles = eon_autoplace_policy.collect_solid_land_tile_names()

---Returns whether a prototype participates in enemy-base style autoplace.
---@param proto table|nil Candidate unit-spawner or turret prototype.
---@return boolean is_candidate True when the prototype has an autoplace control.
local function eon_is_autoplaced_enemy_candidate(proto)
    return proto ~= nil
        and proto.autoplace ~= nil
        and proto.autoplace.control ~= nil
end

---Normalizes an autoplaced enemy prototype for Commander expansion.
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

---Excludes Fulgora oil-ocean tiles from a base prototype's autoplace tile restriction.
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


---Retunes vanilla Gleba pentapod spawn curves for Nauvis evolution pacing.
---In Space Age, Gleba reaches big pentapods much earlier than Nauvis reaches
---behemoth biters. This mod moves Gleba enemies onto Nauvis, so keep the
---pentapod families but delay medium/big variants to better match Nauvis
---military progression.
---@return nil
local function eon_slow_nauvis_pentapod_evolution()
    local spawners = data.raw["unit-spawner"]
    if not spawners then return end

    local gleba_spawner = spawners["gleba-spawner"]
    if gleba_spawner then
        gleba_spawner.result_units = {
            -- Small pentapods: early threat, fade out around big-biter timing.
            { "small-wriggler-pentapod", {
                { 0.00, 0.40 },
                { 0.30, 0.40 },
                { 0.75, 0.00 },
            } },
            { "small-strafer-pentapod", {
                { 0.00, 0.40 },
                { 0.30, 0.40 },
                { 0.75, 0.00 },
            } },
            { "small-stomper-pentapod", {
                { 0.10, 0.00 },
                { 0.35, 0.20 },
                { 0.75, 0.00 },
            } },

            -- Medium pentapods: main midgame Gleba threat on Nauvis.
            { "medium-wriggler-pentapod", {
                { 0.35, 0.00 },
                { 0.70, 0.40 },
                { 1.00, 0.10 },
            } },
            { "medium-strafer-pentapod", {
                { 0.40, 0.00 },
                { 0.75, 0.40 },
                { 1.00, 0.10 },
            } },
            { "medium-stomper-pentapod", {
                { 0.50, 0.00 },
                { 0.80, 0.20 },
                { 1.00, 0.08 },
            } },

            -- Big pentapods: delayed to behemoth-era evolution.
            { "big-wriggler-pentapod", {
                { 0.85, 0.00 },
                { 0.95, 0.35 },
                { 1.00, 0.35 },
            } },
            { "big-strafer-pentapod", {
                { 0.88, 0.00 },
                { 0.97, 0.35 },
                { 1.00, 0.35 },
            } },
            { "big-stomper-pentapod", {
                { 0.92, 0.00 },
                { 0.98, 0.12 },
                { 1.00, 0.15 },
            } },
        }
    end

    local gleba_spawner_small = spawners["gleba-spawner-small"]
    if gleba_spawner_small then
        gleba_spawner_small.result_units = {
            { "small-wriggler-pentapod", {
                { 0.00, 0.90 },
                { 0.40, 0.90 },
                { 0.80, 0.00 },
            } },
            { "medium-wriggler-pentapod", {
                { 0.40, 0.00 },
                { 0.75, 0.70 },
                { 1.00, 0.15 },
            } },
            { "big-wriggler-pentapod", {
                { 0.88, 0.00 },
                { 0.98, 0.60 },
                { 1.00, 0.80 },
            } },
        }
    end
end

---@return nil
local function eon_make_deep_oil_ocean_collide_with_players()
    local tile = data.raw["tile"] and data.raw["tile"]["oil-ocean-deep"]
    if not tile then return end

    eon_autoplace_policy.add_collision_mask_layer(tile, "player")
end

---@return nil
local function eon_prevent_cold_biter_bases_on_fulgora_oil_ocean()
    if not eon_mode.aquilo_on_fulgora then return end
    if not (mods["Cold_biters"] or mods["Frost_biters"]) then return end

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
local function eon_order_fulgoran_enemies_after_gleba_enemy_bases()
    if not mods["Electric_flying_enemies"] then return end

    local control = data.raw["autoplace-control"] and data.raw["autoplace-control"]["electric_enemies"]
    if not control then return end

    control.order = "z-a"
    control.category = "enemy"
end

---@return nil
function eon_final_fixes_enemy_policy.apply()
    eon_normalize_autoplaced_enemy_candidates()
    eon_slow_nauvis_pentapod_evolution()
    eon_make_deep_oil_ocean_collide_with_players()
    eon_prevent_cold_biter_bases_on_fulgora_oil_ocean()
    eon_prevent_fulgoran_enemy_bases_on_fulgora_oil_ocean()
    eon_order_fulgoran_enemies_after_gleba_enemy_bases()
end

return eon_final_fixes_enemy_policy
