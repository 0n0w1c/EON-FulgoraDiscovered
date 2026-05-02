--------------------------------------------------------------------------------
-- Add enemies from other planets
--------------------------------------------------------------------------------

local terrain = require("map-generation.terrain")
local space_enemy_autoplace = require("__space-age__.prototypes.entity.space-enemy-autoplace-utils")

--------------------------------------------------------------------------------
-- MARK: Remove Nauvis enemies aka biters, spitters and spawners from surface that does not belong to nauvis
--------------------------------------------------------------------------------

data:extend({
    -- Default noise expressions for nauvis enemies
    {
        type = "noise-expression",
        name = "biter_spawner",
        expression = data.raw["unit-spawner"]["biter-spawner"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "spitter_spawner",
        expression = data.raw["unit-spawner"]["spitter-spawner"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "small_worm_turret",
        expression = data.raw["turret"]["small-worm-turret"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "medium_worm_turret",
        expression = data.raw["turret"]["medium-worm-turret"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "big_worm_turret",
        expression = data.raw["turret"]["big-worm-turret"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "behemoth_worm_turret",
        expression = data.raw["turret"]["behemoth-worm-turret"].autoplace.probability_expression
    },
})

data.raw["unit-spawner"]["biter-spawner"].autoplace.probability_expression = "eon_mask_nauvis_territory(biter_spawner)"
data.raw["unit-spawner"]["spitter-spawner"].autoplace.probability_expression =
"eon_mask_nauvis_territory(spitter_spawner)"

data.raw["turret"]["small-worm-turret"].autoplace.probability_expression = "eon_mask_nauvis_territory(small_worm_turret)"
data.raw["turret"]["medium-worm-turret"].autoplace.probability_expression =
"eon_mask_nauvis_territory(medium_worm_turret)"

data.raw["turret"]["big-worm-turret"].autoplace.probability_expression = "eon_mask_nauvis_territory(big_worm_turret)"
data.raw["turret"]["behemoth-worm-turret"].autoplace.probability_expression =
"eon_mask_nauvis_territory(behemoth_worm_turret)"

--------------------------------------------------------------------------------
-- MARK: Add Vulcanus enemies aka demolishers
--------------------------------------------------------------------------------

data.raw["planet"]["nauvis"].map_gen_settings.territory_settings =
    data.raw["planet"]["vulcanus"].map_gen_settings.territory_settings

data.raw["noise-expression"]["demolisher_starting_area"].expression = "if(eon_vulcano_coverage > 0.2, 0, 1)"

--data.raw["noise-expression"]["demolisher_variation_expression"].expression =
--"floor(clamp(distance / (30 * 32) - 0.25, 0, 4)) + (-99 * no_enemies_mode)"

data.raw["noise-expression"]["demolisher_variation_expression"].expression =
"floor(clamp(distance / (50 * 32) - 0.25, 0, 4)) + (-99 * no_enemies_mode)"

--------------------------------------------------------------------------------
-- MARK: Add Gleba enemies aka strafer, stompers and wriggler pentapods
--------------------------------------------------------------------------------

data.raw["planet"]["nauvis"].map_gen_settings.autoplace_controls["gleba_enemy_base"] = {}

-- ---------------------------------------------------------------------------
-- Gleba enemy tuning constants
-- ---------------------------------------------------------------------------

local gleba_enemy_frequency = "var('control:gleba_enemy_base:frequency')"
local gleba_enemy_size = "sqrt(var('control:gleba_enemy_base:size'))"

local enemy_cap = 0.004
local fertile_cap = 0.00015
local fertile_scale = 2000
local green_penalty = 12000

data.raw["noise-expression"]["gleba_spawner"].expression =
    gleba_enemy_frequency .. " * eon_mask_gleba_territory(" ..
    "max(" ..
    "0.001 * gleba_starting_enemies * " .. gleba_enemy_size .. ", " ..
    "max(" ..
    "min(" .. enemy_cap .. ", enemy_autoplace_base(0, 8)), " ..
    "min(" .. fertile_cap ..
    ", gleba_fertile_spots_coastal * " .. fertile_scale ..
    " - gleba_biome_mask_green * " .. green_penalty ..
    ")" ..
    ") * (distance > 500 * gleba_starting_area_multiplier)" ..
    ") * gleba_above_deep_water_mask" ..
    ")"

data.raw["noise-expression"]["gleba_spawner_small"].expression =
    gleba_enemy_frequency .. " * eon_mask_gleba_territory(" ..
    "max(" ..
    "0.002 * gleba_starting_enemies * " .. gleba_enemy_size .. ", " ..
    "0.002 * gleba_starting_enemies_safe * " .. gleba_enemy_size .. ", " ..
    "min(" .. enemy_cap .. ", enemy_autoplace_base(0, 8)), " ..
    "min(" .. fertile_cap ..
    ", gleba_fertile_spots_coastal * " .. fertile_scale ..
    " - gleba_biome_mask_green * " .. green_penalty ..
    ")" ..
    ") * gleba_above_deep_water_mask" ..
    ")"
