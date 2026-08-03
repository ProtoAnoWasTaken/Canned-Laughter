local function canlaugh_drain_hand_key()
    local round = G and G.GAME and G.GAME.current_round
    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

SMODS.Atlas({
    key = "drain",
    path = "drain.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "drain",
    name = "Drain",
    atlas = "drain",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            mult = 0,
            mult_gain = 4,
            last_hand = nil,
        },
    },
    loc_txt = {
        name = "Drain",
        text = {
            "Gains {C:mult}+#1#{} Mult if played hand",
            "uses your maximum hand play size",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.mult_gain,
                extra.mult,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local play_limit = G and G.GAME and G.GAME.starting_params and G.GAME.starting_params.play_limit or 5
        local extra = card.ability.extra

        if context.before
            and not context.blueprint
            and #(context.full_hand or {}) >= play_limit
            and extra.last_hand ~= canlaugh_drain_hand_key()
        then
            extra.last_hand = canlaugh_drain_hand_key()
            extra.mult = extra.mult + extra.mult_gain
            card:juice_up(0.3, 0.5)
            return {
                message = "+" .. tostring(extra.mult_gain) .. " Mult",
                colour = G.C.MULT,
            }
        end

        if context.joker_main and extra.mult > 0 then
            return {
                mult = extra.mult,
            }
        end
    end,
})
