local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_superstition", path = "trial_superstition.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "spectral_superstition",
    name = "The Superstition",
    booster_kinds = { "Spectral" },
    placeholder_set = "Spectral",
    kind = "spectral_same_edition",
    need = 3,
    loc = { "The selected hand must", "have at least {C:attention}3{} representations", "of the same edition" },
})
