local registry = {}

registry.music_clones = {
    { source = "gleba",    target = "nauvis" },
    { source = "vulcanus", target = "nauvis" },
    { source = "aquilo",   target = "fulgora" },
}

registry.persistent_sound_merges = {
    { source = "gleba",    target = "nauvis" },
    { source = "vulcanus", target = "nauvis" },
    { source = "aquilo",   target = "fulgora" },
}

registry.persistent_sound_fields = {
    "base_ambience",
    "wind",
    "semi_persistent",
}

registry.excluded_track_types = {
    ["hero-track"] = true,
}

return registry
