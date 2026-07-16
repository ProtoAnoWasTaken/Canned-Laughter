SMODS.Atlas({ key = "perfect_pair", path = "perfect_pair.png", px = 69, py = 93 })

local function hand_contains_pair(poker_hands)
    return poker_hands and next(poker_hands["Pair"] or {}) ~= nil
end

SMODS.Joker({
    key = "perfect_pair",
    name = "Perfect Pair",
    atlas = "perfect_pair",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_txt = { name = "Perfect Pair", text = {
        "Adjacent Jokers retrigger",
        "when a played hand contains a {C:attention}Pair{}",
    } },
    calculate = function(self, card, context)
        if context.retrigger_joker_check
            and not context.retrigger_joker
            and context.other_card
            and hand_contains_pair(context.other_context and context.other_context.poker_hands)
        then
            local jokers = G.jokers and G.jokers.cards or {}
            for index, joker in ipairs(jokers) do
                if joker == card and (jokers[index - 1] == context.other_card or jokers[index + 1] == context.other_card) then
                    return { message = localize("k_again_ex"), repetitions = 1, card = card }
                end
            end
        end
    end,
})

if CannedLaughter and CannedLaughter.barter then
    CannedLaughter.barter.register_rep_modifier("perfect_pair", function(phase, context)
        if (phase ~= "hand" and phase ~= "availability") or context.booster_kind ~= "Celestial"
            or #(SMODS.find_card("j_canlaugh_perfect_pair") or {}) == 0
        then return end
        local eligible = {}
        for _, hand_key in ipairs(G.handlist or {}) do
            local hand = G.GAME.hands and G.GAME.hands[hand_key]
            local requirements = CannedLaughter.barter.planet_requirements[hand_key]
            if hand and (hand.level or 1) <= 1 and requirements and requirements.pair then eligible[#eligible + 1] = hand_key end
        end
        if phase == "availability" then
            if #eligible > 0 then context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_perfect_pair") or {}) end
            return
        end
        for _, joker in ipairs(SMODS.find_card("j_canlaugh_perfect_pair") or {}) do
            if #eligible > 0 then
                local hand_key = eligible[math.floor(pseudorandom("canlaugh_perfect_pair_trial") * #eligible) + 1]
                CannedLaughter.barter.add_collection_rep(CannedLaughter.barter.planet_for_hand(hand_key), "Celestial", joker)
            end
        end
    end)
end
