require("prototypes.remove-planets")
require("prototypes.surface-conditions")
require("prototypes.planet-sounds")

require("prototypes.patches")

require("lib.eon-final-fixes-fulgora-setup").apply()

require("lib.eon-final-fixes-craft-deco-policy").apply()

require("lib.eon-final-fixes-cold-biter-resistance-policy").apply()

require("lib.eon-final-fixes-planet-routing").apply()

require("lib.eon-final-fixes-enemy-policy").apply()

require("map-generation.planet_compatibility").restore_external_planets()
