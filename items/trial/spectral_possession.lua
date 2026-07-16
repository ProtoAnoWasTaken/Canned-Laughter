local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_possession", path = "trial_possession.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "spectral_possession",
    name = "The Possession",
    booster_kinds = { "Spectral" },
    placeholder_set = "Spectral",
    kind = "spectral_possession",
    need = 1,
    loc = { "The selected hand must contain", "an {C:attention}Ace{} representation and at least", "{C:attention}1{} {C:dark_edition}Negative{} representation" },
})
