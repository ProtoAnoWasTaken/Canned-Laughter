local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_precognition", path = "trial_precognition.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "spectral_precognition",
    name = "The Precognition",
    booster_kinds = { "Spectral" },
    placeholder_set = "Spectral",
    kind = "spectral_same_card",
    need = 3,
    loc = { "The selected hand must", "have at least {C:attention}3{} representations", "of the same card" },
})
