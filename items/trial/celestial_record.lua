local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_record", path = "trial_record.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "celestial_record",
    name = "The Record",
    booster_kinds = { "Celestial" },
    placeholder_set = "Planet",
    kind = "different_hands",
    need = 3,
    loc = {
        "The selected hand must",
        "represent at least {C:attention}3{}",
        "different poker hands",
    },
})
