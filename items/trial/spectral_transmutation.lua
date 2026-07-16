local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_transmutation", path = "trial_transmutation.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "spectral_transmutation",
    name = "The Transmutation",
    booster_kinds = { "Spectral" },
    placeholder_set = "Spectral",
    kind = "spectral_transmutation",
    need = 1,
    loc = { "The selected hand must contain", "at least {C:attention}1{} {C:dark_edition}Polychrome{} or {C:dark_edition}Negative{}", "and {C:attention}2{} {C:dark_edition}Foil{} or {C:dark_edition}Holographic{} representations" },
})
