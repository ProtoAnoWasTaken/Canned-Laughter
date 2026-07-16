local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_clown", path = "trial_clown.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "buffoon_clown",
    name = "The Clown",
    booster_kinds = { "Buffoon" },
    placeholder_set = "Joker",
    kind = "joker_output",
    output = "chips",
    need = 2,
    loc = {
        "The selected hand must",
        "have at least {C:attention}2{} Joker representations",
        "that produce {C:chips}Chips{}",
    },
})
