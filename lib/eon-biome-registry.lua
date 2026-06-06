local water = require("lib.eon-water-tiles")
local resources = require("lib.eon-resource-registry")
local aquilo = require("lib.eon-aquilo-registry")
local gleba = require("lib.eon-gleba-registry")
local fulgora = require("lib.eon-fulgora-registry")
local nauvis = require("lib.eon-nauvis-registry")

local biomes = {}

biomes.names = {
    "nauvis",
    "gleba",
    "vulcanus",
    "aquilo",
    "fulgora",
}

biomes.by_name = {
    nauvis = {
        source_planet = nauvis.planet_name,
        default_target_surface = nauvis.planet_name,
        territory_mask = "eon_mask_nauvis_territory",
        native_mask_policy = nauvis.native_mask_policy,
        resources = resources.by_biome.nauvis,
        tiles = nauvis.tiles,
        decoratives = nauvis.decoratives,
        entities = nauvis.entities,
    },

    gleba = {
        source_planet = "gleba",
        default_target_surface = "nauvis",
        territory_mask = "eon_mask_gleba_territory",
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
        territory_mask = "eon_mask_vulcano_terrain",
        coverage_mask = "eon_mask_vulcano_coverage",
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
        territory_mask = "eon_mask_aquilo_territory",
        resource_mask = "eon_mask_aquilo_resource_tiles",
        resources = resources.by_biome.aquilo,
        tiles = aquilo.tiles,
        decoratives = aquilo.decoratives,
        entities = aquilo.entities,
        autoplace_controls = aquilo.autoplace_controls,
    },

    fulgora = {
        source_planet = "fulgora",
        default_target_surface = "fulgora",
        water_tiles = fulgora.water_tiles,
        oil_ocean_tiles = fulgora.oil_ocean_tiles,
        scrap_resource = fulgora.scrap_resource,
        cliff_control = fulgora.cliff_control,
    },
}

biomes.water_tiles = water
biomes.resources = resources

---@param biome_name string
---@return table|nil
function biomes.get(biome_name)
    return biomes.by_name[biome_name]
end

---@param biome_name string
---@param mode table|nil
---@return string|nil
function biomes.target_surface_for(biome_name, mode)
    local biome = biomes.get(biome_name)
    if not biome then return nil end

    if biome_name == "aquilo" and mode and mode.aquilo_on_fulgora then
        return biome.alternate_target_surface
    end

    return biome.default_target_surface
end

return biomes
