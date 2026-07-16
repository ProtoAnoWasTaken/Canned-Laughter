local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_quasar", path = "trial_quasar.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "celestial_quasar",
    name = "The Quasar",
    booster_kinds = { "Celestial" },
    placeholder_set = "Planet",
    kind = "hand_requirement",
    requirement = "flush",
    need = 3,
    loc = {
        "The selected hand must",
        "have at least {C:attention}3{} poker hands",
        "requiring a {C:attention}Flush{}",
    },
})
