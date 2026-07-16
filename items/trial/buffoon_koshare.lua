local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_koshare", path = "trial_koshare.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "buffoon_koshare",
    name = "The Koshare",
    booster_kinds = { "Buffoon" },
    placeholder_set = "Joker",
    kind = "joker_rarity_or",
    rarity_a = 3,
    need_a = 2,
    rarity_b = 4,
    need_b = 1,
    need = 2,
    loc = {
        "The selected hand must",
        "have at least {C:attention}2{} {C:attention}Rare{} Joker",
        "representations or {C:attention}1{} {C:attention}Legendary{}",
        "Joker representation",
    },
})
