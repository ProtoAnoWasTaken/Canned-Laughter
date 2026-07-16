local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_encore", path = "trial_encore.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "buffoon_encore",
    name = "The Encore",
    booster_kinds = { "Buffoon" },
    placeholder_set = "Joker",
    kind = "joker_different_rarities",
    need = 3,
    loc = {
        "The selected hand must",
        "have at least {C:attention}3{} Joker representations",
        "with different rarities",
    },
})
