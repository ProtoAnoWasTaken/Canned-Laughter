local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_farce", path = "trial_farce.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "buffoon_farce",
    name = "The Farce",
    booster_kinds = { "Buffoon" },
    placeholder_set = "Joker",
    kind = "joker_output",
    output = "mult",
    need = 2,
    loc = {
        "The selected hand must",
        "have at least {C:attention}2{} Joker representations",
        "that produce {C:mult}Mult{}",
    },
})
