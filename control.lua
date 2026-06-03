local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value

local surface_names = { nauvis = true }
if eon_aquilo_on_fulgora then
    surface_names.fulgora = true
end

local eon_enemy_surface_names = { nauvis = true }
if eon_aquilo_on_fulgora then
    eon_enemy_surface_names.fulgora = true
end

local aquilo_cliff_blocking_tile_names = {
    "ammoniacal-ocean",
    "ammoniacal-ocean-2",
    "brash-ice",
    "ice-rough",
    "ice-smooth",
    "snow-crests",
    "snow-flat",
    "snow-lumpy",
    "snow-patchy"
}

local aquilo_cliff_blocking_tile_lookup = {
    ["ammoniacal-ocean"] = true,
    ["ammoniacal-ocean-2"] = true,
    ["brash-ice"] = true,
    ["ice-rough"] = true,
    ["ice-smooth"] = true,
    ["snow-crests"] = true,
    ["snow-flat"] = true,
    ["snow-lumpy"] = true,
    ["snow-patchy"] = true
}


local nauvis_tile_names = {
    ["grass-1"] = true,
    ["grass-2"] = true,
    ["grass-3"] = true,
    ["grass-4"] = true,
    ["dry-dirt"] = true,
    ["dirt-1"] = true,
    ["dirt-2"] = true,
    ["dirt-3"] = true,
    ["dirt-4"] = true,
    ["dirt-5"] = true,
    ["dirt-6"] = true,
    ["dirt-7"] = true,
    ["sand-1"] = true,
    ["sand-2"] = true,
    ["sand-3"] = true,
    ["red-desert-0"] = true,
    ["red-desert-1"] = true,
    ["red-desert-2"] = true,
    ["red-desert-3"] = true
}

local terrain_cliff_rules = {
    {
        cliff_name = "cliff-gleba",
        tile_names = {
            ["natural-yumako-soil"] = true,
            ["natural-jellynut-soil"] = true,
            ["wetland-yumako"] = true,
            ["wetland-jellynut"] = true,
            ["wetland-blue-slime"] = true,
            ["wetland-light-green-slime"] = true,
            ["wetland-green-slime"] = true,
            ["wetland-light-dead-skin"] = true,
            ["wetland-dead-skin"] = true,
            ["wetland-pink-tentacle"] = true,
            ["wetland-red-tentacle"] = true,
            ["gleba-deep-lake"] = true,
            ["lowland-brown-blubber"] = true,
            ["lowland-olive-blubber"] = true,
            ["lowland-olive-blubber-2"] = true,
            ["lowland-olive-blubber-3"] = true,
            ["lowland-pale-green"] = true,
            ["lowland-cream-cauliflower"] = true,
            ["lowland-cream-cauliflower-2"] = true,
            ["lowland-dead-skin"] = true,
            ["lowland-dead-skin-2"] = true,
            ["lowland-cream-red"] = true,
            ["lowland-red-vein"] = true,
            ["lowland-red-vein-2"] = true,
            ["lowland-red-vein-3"] = true,
            ["lowland-red-vein-4"] = true,
            ["lowland-red-vein-dead"] = true,
            ["lowland-red-infection"] = true,
            ["midland-turquoise-bark"] = true,
            ["midland-turquoise-bark-2"] = true,
            ["midland-cracked-lichen"] = true,
            ["midland-cracked-lichen-dull"] = true,
            ["midland-cracked-lichen-dark"] = true,
            ["midland-yellow-crust"] = true,
            ["midland-yellow-crust-2"] = true,
            ["midland-yellow-crust-3"] = true,
            ["midland-yellow-crust-4"] = true,
            ["highland-dark-rock"] = true,
            ["highland-dark-rock-2"] = true,
            ["highland-yellow-rock"] = true,
            ["pit-rock"] = true
        }
    },
    {
        cliff_name = "cliff-vulcanus",
        tile_names = {
            ["volcanic-soil-dark"] = true,
            ["volcanic-soil-light"] = true,
            ["volcanic-ash-soil"] = true,
            ["volcanic-ash-flats"] = true,
            ["volcanic-ash-light"] = true,
            ["volcanic-ash-dark"] = true,
            ["volcanic-ash-cracks"] = true,
            ["volcanic-cracks"] = true,
            ["volcanic-cracks-warm"] = true,
            ["volcanic-cracks-hot"] = true,
            ["volcanic-folds"] = true,
            ["volcanic-folds-flat"] = true,
            ["lava"] = true,
            ["lava-hot"] = true,
            ["volcanic-folds-warm"] = true,
            ["volcanic-jagged-ground"] = true,
            ["volcanic-pumice-stones"] = true,
            ["volcanic-smooth-stone"] = true,
            ["volcanic-smooth-stone-warm"] = true
        }
    }
}

---@param cliff LuaEntity
---@return table
local function cliff_scan_area(cliff)
    return {
        left_top = {
            x = cliff.position.x - 3,
            y = cliff.position.y - 3
        },
        right_bottom = {
            x = cliff.position.x + 3,
            y = cliff.position.y + 3
        }
    }
end

---@param cliff LuaEntity
---@return boolean
local function cliff_overlaps_aquilo_tile(cliff)
    local surface = cliff.surface
    local area = cliff_scan_area(cliff)

    if area then
        return surface.count_tiles_filtered({
            area = area,
            name = aquilo_cliff_blocking_tile_names,
            limit = 1
        }) > 0
    end

    local tile = surface.get_tile(cliff.position.x, cliff.position.y)
    return tile and aquilo_cliff_blocking_tile_lookup[tile.name] == true
end

---@param cliff LuaEntity
---@return boolean
local function keep_cliff_off_aquilo_tiles(cliff)
    if not (cliff and cliff.valid) then return false end
    if cliff.name == "crater-cliff" then return true end

    local surface_name = cliff.surface.name
    local should_remove = false

    if eon_aquilo_on_fulgora then
        should_remove = false
    else
        should_remove = surface_name == "nauvis"
    end

    if should_remove and cliff_overlaps_aquilo_tile(cliff) then
        cliff.destroy({ do_cliff_correction = true, raise_destroy = false })
        return false
    end

    return true
end

---@param cliff table
---@return any
local function scan_cliff_terrain(cliff)
    local found = {
        gleba = false,
        vulcanus = false,
        nauvis = false
    }

    local surface = cliff.surface
    local area = cliff_scan_area(cliff)
    local left = math.floor(area.left_top.x)
    local top = math.floor(area.left_top.y)
    local right = math.ceil(area.right_bottom.x) - 1
    local bottom = math.ceil(area.right_bottom.y) - 1

    local gleba_tile_names = terrain_cliff_rules[1].tile_names
    local vulcanus_tile_names = terrain_cliff_rules[2].tile_names

    for x = left, right do
        for y = top, bottom do
            local tile = surface.get_tile(x, y)
            local tile_name = tile and tile.name
            if tile_name then
                if vulcanus_tile_names[tile_name] then
                    found.vulcanus = true
                elseif gleba_tile_names[tile_name] then
                    found.gleba = true
                elseif nauvis_tile_names[tile_name] then
                    found.nauvis = true
                end
            end
        end
    end

    return found
end

---@param cliff table
---@return any
local function target_cliff_rule_for_terrain(cliff)
    local found = scan_cliff_terrain(cliff)

    if (found.vulcanus or found.gleba) and found.nauvis then
        return "destroy"
    end

    if found.vulcanus then
        return terrain_cliff_rules[2]
    end

    if found.gleba then
        return terrain_cliff_rules[1]
    end

    return nil
end

---@param cliff table
---@param target_orientation string
---@return nil
local function rotate_cliff_to_orientation(cliff, target_orientation)
    if not (cliff and cliff.valid and target_orientation) then return end

    local attempts = 0
    while cliff.valid and cliff.cliff_orientation ~= target_orientation and attempts < 20 do
        cliff.rotate()
        attempts = attempts + 1
    end
end

---@param surface table
---@param name string
---@param original_cliff_data any
---@return any
local function create_cliff(surface, name, original_cliff_data)
    local create_params = {
        name = name,
        position = original_cliff_data.position,
        direction = original_cliff_data.direction,
        force = original_cliff_data.force,
        create_build_effect_smoke = false,
        raise_built = false
    }

    local entity = surface.create_entity(create_params)

    if entity and entity.valid then
        rotate_cliff_to_orientation(entity, original_cliff_data.cliff_orientation)
        return entity
    end

    return nil
end

---@param cliff table
---@return nil
local function replace_with_terrain_cliff(cliff)
    if not (cliff and cliff.valid) then return end

    local target_rule = target_cliff_rule_for_terrain(cliff)
    if not target_rule then return end

    if target_rule == "destroy" then
        cliff.destroy({ do_cliff_correction = true, raise_destroy = false })
        return
    end

    local target_cliff_name = target_rule.cliff_name
    if not target_cliff_name then return end
    if cliff.name == target_cliff_name then return end

    local surface = cliff.surface
    local original_name = cliff.name
    local original_cliff_data = {
        position = { x = cliff.position.x, y = cliff.position.y },
        direction = cliff.direction,
        cliff_orientation = cliff.cliff_orientation,
        force = cliff.force
    }

    if not cliff.destroy({ raise_destroy = false }) then
        return
    end

    local created_cliff = create_cliff(surface, target_cliff_name, original_cliff_data)
    if not (created_cliff and created_cliff.valid) then
        create_cliff(surface, original_name, original_cliff_data)
    end
end

---@param surface table
---@param area table
---@return nil
local function process_area(surface, area)
    local cliffs = surface.find_entities_filtered({
        area = area,
        type = "cliff"
    })

    for _, cliff in pairs(cliffs) do
        if keep_cliff_off_aquilo_tiles(cliff) and cliff.valid and cliff.name ~= "crater-cliff" then
            replace_with_terrain_cliff(cliff)
        end
    end
end


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

script.on_event(defines.events.on_script_trigger_effect, function(event)
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
end)

local eon_enemy_base_variant_by_name = {
    ["biter-spawner"] = { tier = "spawner", family = "vanilla" },
    ["spitter-spawner"] = { tier = "spawner", family = "vanilla" },
    ["small-worm-turret"] = { tier = "small-worm", family = "vanilla" },
    ["medium-worm-turret"] = { tier = "medium-worm", family = "vanilla" },
    ["big-worm-turret"] = { tier = "big-worm", family = "vanilla" },
    ["behemoth-worm-turret"] = { tier = "behemoth-worm", family = "vanilla" },

    ["armoured-biter-spawner"] = { tier = "spawner", family = "armoured" },
    ["small-armoured-worm-turret"] = { tier = "small-worm", family = "armoured" },
    ["medium-armoured-worm-turret"] = { tier = "medium-worm", family = "armoured" },
    ["big-armoured-worm-turret"] = { tier = "big-worm", family = "armoured" },
    ["behemoth-armoured-worm-turret"] = { tier = "behemoth-worm", family = "armoured" },

    ["explosive-biter-spawner"] = { tier = "spawner", family = "hot" },
    ["small-explosive-worm-turret"] = { tier = "small-worm", family = "hot" },
    ["medium-explosive-worm-turret"] = { tier = "medium-worm", family = "hot" },
    ["big-explosive-worm-turret"] = { tier = "big-worm", family = "hot" },
    ["behemoth-explosive-worm-turret"] = { tier = "behemoth-worm", family = "hot" },
    ["leviathan-explosive-worm-turret"] = { tier = "behemoth-worm", family = "hot" },
    ["mother-explosive-worm-turret"] = { tier = "behemoth-worm", family = "hot" },

    ["cb-cold-spawner"] = { tier = "spawner", family = "cold" },
    ["small-cold-worm-turret"] = { tier = "small-worm", family = "cold" },
    ["medium-cold-worm-turret"] = { tier = "medium-worm", family = "cold" },
    ["big-cold-worm-turret"] = { tier = "big-worm", family = "cold" },
    ["behemoth-cold-worm-turret"] = { tier = "behemoth-worm", family = "cold" },
    ["leviathan-cold-worm-turret"] = { tier = "behemoth-worm", family = "cold" },
    ["mother-cold-worm-turret"] = { tier = "behemoth-worm", family = "cold" },

    ["gleba-spawner"] = { tier = "spawner", family = "gleba" },
    ["gleba-spawner-small"] = { tier = "spawner", family = "gleba" },

    ["flying-electric-unit-spawner"] = { tier = "spawner", family = "fulgora" },
    ["walker-electric-unit-spawner"] = { tier = "spawner", family = "fulgora" },
}

local eon_enemy_base_names = {}
for entity_name, _ in pairs(eon_enemy_base_variant_by_name) do
    table.insert(eon_enemy_base_names, entity_name)
end


local eon_enemy_expansion_scar_decoratives = {
    "enemy-decal",
    "enemy-decal-transparent",
    "worms-decal",
}

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

local eon_enemy_replacements = {
    vanilla = {
        ["spawner"] = { "biter-spawner", "spitter-spawner" },
        ["small-worm"] = { "small-worm-turret" },
        ["medium-worm"] = { "medium-worm-turret" },
        ["big-worm"] = { "big-worm-turret" },
        ["behemoth-worm"] = { "behemoth-worm-turret" },
    },
    armoured = {
        ["spawner"] = { "armoured-biter-spawner" },
        ["small-worm"] = { "small-armoured-worm-turret" },
        ["medium-worm"] = { "medium-armoured-worm-turret" },
        ["big-worm"] = { "big-armoured-worm-turret" },
        ["behemoth-worm"] = { "behemoth-armoured-worm-turret" },
    },
    hot = {
        ["spawner"] = { "explosive-biter-spawner" },
        ["small-worm"] = { "small-explosive-worm-turret" },
        ["medium-worm"] = { "medium-explosive-worm-turret" },
        ["big-worm"] = { "big-explosive-worm-turret" },
        ["behemoth-worm"] = {
            "behemoth-explosive-worm-turret",
            "leviathan-explosive-worm-turret",
            "mother-explosive-worm-turret"
        },
    },
    cold = {
        ["spawner"] = { "cb-cold-spawner" },
        ["small-worm"] = { "small-cold-worm-turret" },
        ["medium-worm"] = { "medium-cold-worm-turret" },
        ["big-worm"] = { "big-cold-worm-turret" },
        ["behemoth-worm"] = {
            "behemoth-cold-worm-turret",
            "leviathan-cold-worm-turret",
            "mother-cold-worm-turret"
        },
    },
    gleba = {
        ["spawner"] = { "gleba-spawner", "gleba-spawner-small" },
        ["small-worm"] = { "gleba-spawner-small", "gleba-spawner" },
        ["medium-worm"] = { "gleba-spawner", "gleba-spawner-small" },
        ["big-worm"] = { "gleba-spawner", "gleba-spawner-small" },
        ["behemoth-worm"] = { "gleba-spawner", "gleba-spawner-small" },
    },
    fulgora = {
        ["spawner"] = { "flying-electric-unit-spawner", "walker-electric-unit-spawner" },
        ["small-worm"] = { "flying-electric-unit-spawner", "walker-electric-unit-spawner" },
        ["medium-worm"] = { "walker-electric-unit-spawner", "flying-electric-unit-spawner" },
        ["big-worm"] = { "walker-electric-unit-spawner", "flying-electric-unit-spawner" },
        ["behemoth-worm"] = { "walker-electric-unit-spawner", "flying-electric-unit-spawner" },
    },
}

local eon_enemy_unit_replacements = {
    vanilla = {
        biter = {
            small = { "small-biter" },
            medium = { "medium-biter" },
            big = { "big-biter" },
            behemoth = { "behemoth-biter" },
            leviathan = { "behemoth-biter" },
            mother = { "behemoth-biter" },
        },
        spitter = {
            small = { "small-spitter" },
            medium = { "medium-spitter" },
            big = { "big-spitter" },
            behemoth = { "behemoth-spitter" },
            leviathan = { "behemoth-spitter" },
            mother = { "behemoth-spitter" },
        },
    },
    armoured = {
        biter = {
            small = { "small-armoured-biter" },
            medium = { "medium-armoured-biter" },
            big = { "big-armoured-biter" },
            behemoth = { "behemoth-armoured-biter" },
            leviathan = { "leviathan-armoured-biter", "behemoth-armoured-biter" },
            mother = { "leviathan-armoured-biter", "behemoth-armoured-biter" },
        },
        spitter = {
            small = { "small-armoured-biter" },
            medium = { "medium-armoured-biter" },
            big = { "big-armoured-biter" },
            behemoth = { "behemoth-armoured-biter" },
            leviathan = { "leviathan-armoured-biter", "behemoth-armoured-biter" },
            mother = { "leviathan-armoured-biter", "behemoth-armoured-biter" },
        },
    },
    hot = {
        biter = {
            small = { "small-explosive-biter" },
            medium = { "medium-explosive-biter" },
            big = { "big-explosive-biter" },
            behemoth = { "behemoth-explosive-biter" },
            leviathan = { "explosive-leviathan-biter", "behemoth-explosive-biter" },
            mother = { "explosive-leviathan-biter", "behemoth-explosive-biter" },
        },
        spitter = {
            small = { "small-explosive-spitter" },
            medium = { "medium-explosive-spitter" },
            big = { "big-explosive-spitter" },
            behemoth = { "behemoth-explosive-spitter" },
            leviathan = { "leviathan-explosive-spitter", "behemoth-explosive-spitter" },
            mother = { "mother-explosive-spitter", "leviathan-explosive-spitter", "behemoth-explosive-spitter" },
        },
    },
    cold = {
        biter = {
            small = { "small-cold-biter" },
            medium = { "medium-cold-biter" },
            big = { "big-cold-biter" },
            behemoth = { "behemoth-cold-biter" },
            leviathan = { "leviathan-cold-biter", "behemoth-cold-biter" },
            mother = { "leviathan-cold-biter", "behemoth-cold-biter" },
        },
        spitter = {
            small = { "small-cold-spitter" },
            medium = { "medium-cold-spitter" },
            big = { "big-cold-spitter" },
            behemoth = { "behemoth-cold-spitter" },
            leviathan = { "leviathan-cold-spitter", "behemoth-cold-spitter" },
            mother = { "mother-cold-spitter", "leviathan-cold-spitter", "behemoth-cold-spitter" },
        },
    },
    gleba = {
        biter = {
            small = { "small-wriggler-pentapod" },
            medium = { "medium-wriggler-pentapod", "small-wriggler-pentapod" },
            big = { "big-wriggler-pentapod", "medium-wriggler-pentapod" },
            behemoth = { "big-wriggler-pentapod" },
            leviathan = { "big-wriggler-pentapod" },
            mother = { "big-wriggler-pentapod" },
        },
        spitter = {
            small = { "small-wriggler-pentapod" },
            medium = { "medium-wriggler-pentapod", "small-wriggler-pentapod" },
            big = { "big-wriggler-pentapod", "medium-wriggler-pentapod" },
            behemoth = { "big-wriggler-pentapod" },
            leviathan = { "big-wriggler-pentapod" },
            mother = { "big-wriggler-pentapod" },
        },
    },
    fulgora = {
        biter = {
            small = { "walking-electric-unit-1", "flying-electric-unit-1" },
            medium = { "walking-electric-unit-2", "flying-electric-unit-2" },
            big = { "walking-electric-unit-3", "flying-electric-unit-3" },
            behemoth = { "walking-electric-unit-4", "flying-electric-unit-4" },
            leviathan = { "walking-electric-unit-5", "flying-electric-unit-5" },
            mother = { "walking-electric-unit-5", "flying-electric-unit-5" },
        },
        spitter = {
            small = { "flying-electric-unit-1", "walking-electric-unit-1" },
            medium = { "flying-electric-unit-2", "walking-electric-unit-2" },
            big = { "flying-electric-unit-3", "walking-electric-unit-3" },
            behemoth = { "flying-electric-unit-4", "walking-electric-unit-4" },
            leviathan = { "flying-electric-unit-5", "walking-electric-unit-5" },
            mother = { "flying-electric-unit-5", "walking-electric-unit-5" },
        },
    },
}

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
---@return string|nil
local function eon_target_unit_family_for_terrain(terrain_family)
    if terrain_family == "cold" then return "cold" end
    if terrain_family == "hot" then return "hot" end
    if terrain_family == "gleba" then return "gleba" end
    if terrain_family == "fulgora" then return "fulgora" end
    if terrain_family == "nauvis" then return "vanilla" end
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

local EON_EXPANSION_SITE_CLEANUP_TICKS = 60 * 60 * 10
local EON_EXPANSION_SITE_CLEANUP_RADIUS = 24
local EON_EXPANSION_SITE_CLEANUP_INTERVAL = 60

---@param surface LuaSurface|nil Surface where the cleanup would run.
---@return boolean enabled True when the delayed cleanup workaround is needed.
local function eon_expansion_site_cleanup_enabled(surface)
    if not (surface and surface.valid and eon_enemy_surface_names[surface.name]) then return false end

    return script.active_mods["Cold_biters"] ~= nil
        or script.active_mods["Explosive_biters"] ~= nil
end

---@return table<uint, table[]> buckets Pending cleanup records keyed by due tick.
local function eon_pending_expansion_site_cleanups()
    storage.eon_pending_expansion_site_cleanups = storage.eon_pending_expansion_site_cleanups or {}
    return storage.eon_pending_expansion_site_cleanups
end

---@param surface LuaSurface Surface containing the expansion site.
---@param position MapPosition Position of the expansion site.
---@return string key Stable bucket key for nearby expansion-site events.
local function eon_expansion_site_cleanup_key(surface, position)
    local radius = EON_EXPANSION_SITE_CLEANUP_RADIUS
    local bucket_x = math.floor(position.x / radius)
    local bucket_y = math.floor(position.y / radius)
    return tostring(surface.index) .. ":" .. tostring(bucket_x) .. ":" .. tostring(bucket_y)
end

---@return table<string, table> records Expansion group units tracked by cleanup-site key.
local function eon_expansion_site_tracked_unit_records()
    storage.eon_expansion_site_tracked_unit_records = storage.eon_expansion_site_tracked_unit_records or {}
    return storage.eon_expansion_site_tracked_unit_records
end

local eon_schedule_expansion_site_cleanup -- forward declaration for delayed expansion site cleanup

---@param surface LuaSurface Surface containing the expansion site.
---@param position MapPosition Expansion group destination.
---@param units table Unit group members to destroy during delayed cleanup if still valid.
---@return nil
local function eon_record_expansion_site_group_units(surface, position, units)
    if not (surface and surface.valid and position and type(units) == "table") then return end
    if not eon_expansion_site_cleanup_enabled(surface) then return end

    local key = eon_expansion_site_cleanup_key(surface, position)
    local records = eon_expansion_site_tracked_unit_records()
    local record = records[key]
    if not record then
        record = {
            surface_index = surface.index,
            position = { x = position.x, y = position.y },
            units = {},
        }
        records[key] = record
    end

    for _, unit in pairs(units) do
        if unit and unit.valid and unit.unit_number then
            record.units[unit.unit_number] = unit
        end
    end
end

---@param key string|nil Cleanup-site key.
---@return integer destroyed Number of tracked units destroyed.
local function eon_destroy_tracked_expansion_site_units(key)
    if not key then return 0 end
    local records = storage.eon_expansion_site_tracked_unit_records
    local record = records and records[key] or nil
    if not record then return 0 end

    local destroyed = 0
    for unit_number, unit in pairs(record.units or {}) do
        if unit and unit.valid then
            unit.destroy({ raise_destroy = false })
            destroyed = destroyed + 1
        end
        record.units[unit_number] = nil
    end

    records[key] = nil
    return destroyed
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
    local target_family = eon_target_unit_family_for_terrain(terrain_family)
    if not target_family then return end

    local old_units = {}
    local replacements = {}
    local changed = false

    for _, unit in pairs(group.members or {}) do
        if unit and unit.valid then
            table.insert(old_units, unit)
            local replacement_name = nil

            if eon_enemy_unit_family(unit.name) ~= target_family then
                replacement_name = eon_replacement_unit_name(unit.name, target_family)
            end

            replacements[unit.unit_number or table_size(old_units)] = replacement_name
            if replacement_name and replacement_name ~= unit.name then
                changed = true
            end
        end
    end

    if not changed then
        eon_record_expansion_site_group_units(surface, destination, group.members or {})
        if eon_schedule_expansion_site_cleanup then
            eon_schedule_expansion_site_cleanup(surface, destination)
        end
        return
    end

    for _, old_unit in pairs(old_units) do
        local replacement_name = replacements[old_unit.unit_number or 0]
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

    eon_record_expansion_site_group_units(surface, destination, group.members or {})
    if eon_schedule_expansion_site_cleanup then
        eon_schedule_expansion_site_cleanup(surface, destination)
    end
end

---@return integer
local function eon_destroy_spawner_owned_units(spawner)
    if not (spawner and spawner.valid and spawner.type == "unit-spawner") then return 0 end

    local ok, units = pcall(function() return spawner.units end)
    if not ok or type(units) ~= "table" then return 0 end

    local destroyed = 0
    for _, unit in pairs(units) do
        if unit and unit.valid then
            unit.destroy({ raise_destroy = false })
            destroyed = destroyed + 1
        end
    end

    return destroyed
end

---@param surface LuaSurface
---@param position MapPosition
eon_schedule_expansion_site_cleanup = function(surface, position)
    if not (surface and surface.valid and position) then return end
    if not eon_expansion_site_cleanup_enabled(surface) then return end

    local key = eon_expansion_site_cleanup_key(surface, position)
    storage.eon_scheduled_expansion_site_cleanup_keys = storage.eon_scheduled_expansion_site_cleanup_keys or {}
    if storage.eon_scheduled_expansion_site_cleanup_keys[key] then return end

    local due_tick = game.tick + EON_EXPANSION_SITE_CLEANUP_TICKS
    local buckets = eon_pending_expansion_site_cleanups()
    buckets[due_tick] = buckets[due_tick] or {}
    storage.eon_scheduled_expansion_site_cleanup_keys[key] = due_tick

    table.insert(buckets[due_tick], {
        key = key,
        surface_index = surface.index,
        position = { x = position.x, y = position.y },
        radius = EON_EXPANSION_SITE_CLEANUP_RADIUS,
    })
end

---@param surface LuaSurface
---@param position MapPosition
---@param radius number
---@return LuaEntity[]
local function eon_find_nearby_enemy_structures(surface, position, radius)
    local existing_enemy_base_names = eon_existing_entity_names(eon_enemy_base_names)
    if table_size(existing_enemy_base_names) == 0 then return {} end

    return surface.find_entities_filtered({
        area = {
            { position.x - radius, position.y - radius },
            { position.x + radius, position.y + radius },
        },
        force = "enemy",
        name = existing_enemy_base_names,
    })
end

---@param entity LuaEntity
---@return integer units_destroyed, integer bases_replaced, integer bases_removed
local function eon_delayed_cleanup_enemy_base(entity)
    if not (entity and entity.valid) then return 0, 0, 0 end

    local variant = eon_enemy_base_variant_by_name[entity.name]
    if not variant then return 0, 0, 0 end

    local surface = entity.surface
    if not (surface and surface.valid) then return 0, 0, 0 end

    local terrain_family = eon_enemy_terrain_family_for_entity(entity)

    if eon_enemy_base_allowed_on_terrain(variant, terrain_family) then
        return 0, 0, 0
    end

    local replacement_name = eon_replacement_enemy_name(variant, terrain_family)
    local position = { x = entity.position.x, y = entity.position.y }
    local force = entity.force
    local owned_units_destroyed = eon_destroy_spawner_owned_units(entity)

    entity.destroy({ raise_destroy = false })
    eon_clear_enemy_expansion_scars(surface, position, variant)

    if replacement_name then
        local created = surface.create_entity({
            name = replacement_name,
            position = position,
            force = force,
            raise_built = false,
        })

        if created and created.valid then
            return owned_units_destroyed, 1, 0
        end
    end

    return owned_units_destroyed, 0, 1
end

---@param record table Pending delayed expansion-site cleanup record.
local function eon_run_expansion_site_cleanup(record)
    local surface = record.surface_index and game.surfaces[record.surface_index] or nil
    local position = record.position
    local radius = record.radius or EON_EXPANSION_SITE_CLEANUP_RADIUS

    if not (surface and surface.valid and position) then return end

    if not eon_expansion_site_cleanup_enabled(surface) then
        eon_destroy_tracked_expansion_site_units(record.key)
        return
    end

    for _, base in pairs(eon_find_nearby_enemy_structures(surface, position, radius)) do
        eon_delayed_cleanup_enemy_base(base)
    end

    for _, base in pairs(eon_find_nearby_enemy_structures(surface, position, radius)) do
        eon_destroy_spawner_owned_units(base)
    end

    eon_destroy_tracked_expansion_site_units(record.key)
end

---@param event NthTickEventData
local function eon_on_nth_tick_expansion_site_cleanups(event)
    local buckets = storage.eon_pending_expansion_site_cleanups
    if not buckets then return end

    for due_tick, bucket in pairs(buckets) do
        if due_tick <= event.tick then
            buckets[due_tick] = nil
            for _, record in pairs(bucket) do
                if record.key and storage.eon_scheduled_expansion_site_cleanup_keys then
                    storage.eon_scheduled_expansion_site_cleanup_keys[record.key] = nil
                end
                eon_run_expansion_site_cleanup(record)
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

    eon_schedule_expansion_site_cleanup(surface, entity.position)

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

script.on_event(defines.events.on_unit_group_finished_gathering, eon_on_unit_group_finished_gathering)
script.on_event(defines.events.on_biter_base_built, function(event)
    eon_enforce_enemy_base_entity(event.entity)
end)

script.on_event(defines.events.script_raised_built, function(event)
    eon_enforce_enemy_base_entity(event.entity)
end)

script.on_nth_tick(EON_EXPANSION_SITE_CLEANUP_INTERVAL, eon_on_nth_tick_expansion_site_cleanups)

script.on_event(defines.events.on_chunk_generated, function(event)
    local surface = event.surface
    if not (surface and surface.valid) then return end

    if surface_names[surface.name] then
        process_area(surface, event.area)
    end
end)


local explosive_biter_autoplace_entities = {
    "explosive-biter-spawner",
    "small-explosive-worm-turret",
    "medium-explosive-worm-turret",
    "big-explosive-worm-turret",
    "behemoth-explosive-worm-turret",
    "leviathan-explosive-worm-turret",
    "mother-explosive-worm-turret"
}

---@param control table|nil
---@return table
local function eon_copy_autoplace_control(control)
    if not control then return {} end

    local copy = {}
    for key, value in pairs(control) do
        copy[key] = value
    end
    return copy
end

---@return nil
local function eon_enable_explosive_biters_on_existing_nauvis()
    if not script.active_mods["Explosive_biters"] then return end

    local surface = game.surfaces["nauvis"]
    if not surface then return end

    local map_gen_settings = surface.map_gen_settings
    map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}

    if not map_gen_settings.autoplace_controls["hot_enemy_base"] then
        map_gen_settings.autoplace_controls["hot_enemy_base"] =
            eon_copy_autoplace_control(map_gen_settings.autoplace_controls["enemy-base"])
    end

    map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
    map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or { settings = {} }
    map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

    for _, entity_name in pairs(explosive_biter_autoplace_entities) do
        if prototypes.entity[entity_name] and prototypes.entity[entity_name].autoplace_specification then
            map_gen_settings.autoplace_settings.entity.settings[entity_name] =
                map_gen_settings.autoplace_settings.entity.settings[entity_name] or {}
        end
    end

    surface.map_gen_settings = map_gen_settings
end

script.on_init(function()
    eon_enable_explosive_biters_on_existing_nauvis()
end)

script.on_configuration_changed(function()
    eon_enable_explosive_biters_on_existing_nauvis()
end)
