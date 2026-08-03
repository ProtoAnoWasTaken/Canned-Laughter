local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "trial_range",
    path = "trial_range.png",
    px = 34,
    py = 34,
    frames = 21,
    atlas_table = "ANIMATION_ATLAS",
})

CL.barter.register_trial({
    key = "standard_range",
    name = "The Range",
    booster_kinds = { "Standard" },
    standard_card = true,
    kind = "standard_range",
    need = 4,
    loc = {
        "The selected hand must have",
        "at least {C:attention}#1# #2#{} and",
        "{C:attention}#3# #4#{}",
    },
    loc_vars = function()
        local bounds = CL.barter.standard_range_bounds()
        local highest = bounds
            and bounds.highest
            and bounds.highest.display_plural
            or "highest cards"
        local lowest = bounds
            and bounds.lowest
            and bounds.lowest.display_plural
            or "lowest cards"

        return {
            vars = { 2, highest, 2, lowest },
        }
    end,
})
