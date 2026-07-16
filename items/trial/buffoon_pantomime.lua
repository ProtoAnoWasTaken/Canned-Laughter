local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_pantomime", path = "trial_pantomime.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "buffoon_pantomime",
    name = "The Pantomime",
    booster_kinds = { "Buffoon" },
    placeholder_set = "Joker",
    kind = "joker_output",
    output = "effect",
    need = 2,
    loc = {
        "The selected hand must",
        "have at least {C:attention}2{} effect-providing",
        "Joker representations",
    },
})
