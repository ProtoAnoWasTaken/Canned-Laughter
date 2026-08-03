SMODS.Atlas({
    key = "sandbag",
    path = "sandbag.png",
    px = 69,
    py = 93,
})

local function canlaugh_sandbag_first_hand()
    local round = G and G.GAME and G.GAME.current_round
    return round and (round.hands_played or 0) == 0
end

SMODS.Joker({
    key = "sandbag",
    name = "Sandbag",
    atlas = "sandbag",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            mult = 0,
            mult_gain = 3,
            triggered_this_round = false,
        },
    },
    loc_txt = {
        name = "Sandbag",
        text = {
            "Gains {C:mult}+#2#{} Mult if first hand",
            "this round is not your most",
            "played poker hand",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return { vars = { extra.mult, extra.mult_gain } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.setting_blind and not context.blueprint then
            extra.triggered_this_round = false
        end

        if context.before
            and not context.blueprint
            and not context.retrigger_joker
            and not extra.triggered_this_round
            and canlaugh_sandbag_first_hand()
        then
            extra.triggered_this_round = true
            local most_played = CannedLaughter.boss_most_played(G.GAME.hands)
            if context.scoring_name ~= most_played then
                extra.mult = extra.mult + extra.mult_gain
                return {
                    message = "Sandbagged!",
                    colour = G.C.MULT,
                }
            end
        end

        if context.joker_main and extra.mult > 0 then
            return { mult = extra.mult }
        end
    end,
})
