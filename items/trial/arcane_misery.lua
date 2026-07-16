local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_misery", path = "trial_misery.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "arcane_misery",
    name = "The Misery",
    booster_kinds = { "Arcana" },
    kind = "no_suit",
    need = 2,
    loc = {
        "The selected hand must",
        "have at least {C:attention}2{} no-suit",
        "representations",
    },
})
