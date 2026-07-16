local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_pierrot", path = "trial_pierrot.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "buffoon_pierrot",
    name = "The Pierrot",
    booster_kinds = { "Buffoon" },
    placeholder_set = "Joker",
    kind = "joker_rarity",
    rarity = 2,
    need = 2,
    loc = {
        "The selected hand must",
        "have at least {C:attention}2{} {C:attention}Uncommon{}",
        "Joker representations",
    },
})
