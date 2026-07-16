local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_stagnation", path = "trial_stagnation.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "arcane_stagnation",
    name = "The Stagnation",
    booster_kinds = { "Arcana" },
    kind = "multi_suit",
    need = 2,
    loc = {
        "The selected hand must",
        "have at least {C:attention}2{} multi-suit",
        "representations",
    },
})
