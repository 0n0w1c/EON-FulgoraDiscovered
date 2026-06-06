local eon_mode = require("lib.eon-mode")

if eon_mode.aquilo_on_fulgora then
    require("lib.eon-aquilo-on-fulgora-data-updates").apply()
end

require("prototypes.technologies")
require("prototypes.tiles")

require("map-generation.enemies")
require("map-generation.resources-updates")
require("map-generation.terrain")

if mods["craft-deco-2"] then
    require("map-generation.craft-deco-trees")
    require("map-generation.craft-deco-rocks")
end
