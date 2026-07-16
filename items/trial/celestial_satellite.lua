local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_satellite", path = "trial_satellite.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "celestial_satellite",
    name = "The Satellite",
    booster_kinds = { "Celestial" },
    placeholder_set = "Planet",
    kind = "body",
    body = "gaseous",
    need = 3,
    loc = {
        "The selected hand must",
        "have at least {C:attention}3{}",
        "{C:attention}gaseous{} bodies",
    },
})
