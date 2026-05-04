local data_util = require("data-util")

local move_aquilo_to_fulgora =
    settings.startup["eon-fd-aquilo-on-fulgora"] and
    settings.startup["eon-fd-aquilo-on-fulgora"].value

local function copy_nauvis_aquilo_connection_to_fulgora()
    if not move_aquilo_to_fulgora then
        return
    end

    local source_connection = data.raw["space-connection"]["fulgora-aquilo"]
    local nauvis_fulgora = data.raw["space-connection"]["nauvis-fulgora"]

    if not source_connection or not nauvis_fulgora then
        return
    end

    nauvis_fulgora.asteroid_spawn_definitions =
        table.deepcopy(source_connection.asteroid_spawn_definitions)
end

if data.raw.planet["aquilo"] then
    data.raw.planet["aquilo"].map_gen_settings = nil
    data.raw.planet["aquilo"].hidden = true
end

if data.raw.planet["gleba"] then
    data.raw.planet["gleba"].map_gen_settings = nil
    data.raw.planet["gleba"].hidden = true
end

if data.raw.planet["vulcanus"] then
    data.raw.planet["vulcanus"].map_gen_settings = nil
    data.raw.planet["vulcanus"].hidden = true
end

data_util.delete_prototype("space-connection", "nauvis-vulcanus")
data_util.delete_prototype("space-connection", "nauvis-gleba")
data_util.delete_prototype("space-connection", "vulcanus-gleba")
data_util.delete_prototype("space-connection", "gleba-aquilo")
data_util.delete_prototype("space-connection", "gleba-fulgora")
copy_nauvis_aquilo_connection_to_fulgora()

data_util.delete_prototype("space-connection", "fulgora-aquilo")

local edge = data.raw["space-connection"]["aquilo-solar-system-edge"]

if edge then
    local fulgora_edge = table.deepcopy(edge)

    fulgora_edge.name = "fulgora-solar-system-edge"
    fulgora_edge.from = "fulgora"

    fulgora_edge.icons = {
        {
            icon = "__space-age__/graphics/icons/planet-route.png"
        },
        {
            icon = "__space-age__/graphics/icons/fulgora.png",
            icon_size = 64,
            scale = 0.333,
            shift = { -6, -6 }
        },
        {
            icon = "__space-age__/graphics/icons/solar-system-edge.png",
            icon_size = 64,
            scale = 0.333,
            shift = { 6, 6 }
        }
    }

    data:extend({ fulgora_edge })

    data_util.delete_prototype("space-connection", "aquilo-solar-system-edge")
end

--data.raw["space-connection"]["aquilo-solar-system-edge"].from = "fulgora"
--data_util.delete_prototype("space-connection", "aquilo-solar-system-edge")

-- remove space age menu simulations that break
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_solar_power_construction = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_lab = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_burner_city = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_mining_defense = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_forest_fire = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_oil_pumpjacks = nil  -- Safe simulations
data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_oil_refinery = nil
data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_early_smelting = nil -- This one crashes after it finishes
data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_train_station = nil
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_logistic_robots = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_nuclear_power = nil  -- Safe simulations
data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_train_junction = nil
data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_artillery = nil
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_biter_base_spidertron = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_biter_base_artillery = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_biter_base_laser_defense = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_biter_base_player_attack = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_biter_base_steamrolled = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_chase_player = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_big_defense = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_brutal_defeat = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_spider_ponds = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_uranium_processing = nil  -- Safe simulations

-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_ship_rails = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_river_bridge = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_t_section = nil  -- Safe simulations

-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_biolab = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_tank_building = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_power_up = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_bus = nil  -- Safe simulations
-- data.raw["utility-constants"]["default"].main_menu_simulations.platform_science = nil  -- Safe simulations
data.raw["utility-constants"]["default"].main_menu_simulations.platform_moving = nil
data.raw["utility-constants"]["default"].main_menu_simulations.platform_messy_nuclear = nil
data.raw["utility-constants"]["default"].main_menu_simulations.vulcanus_lava_forge = nil
data.raw["utility-constants"]["default"].main_menu_simulations.vulcanus_crossing = nil
data.raw["utility-constants"]["default"].main_menu_simulations.vulcanus_punishmnent = nil
data.raw["utility-constants"]["default"].main_menu_simulations.vulcanus_sulfur_drop = nil
data.raw["utility-constants"]["default"].main_menu_simulations.gleba_agri_towers = nil
data.raw["utility-constants"]["default"].main_menu_simulations.gleba_pentapod_ponds = nil
data.raw["utility-constants"]["default"].main_menu_simulations.gleba_egg_escape = nil
data.raw["utility-constants"]["default"].main_menu_simulations.gleba_farm_attack = nil
data.raw["utility-constants"]["default"].main_menu_simulations.gleba_grotto = nil
data.raw["utility-constants"]["default"].main_menu_simulations.aquilo_send_help = nil
data.raw["utility-constants"]["default"].main_menu_simulations.aquilo_starter = nil
data.raw["utility-constants"]["default"].main_menu_simulations.nauvis_rocket_factory = nil

-- delete technologies
data_util.hide_prototype("technology", "planet-discovery-aquilo")
data_util.hide_prototype("technology", "planet-discovery-gleba")
data_util.hide_prototype("technology", "planet-discovery-vulcanus")

-- hide unused controls
data.raw["autoplace-control"]["aquilo_crude_oil"].hidden = true
data.raw["autoplace-control"]["gleba_stone"].hidden = true
data.raw["autoplace-control"]["gleba_cliff"].hidden = true
data.raw["autoplace-control"]["vulcanus_coal"].hidden = true
