local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "trial_court",
    path = "trial_court.png",
    px = 34,
    py = 34,
    frames = 21,
    atlas_table = "ANIMATION_ATLAS",
})

CL.barter.register_trial({
    key = "standard_court",
    name = "The Court",
    booster_kinds = { "Standard" },
    standard_card = true,
    kind = "standard_court",
    need = 3,
    loc = {
        "The selected hand must have",
        "a {C:attention}Jack{}, a {C:attention}Queen{}, and a {C:attention}King{}",
    },
})
