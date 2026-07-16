local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "hypnotized_joker", path = "hypnotized_joker.png", px = 69, py = 93 })

local function hypnotized_active()
    return next(SMODS.find_card("j_canlaugh_hypnotized_joker") or {}) ~= nil
end

if G and G.FUNCS and type(G.FUNCS.get_poker_hand_info) == "function" and not CL.hypnotized_hand_hook_installed then
    CL.hypnotized_hand_hook_installed = true
    local get_poker_hand_info_ref = G.FUNCS.get_poker_hand_info
    G.FUNCS.get_poker_hand_info = function(cards)
        local text, loc_text, poker_hands, scoring_hand, display_text = get_poker_hand_info_ref(cards)
        if not (CL.hypnotized_evaluating_play and hypnotized_active() and G.GAME and G.GAME.current_round) then
            return text, loc_text, poker_hands, scoring_hand, display_text
        end

        local round = G.GAME.current_round
        if not round.canlaugh_hypnotized_hand then
            round.canlaugh_hypnotized_hand = text
        elseif text ~= round.canlaugh_hypnotized_hand then
            text = round.canlaugh_hypnotized_hand
            display_text = text
            loc_text = localize(text, "poker_hands")
            poker_hands[text] = poker_hands[text] or { scoring_hand }
        end
        return text, loc_text, poker_hands, scoring_hand, display_text
    end
end

if G and G.FUNCS and type(G.FUNCS.evaluate_play) == "function" and not CL.hypnotized_evaluate_hook_installed then
    CL.hypnotized_evaluate_hook_installed = true
    local evaluate_play_ref = G.FUNCS.evaluate_play
    G.FUNCS.evaluate_play = function(...)
        CL.hypnotized_evaluating_play = true
        local results = { pcall(evaluate_play_ref, ...) }
        CL.hypnotized_evaluating_play = nil
        if not results[1] then
            error(results[2])
        end
        return unpack(results, 2)
    end
end

SMODS.Joker({
    key = "hypnotized_joker",
    name = "Hypnotized Joker",
    atlas = "hypnotized_joker",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_txt = { name = "Hypnotized Joker", text = {
        "All hands played this round",
        "are considered the same as",
        "the first hand played this round",
        "{C:inactive}(#1#, current hand: {C:attention}#2#{C:inactive}){}",
    } },
    loc_vars = function(self, info_queue, card)
        local current_hand = G and G.GAME and G.GAME.current_round and G.GAME.current_round.canlaugh_hypnotized_hand
        return {
            vars = {
                current_hand and "Active" or "Inactive",
                current_hand and localize(current_hand, "poker_hands") or "None",
            },
        }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint and G and G.GAME and G.GAME.current_round then
            G.GAME.current_round.canlaugh_hypnotized_hand = nil
        end
    end,
})

if CL.barter then
    CL.barter.register_rep_modifier("hypnotized_joker", function(phase, context)
        local hand = G.GAME and G.GAME.current_round and G.GAME.current_round.canlaugh_hypnotized_hand
        if phase == "availability" and context.booster_kind == "Celestial" and hand then context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_hypnotized_joker") or {}); return end
        if phase == "hand" and context.booster_kind == "Celestial" and hand then
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_hypnotized_joker") or {}) do
                CL.barter.add_collection_rep(CL.barter.planet_for_hand(hand), "Celestial", joker)
            end
        end
    end)
end
