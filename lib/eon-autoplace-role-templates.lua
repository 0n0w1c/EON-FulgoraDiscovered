local eon_autoplace_role_templates = {}

---@return table
function eon_autoplace_role_templates.templates()
    return {
        solid_resource_on_nauvis = {
            prototype_type = "resource",
            analogue = "iron-ore",
            water_policy = "land-only",
            notes = "Use for imported solid ore resources when behavior is intentionally redesigned.",
        },
        fluid_resource_on_nauvis = {
            prototype_type = "resource",
            analogue = "crude-oil",
            water_policy = "land-only",
            notes = "Use for imported fluid resources such as lithium brine and fluorine vents.",
        },
        decorative_on_nauvis = {
            prototype_type = "optimized-decorative",
            analogue = "nauvis decoratives",
            water_policy = "land-only by default, water-only by exception",
        },
        simple_entity_on_nauvis = {
            prototype_type = "simple-entity",
            analogue = "Nauvis rocks/simple entities",
            water_policy = "land-only by default",
        },
        water_tile = {
            prototype_type = "tile",
            analogue = "water/deepwater",
            water_policy = "blocks ordinary autoplaced entities",
        },
    }
end

return eon_autoplace_role_templates
