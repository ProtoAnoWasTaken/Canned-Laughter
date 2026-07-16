SMODS.Atlas({
    key = "christmas_card",
    path = "christmascard.png",
    px = 69,
    py = 93,
})

local function canlaugh_christmas_targets()
    local targets = {}

    for _, joker in ipairs((G.jokers and G.jokers.cards) or {}) do
        if joker and joker.set_cost then
            targets[#targets + 1] = joker
        end
    end

    for _, consumable in ipairs((G.consumeables and G.consumeables.cards) or {}) do
        if consumable and consumable.set_cost then
            targets[#targets + 1] = consumable
        end
    end

    return targets
end

local function canlaugh_add_sell_value(target, amount)
    if not (target and target.ability and target.set_cost) then
        return
    end

    target.ability.extra_value = (target.ability.extra_value or 0) + amount
    target:set_cost()
end

SMODS.Joker({
    key = "christmas_card",
    name = "Christmas Card",
    atlas = "christmas_card",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            odds = 2,
            sell_value = 2,
        },
    },
    loc_txt = {
        name = "Christmas Card",
        text = {
            "Played {C:attention}face cards{} have a",
            "{C:green}#1# in #2#{} chance to add {C:money}$#3#{}",
            "of sell value to a random",
            "{C:attention}Joker{} or {C:attention}consumable{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                G.GAME and G.GAME.probabilities.normal or 1,
                extra.odds,
                extra.sell_value,
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
            and context.other_card:is_face()
            and SMODS.pseudorandom_probability(card, "canlaugh_christmas_card", 1, card.ability.extra.odds)
        then
            local targets = canlaugh_christmas_targets()
            local target = #targets > 0
                and pseudorandom_element(targets, pseudoseed("canlaugh_christmas_card_target"))

            if not target then
                return
            end

            canlaugh_add_sell_value(target, card.ability.extra.sell_value)

            return {
                extra = {
                    focus = target,
                    message = localize("k_val_up"),
                    colour = G.C.MONEY,
                },
                card = card,
            }
        end
    end,
})
