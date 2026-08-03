local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "trial_house",
    path = "trial_house.png",
    px = 34,
    py = 34,
    frames = 21,
    atlas_table = "ANIMATION_ATLAS",
})

CL.barter.register_trial({
    key = "standard_home",
    name = "The Home",
    booster_kinds = { "Standard" },
    standard_card = true,
    kind = "standard_home",
    need = 5,
    icon_atlas = "canlaugh_trial_house",
    loc = {
        "The selected hand must have",
        "at least {C:attention}5 even-ranked{}",
        "representations",
    },
})
