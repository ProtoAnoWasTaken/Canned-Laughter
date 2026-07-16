local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_diluvion", path = "trial_diluvion.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "spectral_diluvion",
    name = "The Diluvion",
    booster_kinds = { "Spectral" },
    placeholder_set = "Spectral",
    kind = "spectral_unique_editions",
    need = 3,
    loc = { "The selected hand must", "have at least {C:attention}3{} unique", "editions represented" },
})
