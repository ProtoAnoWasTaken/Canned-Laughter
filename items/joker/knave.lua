local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "knave", path = "knave.png", px = 69, py = 93 })

local function mathematician_active()
    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center
        if center and (center.key == "j_canlaugh_mathematician" or center.original_key == "mathematician") then
            return true
        end
    end
    return false
end

local function ranks_total_twenty_one(cards, force_rank_values)
    local totals = { [0] = true }
    local use_rank_values = force_rank_values
    if use_rank_values == nil then use_rank_values = mathematician_active() end
    for _, playing_card in ipairs(cards or {}) do
        local rank = playing_card:get_id()
        local values
        if rank == 14 then
            values = use_rank_values and { 14 } or { 1, 11 }
        elseif rank >= 11 and rank <= 13 then
            values = use_rank_values and { rank } or { 10 }
        else
            values = { rank }
        end
        local next_totals = {}
        for total in pairs(totals) do
            for _, value in ipairs(values) do
                if total + value <= 21 then next_totals[total + value] = true end
            end
        end
        totals = next_totals
    end
    return totals[21] or false
end

local function knave_active()
    return SMODS and next(SMODS.find_card("j_canlaugh_knave") or {}) ~= nil
end

if G and G.FUNCS and type(G.FUNCS.get_poker_hand_info) == "function" and not CannedLaughter.knave_hand_hook_installed then
    CannedLaughter.knave_hand_hook_installed = true
    local get_poker_hand_info_ref = G.FUNCS.get_poker_hand_info
    G.FUNCS.get_poker_hand_info = function(cards)
        local text, loc_text, poker_hands, scoring_hand, display_text = get_poker_hand_info_ref(cards)
        if CannedLaughter.knave_evaluating_play and knave_active() and ranks_total_twenty_one(cards) then
            scoring_hand = cards
        end
        return text, loc_text, poker_hands, scoring_hand, display_text
    end
end

if G and G.FUNCS and type(G.FUNCS.evaluate_play) == "function" and not CannedLaughter.knave_evaluate_hook_installed then
    CannedLaughter.knave_evaluate_hook_installed = true
    local evaluate_play_ref = G.FUNCS.evaluate_play
    G.FUNCS.evaluate_play = function(...)
        CannedLaughter.knave_evaluating_play = true
        local results = { evaluate_play_ref(...) }
        CannedLaughter.knave_evaluating_play = nil
        return unpack(results)
    end
end

SMODS.Joker({
    key = "knave",
    name = "Knave",
    atlas = "knave",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_txt = { name = "Knave", text = {
        "If played ranks total {C:attention}21{},",
        "score and retrigger each played card once",
        "{C:inactive}(Face cards count as 10; Aces as 1 or 11){}",
    } },
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and ranks_total_twenty_one(context.full_hand)
        then
            if mathematician_active() and not ranks_total_twenty_one(context.full_hand, false)
                and type(check_for_unlock) == "function" then
                check_for_unlock({ type = "canlaugh_house_rules" })
            end
            return { message = localize("k_again_ex"), repetitions = 1, card = card }
        end
    end,
})
