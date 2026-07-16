local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_reflection", path = "trial_reflection.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "spectral_reflection",
    name = "The Reflection",
    booster_kinds = { "Spectral" },
    placeholder_set = "Spectral",
    kind = "spectral_reflective",
    need = 2,
    loc = { "The selected hand must", "have at least {C:attention}2{} {C:dark_edition}Foil{} or {C:dark_edition}Holographic{} representations" },
})
