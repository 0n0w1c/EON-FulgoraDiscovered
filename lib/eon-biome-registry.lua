local water = require("lib.eon-water-tiles")
local resources = require("lib.eon-resource-registry")
local aquilo = require("lib.eon-aquilo-registry")
local gleba = require("lib.eon-gleba-registry")
local fulgora = require("lib.eon-fulgora-registry")
local nauvis = require("lib.eon-nauvis-registry")

---@class EonBiomeMasks
---@field territory string
---@field off_territory string
---@field resource_territory string|nil
---@field coverage string|nil
---@field off_coverage string|nil
---@field terrain string|nil
---@field off_terrain string|nil
---@field territory_on_fulgora string|nil
---@field off_territory_on_fulgora string|nil
---@field resource_tiles string|nil
---@field off_resource_tiles string|nil
---@field decorative_territory string|nil
---@field off_decorative_territory string|nil
---@field snow_decorative_territory string|nil
---@field off_snow_decorative_territory string|nil
---@field snow_decorative_territory_on_fulgora string|nil
---@field ammonia_ocean string|nil
---@field off_ammonia_ocean string|nil
---@field ammonia_ocean_core_on_fulgora string|nil
---@field off_ocean_edge_on_fulgora string|nil
---@field aquilo_territory string|nil
---@field off_aquilo_territory string|nil
---@field off_oil_ocean string|nil

---@class EonBiomeDefinition
---@field source_planet string
---@field default_target_surface string
---@field alternate_target_surface string|nil
---@field territory_mask string|nil
---@field coverage_mask string|nil
---@field resource_mask string|nil
---@field masks EonBiomeMasks
---@field native_mask_policy string|nil
---@field resources table|nil
---@field tiles string[]|nil
---@field water_tiles string[]|nil
---@field oil_ocean_tiles string[]|nil
---@field decoratives string[]|nil
---@field entities string[]|nil
---@field autoplace_controls table|nil
---@field agriculture_probability_expressions table|nil
---@field modes table<string, string>|nil
---@field scrap_resource string|nil
---@field cliff_control string|nil

---@class EonBiomeRegistry
---@field names string[]
---@field by_name table<string, EonBiomeDefinition>
---@field water_tiles table
---@field resources table
---@field get fun(biome_name:string):EonBiomeDefinition|nil
---@field target_surface_for fun(biome_name:string, mode:table|nil):string|nil

local biomes

---@type table<string, EonBiomeMasks>
local mask_names = {
    nauvis = {
        territory = "eon_mask_nauvis_territory",
        off_territory = "eon_mask_off_nauvis_territory",
        resource_territory = "eon_mask_resource_territory",
    },
    gleba = {
        territory = "eon_mask_gleba_territory",
        off_territory = "eon_mask_off_gleba_territory",
    },
    vulcanus = {
        territory = "eon_mask_vulcano_terrain",
        off_territory = "eon_mask_off_vulcano_terrain",
        coverage = "eon_mask_vulcano_coverage",
        off_coverage = "eon_mask_off_vulcano_coverage",
        terrain = "eon_mask_vulcano_terrain",
        off_terrain = "eon_mask_off_vulcano_terrain",
    },
    aquilo = {
        territory = "eon_mask_aquilo_territory",
        off_territory = "eon_mask_off_aquilo_territory",
        territory_on_fulgora = "eon_mask_aquilo_territory_on_fulgora",
        off_territory_on_fulgora = "eon_mask_off_aquilo_territory_on_fulgora",
        resource_tiles = "eon_mask_aquilo_resource_tiles",
        off_resource_tiles = "eon_mask_off_aquilo_resource_tiles",
        decorative_territory = "eon_mask_aquilo_territory",
        off_decorative_territory = "eon_mask_off_aquilo_territory",
        snow_decorative_territory = "eon_mask_aquilo_territory",
        off_snow_decorative_territory = "eon_mask_off_aquilo_territory",
        snow_decorative_territory_on_fulgora = "eon_mask_fulgora_aquilo_snow_decorative_territory",
        ammonia_ocean = "eon_mask_ammonia_ocean",
        off_ammonia_ocean = "eon_mask_off_ammonia_ocean",
        ammonia_ocean_core_on_fulgora = "eon_mask_fulgora_ammonia_ocean_core",
        off_ocean_edge_on_fulgora = "eon_mask_off_aquilo_ocean_edge",
    },
    fulgora = {
        territory = "eon_mask_fulgora_territory",
        off_territory = "eon_mask_off_fulgora_territory",
        aquilo_territory = "eon_mask_fulgora_aquilo_territory",
        off_aquilo_territory = "eon_mask_off_fulgora_aquilo_territory",
        off_oil_ocean = "eon_mask_off_fulgora_oil_ocean",
    },
}

---@param biome_name string
---@return EonBiomeDefinition|nil
local function get_biome(biome_name)
    return biomes.by_name[biome_name]
end

---@param biome_name string
---@param mode table|nil
---@return string|nil
local function target_surface_for(biome_name, mode)
    local biome = get_biome(biome_name)
    if not biome then return nil end

    if biome_name == "aquilo" and mode and mode.aquilo_on_fulgora then
        return biome.alternate_target_surface
    end

    return biome.default_target_surface
end

---@type EonBiomeRegistry
biomes = {
    names = {
        "nauvis",
        "gleba",
        "vulcanus",
        "aquilo",
        "fulgora",
    },

    by_name = {
        nauvis = {
            source_planet = nauvis.planet_name,
            default_target_surface = nauvis.planet_name,
            territory_mask = mask_names.nauvis.territory,
            masks = mask_names.nauvis,
            native_mask_policy = nauvis.native_mask_policy,
            resources = resources.by_biome.nauvis,
            tiles = nauvis.tiles,
            decoratives = nauvis.decoratives,
            entities = nauvis.entities,
        },

        gleba = {
            source_planet = "gleba",
            default_target_surface = "nauvis",
            territory_mask = mask_names.gleba.territory,
            masks = mask_names.gleba,
            resources = resources.by_biome.gleba,
            tiles = gleba.tiles,
            decoratives = gleba.decoratives,
            entities = gleba.entities,
            autoplace_controls = gleba.autoplace_controls,
            agriculture_probability_expressions = gleba.agriculture_probability_expressions,
        },

        vulcanus = {
            source_planet = "vulcanus",
            default_target_surface = "nauvis",
            territory_mask = mask_names.vulcanus.territory,
            coverage_mask = mask_names.vulcanus.coverage,
            masks = mask_names.vulcanus,
            resources = resources.by_biome.vulcanus,
            modes = {
                volcano_spots = "scattered volcano/lava features when Aquilo remains on Nauvis",
                northern_region = "broad northern Vulcanus region when Aquilo is moved to Fulgora",
            },
        },

        aquilo = {
            source_planet = "aquilo",
            default_target_surface = "nauvis",
            alternate_target_surface = "fulgora",
            territory_mask = mask_names.aquilo.territory,
            resource_mask = mask_names.aquilo.resource_tiles,
            masks = mask_names.aquilo,
            resources = resources.by_biome.aquilo,
            tiles = aquilo.tiles,
            decoratives = aquilo.decoratives,
            entities = aquilo.entities,
            autoplace_controls = aquilo.autoplace_controls,
        },

        fulgora = {
            source_planet = "fulgora",
            default_target_surface = "fulgora",
            masks = mask_names.fulgora,
            water_tiles = fulgora.water_tiles,
            oil_ocean_tiles = fulgora.oil_ocean_tiles,
            scrap_resource = fulgora.scrap_resource,
            cliff_control = fulgora.cliff_control,
        },
    },

    water_tiles = water,
    resources = resources,
    get = get_biome,
    target_surface_for = target_surface_for,
}

return biomes
