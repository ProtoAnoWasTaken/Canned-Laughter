local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_voyager", path = "trial_voyager.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "arcane_voyager",
    name = "The Voyager",
    booster_kinds = { "Arcana" },
    kind = "suit",
    suit = "Spades",
    need = 3,
    loc = {
        "The selected hand must",
        "have at least {C:attention}3{} {C:spades}Spade{}",
        "representations",
    },
})
