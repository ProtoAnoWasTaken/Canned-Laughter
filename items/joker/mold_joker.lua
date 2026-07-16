SMODS.Atlas({
    key = "mold_joker",
    path = "mold_joker.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "mold_joker",
    name = "Mold Joker",
    atlas = "mold_joker",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 5,
    config = { extra = { mult = 0, mult_gain = 6 } },
    loc_txt = {
        name = "Mold Joker",
        text = {
            "{C:attention}Food Jokers{} expire at",
            "double the rate",
            "{C:mult}+#2#{} Mult for every stage",
            "lost this way",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return { vars = { extra.mult, extra.mult_gain } }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calc_scaling = function(self, card, target, initial, scalar_value, args)
        local PCJ = CannedLaughter.playing_card_jokers
        if not card.debuff and PCJ.should_double_food_scaling(target, scalar_value, args) then
            PCJ.mark_scale_card_food_decay(target)
            PCJ.gain_mold_joker_mult(card)
            return {
                override_scalar_value = { value = scalar_value * 2 },
            }
        end
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
})
