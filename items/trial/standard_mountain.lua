local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "trial_mountain",
    path = "trial_mountain.png",
    px = 34,
    py = 34,
    frames = 21,
    atlas_table = "ANIMATION_ATLAS",
})

CL.barter.register_trial({
    key = "standard_mountain",
    name = "The Mountain",
    booster_kinds = { "Standard" },
    standard_card = true,
    kind = "standard_mountain",
    need = 3,
    loc = {
        "The selected hand must have",
        "at least {C:attention}3 Aces{}",
        "representations",
    },
})
