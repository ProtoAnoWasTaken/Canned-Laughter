local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_enlightened", path = "trial_enlightened.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "arcane_enlightened",
    name = "The Enlightened",
    booster_kinds = { "Arcana" },
    kind = "suit",
    suit = "Hearts",
    need = 3,
    loc = {
        "The selected hand must",
        "have at least {C:attention}3{} {C:hearts}Heart{}",
        "representations",
    },
})
