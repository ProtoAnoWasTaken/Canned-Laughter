SMODS.Atlas({
    key = "solatro",
    path = "solatro.png",
    px = 69,
    py = 93,
})

local function canlaugh_solatro_qualifies(context)
    return context.scoring_name == "High Card"
        and context.scoring_hand
        and #context.scoring_hand > 1
end

SMODS.Joker({
    key = "solatro",
    name = "Solatro",
    atlas = "solatro",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            total_hands = 0,
            high_card_hands = 0,
            x_mult = 3,
        },
    },
    loc_txt = {
        name = "Solatro",
        text = {
            "{C:blue}+1 Hand{} every round",
            "Gives {X:mult,C:white}X#1#{} Mult after playing",
            "at least {C:attention}half{} of all hands as",
            "High Cards with more than",
            "{C:attention}1{} scoring card",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return { vars = { extra.x_mult } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.setting_blind and not context.blueprint then
            ease_hands_played(1)
            return {
                message = "+1 Hand",
                colour = G.C.BLUE,
            }
        end

        if context.before and not context.blueprint and not context.retrigger_joker then
            extra.total_hands = extra.total_hands + 1
            if canlaugh_solatro_qualifies(context) then
                extra.high_card_hands = extra.high_card_hands + 1
            end
        end

        if context.joker_main
            and extra.total_hands > 0
            and extra.high_card_hands * 2 >= extra.total_hands
        then
            return { x_mult = extra.x_mult }
        end
    end,
})
