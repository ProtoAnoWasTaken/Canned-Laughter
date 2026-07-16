local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_auguste", path = "trial_auguste.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "buffoon_auguste",
    name = "The Auguste",
    booster_kinds = { "Buffoon" },
    placeholder_set = "Joker",
    kind = "joker_rarity",
    rarity = 1,
    need = 2,
    loc = {
        "The selected hand must",
        "have at least {C:attention}2{} {C:attention}Common{}",
        "Joker representations",
    },
})
