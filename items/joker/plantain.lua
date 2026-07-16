SMODS.Atlas({
    key = "plantain",
    path = "plantain.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "plantain",
    name = "Plantain",
    atlas = "plantain",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            chips = 175,
            odds = 6,
        },
    },
    loc_txt = {
        name = "Plantain",
        text = {
            "{C:chips}+#1#{} Chips",
            "{C:green}#2# in #3#{} chance this card is",
            "destroyed at end of round",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability.extra or self.config.extra
        local numerator, denominator = SMODS.get_probability_vars(
            card,
            1,
            extra.odds,
            "canlaugh_plantain"
        )

        return {
            vars = {
                extra.chips,
                numerator,
                denominator,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    pools = {
        Food = true,
    },
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
            }
        end

        if context.end_of_round
            and not context.individual
            and not context.repetition
            and not context.blueprint
        then
            if SMODS.pseudorandom_probability(
                card,
                "canlaugh_plantain",
                1,
                card.ability.extra.odds
            ) then
                G.GAME.pool_flags.canlaugh_plantain_extinct = true
                SMODS.destroy_cards(card, nil, nil, true)
                return {
                    message = localize("k_extinct_ex"),
                }
            end

            return {
                message = localize("k_safe_ex"),
            }
        end
    end,
})
