local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "trial_town",
    path = "trial_town.png",
    px = 34,
    py = 34,
    frames = 21,
    atlas_table = "ANIMATION_ATLAS",
})

CL.barter.register_trial({
    key = "standard_town",
    name = "The Town",
    booster_kinds = { "Standard" },
    standard_card = true,
    kind = "standard_town",
    need = 5,
    loc = {
        "The selected hand must have",
        "at least {C:attention}5{} representations",
        "between {C:attention}6{} and {C:attention}10{}",
    },
})
