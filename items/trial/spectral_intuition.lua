local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_intuition", path = "trial_intuition.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "spectral_intuition",
    name = "The Intuition",
    booster_kinds = { "Spectral" },
    placeholder_set = "Spectral",
    kind = "spectral_unique_cards",
    need = 3,
    loc = { "The selected hand must", "have at least {C:attention}3{} unique", "playing card representations" },
})
