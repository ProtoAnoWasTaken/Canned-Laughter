local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_desolate", path = "trial_desolate.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "arcane_desolate",
    name = "The Desolate",
    booster_kinds = { "Arcana" },
    kind = "suit",
    suit = "Diamonds",
    need = 3,
    loc = {
        "The selected hand must",
        "have at least {C:attention}3{} {C:diamonds}Diamond{}",
        "representations",
    },
})
