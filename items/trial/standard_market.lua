local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "trial_market",
    path = "trial_market.png",
    px = 34,
    py = 34,
    frames = 21,
    atlas_table = "ANIMATION_ATLAS",
})

CL.barter.register_trial({
    key = "standard_market",
    name = "The Market",
    booster_kinds = { "Standard" },
    standard_card = true,
    kind = "standard_market",
    need = 5,
    loc = {
        "The selected hand must have",
        "at least {C:attention}5 odd-ranked{}",
        "representations",
    },
})
