local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local EM = CL.edition_modifiers

SMODS.Spectral({
    key = "vibe",
    atlas = "vibe",
    pos = { x = 0, y = 0 },
    cost = 4,
    weight = 0.5,
    hidden = not EM.disable_overrides(),
    no_collection = not EM.disable_overrides(),
    in_pool = function(self, args)
        return EM.disable_overrides()
    end,
    config = {
        max_highlighted = 1,
    },
    loc_txt = {
        name = "Vibe",
        text = {
            "Applies any {C:dark_edition}non-standard{}",
            "edition to {C:attention}1{} selected card",
            "{C:inactive}(Includes {C:dark_edition}Negative{C:inactive}){}",
        },
    },
    can_use = function(self, card)
        return EM.can_use_selected_card_edition(EM.NON_STANDARD_SELECTED_ARGS)
    end,
    use = function(self, card, area, copier)
        EM.use_selected_card_edition(copier or card, copier, EM.NON_STANDARD_SELECTED_ARGS)
        delay(0.3)
    end,
})
