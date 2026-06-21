local eon_enemy_registry = require("lib.eon-enemy-registry")
local eon_tile_registry = require("lib.eon-tile-registry")

local eon_runtime_enemies = {}

---@param tile LuaTile|nil
---@return string|nil
local function eon_tile_subgroup_name(tile)
    if not (tile and tile.valid and tile.prototype and tile.prototype.subgroup) then
        return nil
    end

    return tile.prototype.subgroup.name
end

function eon_runtime_enemies.create_handlers(settings)
    settings = settings or {}
    local eon_aquilo_on_fulgora = settings.aquilo_on_fulgora == true
    local eon_enemy_surface_names = eon_enemy_registry.surface_names_for_mode(eon_aquilo_on_fulgora)

    local aquilo_cliff_blocking_tile_lookup = eon_tile_registry.cliff_blocking.aquilo_set
    local nauvis_tile_names = eon_tile_registry.cliff_blocking.nauvis_set
    local terrain_cliff_rules = eon_tile_registry.cliff_blocking.rules

    local eon_enemy_base_variant_by_name = eon_enemy_registry.base_variant_by_name

    local eon_enemy_expansion_scar_decoratives = eon_enemy_registry.runtime.expansion_scar_decoratives

    ---@param surface LuaSurface
    ---@param position MapPosition
    ---@param variant table
    local function eon_clear_enemy_expansion_scars(surface, position, variant)
        local radius = variant and variant.tier == "spawner" and 14 or 3
        surface.destroy_decoratives({
            area = {
                { position.x - radius, position.y - radius },
                { position.x + radius, position.y + radius },
            },
            name = eon_enemy_expansion_scar_decoratives,
        })
    end

    local eon_existing_entity_names

    local eon_enemy_replacements = eon_enemy_registry.base_replacements

    local eon_enemy_unit_replacements = eon_enemy_registry.unit_replacements

    ---@param unit_name string
    ---@return string,string
    local function eon_unit_kind_and_tier(unit_name)
        local kind = string.find(unit_name, "spitter", 1, true) and "spitter" or "biter"

        if string.find(unit_name, "wriggler%-pentapod") or string.find(unit_name, "electric%-unit") then
            kind = "biter"
        end

        local tier = "small"
        if string.find(unit_name, "medium", 1, true) or string.find(unit_name, "%-2") then
            tier = "medium"
        elseif string.find(unit_name, "big", 1, true) or string.find(unit_name, "%-3") then
            tier = "big"
        elseif string.find(unit_name, "behemoth", 1, true) or string.find(unit_name, "%-4") then
            tier = "behemoth"
        elseif string.find(unit_name, "leviathan", 1, true) or string.find(unit_name, "%-5") then
            tier = "leviathan"
        elseif string.find(unit_name, "mother", 1, true) then
            tier = "mother"
        end

        return kind, tier
    end

    ---@param unit_name string|nil Runtime unit prototype name.
    ---@return string family Enemy visual family used by expansion group normalization.
    local function eon_enemy_unit_family(unit_name)
        if type(unit_name) ~= "string" then return "vanilla" end

        if string.find(unit_name, "electric%-unit") then return "fulgora" end
        if string.find(unit_name, "cold", 1, true) or string.find(unit_name, "frost", 1, true) then return "cold" end
        if string.find(unit_name, "explosive", 1, true) then return "hot" end

        if string.find(unit_name, "wriggler%-pentapod")
            or string.find(unit_name, "strafer%-pentapod")
            or string.find(unit_name, "stomper%-pentapod") then
            return "gleba"
        end

        if string.find(unit_name, "armoured", 1, true) then return "armoured" end
        return "vanilla"
    end

    ---@param unit_name string
    ---@param target_family string
    ---@return string|nil
    local function eon_replacement_unit_name(unit_name, target_family)
        local kind, tier = eon_unit_kind_and_tier(unit_name)
        local candidates = eon_enemy_unit_replacements[target_family]
            and eon_enemy_unit_replacements[target_family][kind]
            and eon_enemy_unit_replacements[target_family][kind][tier]

        local existing = eon_existing_entity_names(candidates)
        local existing_count = table_size(existing)
        if existing_count == 0 and kind == "spitter" then
            candidates = eon_enemy_unit_replacements[target_family]
                and eon_enemy_unit_replacements[target_family].biter
                and eon_enemy_unit_replacements[target_family].biter[tier]
            existing = eon_existing_entity_names(candidates)
            existing_count = table_size(existing)
        end

        if existing_count == 0 then return nil end
        return existing[math.random(existing_count)]
    end

    ---@param terrain_family string|nil
    ---@param source_family string|nil Current unit family, when known.
    ---@return string|nil
    local function eon_target_unit_family_for_terrain(terrain_family, source_family)
        if terrain_family == "cold" then return "cold" end
        if terrain_family == "hot" then return "hot" end
        if terrain_family == "gleba" then return "gleba" end
        if terrain_family == "fulgora" then return "fulgora" end

        if terrain_family == "nauvis" then
            if source_family == "armoured" then return "armoured" end
            return "vanilla"
        end

        return nil
    end

    ---@param entity_name string|nil
    ---@return boolean exists True when the entity prototype is loaded at runtime.
    local function eon_runtime_entity_prototype_exists(entity_name)
        return type(entity_name) == "string"
            and prototypes
            and prototypes.entity
            and prototypes.entity[entity_name] ~= nil
    end

    ---@param names string[]|nil Candidate entity prototype names.
    ---@return string[] existing Candidate names that are available in this save.
    eon_existing_entity_names = function(names)
        local existing = {}
        if type(names) ~= "table" then return existing end

        for _, entity_name in pairs(names) do
            if eon_runtime_entity_prototype_exists(entity_name) then
                table.insert(existing, entity_name)
            end
        end

        return existing
    end

    ---@param tile LuaTile|nil Tile under the entity/group destination.
    ---@return string|nil terrain_family One of cold, hot, gleba, fulgora, nauvis, or nil when unknown.
    local function eon_enemy_tile_family(tile)
        local subgroup_name = eon_tile_subgroup_name(tile)
        local tile_name = tile and tile.name

        if subgroup_name == "aquilo-tiles" or aquilo_cliff_blocking_tile_lookup[tile_name] then
            return "cold"
        end

        if subgroup_name == "vulcanus-tiles" or terrain_cliff_rules[2].tile_names[tile_name] then
            return "hot"
        end

        if subgroup_name == "gleba-tiles" or terrain_cliff_rules[1].tile_names[tile_name] then
            return "gleba"
        end

        if subgroup_name == "fulgora-tiles" then
            return "fulgora"
        end

        if subgroup_name == "nauvis-tiles" or nauvis_tile_names[tile_name] then
            return "nauvis"
        end

        return nil
    end

    ---@param entity LuaEntity Entity whose center tile should be classified.
    ---@return string|nil terrain_family Tile family under the entity center.
    local function eon_enemy_terrain_family_for_entity(entity)
        local surface = entity.surface
        local position = entity.position

        return eon_enemy_tile_family(surface.get_tile(position.x, position.y))
    end

    ---@param variant table Enemy base variant metadata from eon_enemy_base_variant_by_name.
    ---@param terrain_family string|nil Terrain family returned by eon_enemy_tile_family.
    ---@return boolean allowed True when the current base family is valid for the terrain.
    local function eon_enemy_base_allowed_on_terrain(variant, terrain_family)
        if terrain_family == "cold" then return variant.family == "cold" end
        if terrain_family == "hot" then return variant.family == "hot" end
        if terrain_family == "gleba" then return variant.family == "gleba" end

        if terrain_family == "nauvis" then
            return variant.family == "vanilla" or variant.family == "armoured"
        end

        if terrain_family == "fulgora" then
            return variant.family == "fulgora" or not eon_aquilo_on_fulgora
        end

        if variant.family == "fulgora" and not eon_aquilo_on_fulgora then
            return true
        end

        return false
    end

    ---@param variant table Enemy base variant metadata from eon_enemy_base_variant_by_name.
    ---@param terrain_family string|nil Terrain family returned by eon_enemy_tile_family.
    ---@return string|nil family Replacement family to use for this terrain.
    local function eon_target_enemy_family(variant, terrain_family)
        if terrain_family == "cold" then return "cold" end
        if terrain_family == "hot" then return "hot" end
        if terrain_family == "gleba" then return "gleba" end
        if terrain_family == "fulgora" then return "fulgora" end

        if terrain_family == "nauvis" then
            if variant.family == "armoured" then return "armoured" end
            return "vanilla"
        end

        return nil
    end

    ---@param variant table Enemy base variant metadata from eon_enemy_base_variant_by_name.
    ---@param terrain_family string|nil Terrain family returned by eon_enemy_tile_family.
    ---@return string|nil entity_name Replacement entity prototype name, or nil to remove without replacement.
    local function eon_replacement_enemy_name(variant, terrain_family)
        local target_family = eon_target_enemy_family(variant, terrain_family)
        local candidates = target_family
            and eon_enemy_replacements[target_family]
            and eon_enemy_replacements[target_family][variant.tier]

        local existing = eon_existing_entity_names(candidates)
        local existing_count = table_size(existing)
        if existing_count == 0 then return nil end

        return existing[math.random(existing_count)]
    end

    ---@param event EventData.on_unit_group_finished_gathering
    local function eon_on_unit_group_finished_gathering(event)
        local group = event.group
        if not (group and group.valid and group.is_unit_group) then return end
        if not (group.surface and group.surface.valid and eon_enemy_surface_names[group.surface.name]) then return end

        local command = group.command
        if not (command and command.type == defines.command.build_base) then return end

        local surface = group.surface
        local destination = command.destination or group.position
        if not destination then return end

        local tile = surface.get_tile(destination.x, destination.y)
        local terrain_family = eon_enemy_tile_family(tile)

        local old_units = {}
        local replacements = {}
        local changed = false

        for _, unit in pairs(group.members or {}) do
            if unit and unit.valid then
                table.insert(old_units, unit)
                local unit_index = table_size(old_units)
                local source_family = eon_enemy_unit_family(unit.name)
                local target_family = eon_target_unit_family_for_terrain(terrain_family, source_family)
                local replacement_name = nil

                if target_family and source_family ~= target_family then
                    replacement_name = eon_replacement_unit_name(unit.name, target_family)
                end

                replacements[unit_index] = replacement_name
                if replacement_name and replacement_name ~= unit.name then
                    changed = true
                end
            end
        end

        if not changed then
            return
        end

        for unit_index, old_unit in pairs(old_units) do
            local replacement_name = replacements[unit_index]
            if replacement_name and replacement_name ~= old_unit.name then
                local created = surface.create_entity({
                    name = replacement_name,
                    position = old_unit.position or destination,
                    force = group.force,
                    raise_built = false,
                })

                if created and created.valid then
                    pcall(function() group.add_member(created) end)
                end

                if old_unit and old_unit.valid then
                    old_unit.destroy({ raise_destroy = false })
                end
            end
        end
    end

    ---@param entity LuaEntity|nil Entity supplied by on_biter_base_built or script_raised_built.
    ---@return nil
    local function eon_enforce_enemy_base_entity(entity)
        if not (entity and entity.valid) then return end

        local surface = entity.surface
        local terrain_family = eon_enemy_terrain_family_for_entity(entity)
        local variant = eon_enemy_base_variant_by_name[entity.name]

        if not variant then return end
        if not (surface and surface.valid and eon_enemy_surface_names[surface.name]) then return end

        if eon_enemy_base_allowed_on_terrain(variant, terrain_family) then return end

        local replacement_name = eon_replacement_enemy_name(variant, terrain_family)
        local position = { x = entity.position.x, y = entity.position.y }
        local force = entity.force

        entity.destroy({ raise_destroy = false })
        eon_clear_enemy_expansion_scars(surface, position, variant)

        if replacement_name then
            surface.create_entity({
                name = replacement_name,
                position = position,
                force = force,
                raise_built = false,
            })
        end
    end

    return {
        on_unit_group_finished_gathering = eon_on_unit_group_finished_gathering,
        enforce_enemy_base_entity = eon_enforce_enemy_base_entity,
    }
end

return eon_runtime_enemies
