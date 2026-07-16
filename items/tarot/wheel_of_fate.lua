local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local EM = CL.edition_modifiers

SMODS.Tarot({
    key = "wheel_of_fate",
    name = "Wheel of Fate",
    atlas = "wheel_of_fate",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 0.5,
    config = {
        extra = 4,
    },
    hidden = not EM.disable_overrides(),
    no_collection = not EM.disable_overrides(),
    in_pool = function(self, args)
        return EM.disable_overrides()
    end,
    loc_txt = {
        name = "Wheel of Fate",
        text = {
            "{C:green}#1# in #2#{} chance to add",
            "a {C:dark_edition}non-standard{} edition",
            "to a random {C:attention}Joker{}",
            "{C:inactive}(Includes {C:dark_edition}Negative{C:inactive}){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                SMODS.get_probability_vars(card, 1, extra, "canlaugh_wheel_of_fate"),
            },
        }
    end,
    can_use = function(self, card)
        return EM.can_use_wheel(card, EM.NON_STANDARD_WHEEL_ARGS.edition_args)
            and #EM.get_editions(EM.NON_STANDARD_WHEEL_ARGS.edition_args) > 0
    end,
    use = function(self, card, area, copier)
        EM.use_wheel_like(card, copier, EM.NON_STANDARD_WHEEL_ARGS)
    end,
})
