local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_comments", path = "trial_comments.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "arcane_comments",
    name = "The Comments",
    booster_kinds = { "Arcana" },
    kind = "suit",
    suit = "Clubs",
    need = 3,
    loc = {
        "The selected hand must",
        "have at least {C:attention}3{} {C:clubs}Club{}",
        "representations",
    },
})
