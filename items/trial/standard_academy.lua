local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "trial_academy",
    path = "trial_academy.png",
    px = 34,
    py = 34,
    frames = 21,
    atlas_table = "ANIMATION_ATLAS",
})

CL.barter.register_trial({
    key = "standard_academy",
    name = "The Academy",
    booster_kinds = { "Standard" },
    standard_card = true,
    kind = "standard_academy",
    need = 5,
    loc = {
        "The selected hand must have",
        "at least {C:attention}5{} representations",
        "between {C:attention}2{} and {C:attention}5{}",
    },
})
