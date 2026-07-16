local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_jurist", path = "trial_jurist.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "arcane_jurist",
    name = "The Jurist",
    booster_kinds = { "Arcana" },
    kind = "face",
    need = 3,
    loc = {
        "The selected hand must",
        "have at least {C:attention}3{} face",
        "representations",
    },
})
