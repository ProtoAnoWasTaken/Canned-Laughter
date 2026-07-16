SMODS.Atlas({
    key = "pack_rat",
    path = "packrat.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "pack_rat",
    name = "Pack Rat",
    atlas = "pack_rat",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 5,
    config = {
        extra = {
            slots = 1,
            trials = 0,
        },
    },
    loc_txt = {
        name = "Pack Rat",
        text = {
            "This Joker gives {C:attention}+1{} consumable slot",
            "for every {C:attention}#3# Trials passed{}",
            "{C:inactive}(Currently {C:attention}+#1#{C:inactive} consumable slots){}",
            "{C:inactive}(Passed: #2#/#3#){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability.extra or self.config.extra
        local trials_per_slot = 2
        local progress = extra.trials % trials_per_slot

        return {
            vars = {
                extra.slots,
                progress,
                trials_per_slot,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    add_to_deck = function(self, card, from_debuff)
        if not from_debuff and G.consumeables then
            G.consumeables.config.card_limit = G.consumeables.config.card_limit
                + card.ability.extra.slots
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        if not from_debuff and G.consumeables then
            G.consumeables.config.card_limit = G.consumeables.config.card_limit
                - card.ability.extra.slots
        end
    end,
})
