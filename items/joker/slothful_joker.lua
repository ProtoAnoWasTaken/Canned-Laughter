SMODS.Atlas({
    key = "slothful_joker",
    path = "slothfuljoker.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "slothful_joker",
    name = "Slothful Joker",
    atlas = "slothful_joker",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            mult = 3,
        },
    },
    loc_txt = {
        name = "Slothful Joker",
        text = {
            "Played cards with {C:attention}no suit{} give",
            "{C:mult}+#1#{} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card and card.ability and card.ability.extra and card.ability.extra.mult
                    or self.config.extra.mult,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual
            and context.cardarea == G.play
            and context.other_card
            and SMODS.has_no_suit(context.other_card)
        then
            return {
                mult = card.ability.extra.mult,
            }
        end
    end,
})
