local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "trial_message", path = "trial_message.png", px = 34, py = 34, frames = 21, atlas_table = "ANIMATION_ATLAS" })

CL.barter.register_trial({
    key = "celestial_message",
    name = "The Message",
    booster_kinds = { "Celestial" },
    placeholder_set = "Planet",
    kind = "secret_hand",
    need = 1,
    in_pool = function()
        return CL.barter and CL.barter.has_unlocked_secret_hand and CL.barter.has_unlocked_secret_hand()
    end,
    loc = {
        "The selected hand must",
        "have at least {C:attention}1{}",
        "{C:attention}secret{} poker hand",
    },
})
