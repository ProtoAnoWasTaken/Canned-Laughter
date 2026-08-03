local HANDS = {
    "Four of a Kind",
    "Full House",
    "Flush",
    "Straight",
    "Straight Flush",
    "Five of a Kind",
    "Flush House",
    "Flush Five",
}

local function canlaugh_leg_day_hand_key()
    local round = G and G.GAME and G.GAME.current_round
    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

local function canlaugh_leg_day_choose(card)
    local candidates = {}
    for _, hand in ipairs(HANDS) do
        if G and G.GAME and G.GAME.hands and G.GAME.hands[hand] and hand ~= card.ability.extra.hand then
            candidates[#candidates + 1] = hand
        end
    end

    if #candidates == 0 and G and G.GAME and G.GAME.hands and G.GAME.hands[card.ability.extra.hand] then
        candidates[#candidates + 1] = card.ability.extra.hand
    end

    if #candidates > 0 then
        card.ability.extra.hand = pseudorandom_element(candidates, pseudoseed(table.concat({
            "canlaugh_leg_day",
            tostring(card.sort_id or ""),
            tostring(G and G.GAME and G.GAME.round or ""),
        }, "_")))
    end
end

SMODS.Atlas({
    key = "leg_day",
    path = "leg_day.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "leg_day",
    name = "Leg Day",
    atlas = "leg_day",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    config = {
        extra = {
            mult = 0,
            chips = 0,
            mult_gain = 2,
            chips_gain = 4,
            hand = "Full House",
            last_hand = nil,
        },
    },
    loc_txt = {
        name = "Leg Day",
        text = {
            "Gains {C:mult}+#1#{} Mult and {C:chips}+#2#{} Chips",
            "if played hand contains a {C:attention}#3#{}",
            "{C:inactive}(Changes every round; currently {C:mult}+#4#{} Mult and {C:chips}+#5#{} Chips){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.mult_gain,
                extra.chips_gain,
                localize(extra.hand, "poker_hands"),
                extra.mult,
                extra.chips,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.setting_blind and not context.blueprint then
            canlaugh_leg_day_choose(card)
            extra.last_hand = nil
        end

        if context.before and not context.blueprint then
            local hand_key = canlaugh_leg_day_hand_key()
            local target_hand = context.poker_hands and context.poker_hands[extra.hand]
            if target_hand and next(target_hand) and extra.last_hand ~= hand_key then
                extra.last_hand = hand_key
                extra.mult = extra.mult + extra.mult_gain
                extra.chips = extra.chips + extra.chips_gain
                card:juice_up(0.3, 0.5)
                return {
                    message = "Leg Day!",
                    colour = G.C.MULT,
                }
            end
        end

        if context.joker_main then
            return {
                mult = extra.mult,
                chips = extra.chips,
            }
        end
    end,
})
