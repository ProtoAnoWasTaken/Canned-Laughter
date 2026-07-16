SMODS.Atlas({
    key = "oracle_attack",
    path = "oracle_attack.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "oracle_attack",
    name = "Oracle Attack",
    atlas = "oracle_attack",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = { extra = { x_mult = 2 } },
    loc_txt = {
        name = "Oracle Attack",
        text = {
            "{C:spectral}Spectral{} cards in your",
            "{C:attention}consumable{} area",
            "each give {X:mult,C:white}X#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { self.config.extra.x_mult } }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.other_consumeable
            and context.other_consumeable.ability
            and context.other_consumeable.ability.set == "Spectral"
        then
            return {
                x_mult = card.ability.extra.x_mult,
                message_card = context.other_consumeable,
            }
        end
    end,
})
