SMODS.Atlas({
    key = "jester",
    path = "jester.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "jester",
    name = "Jester",
    atlas = "jester",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 1,
    config = {
        extra = {
            chips = 21,
        },
    },
    loc_txt = {
        name = "Jester",
        text = {
            "{C:chips}+#1#{} Chips",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                extra.chips,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
            }
        end
    end,
})
