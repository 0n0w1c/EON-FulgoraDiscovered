local nauvis = {}

local function make_set(names)
    local set = {}
    for _, name in ipairs(names) do
        set[name] = true
    end
    return set
end

nauvis.planet_name = "nauvis"

nauvis.native_mask_policy = "mask_nauvis_territory"

nauvis.tiles = {
    "grass-1",
    "grass-2",
    "grass-3",
    "grass-4",
    "dry-dirt",
    "dirt-1",
    "dirt-2",
    "dirt-3",
    "dirt-4",
    "dirt-5",
    "dirt-6",
    "dirt-7",
    "sand-1",
    "sand-2",
    "sand-3",
    "red-desert-0",
    "red-desert-1",
    "red-desert-2",
    "red-desert-3",
}

nauvis.decoratives = {
    "cracked-mud-decal",
    "dark-mud-decal",
    "lichen-decal",
    "light-mud-decal",
    "small-rock",
    "small-sand-rock",
    "tiny-rock",
    "brown-asterisk",
    "brown-asterisk-mini",
    "brown-carpet-grass",
    "brown-fluff",
    "brown-fluff-dry",
    "brown-hairy-grass",
    "garballo",
    "garballo-mini-dry",
    "green-asterisk",
    "green-asterisk-mini",
    "green-bush-mini",
    "green-carpet-grass",
    "green-croton",
    "green-desert-bush",
    "green-hairy-grass",
    "green-pita",
    "green-pita-mini",
    "green-small-grass",
    "medium-rock",
    "medium-sand-rock",
    "red-asterisk",
    "red-croton",
    "red-desert-bush",
    "red-desert-decal",
    "red-pita",
    "sand-decal",
    "sand-dune-decal",
    "white-desert-bush",
}

nauvis.entities = {
    "big-rock",
    "big-sand-rock",
    "huge-rock",
}

nauvis.tile_set = make_set(nauvis.tiles)
nauvis.decorative_set = make_set(nauvis.decoratives)
nauvis.entity_set = make_set(nauvis.entities)

nauvis.native_autoplace_by_type = {
    tile = nauvis.tiles,
    ["optimized-decorative"] = nauvis.decoratives,
    ["simple-entity"] = nauvis.entities,
}

---@return table<string, string[]>
function nauvis.native_autoplace_manifest()
    return nauvis.native_autoplace_by_type
end

return nauvis
