local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_paint_thinner_active()
    for _, joker in ipairs(SMODS.find_card("j_canlaugh_paint_thinner") or {}) do
        if not joker.debuff then
            return true
        end
    end

    return false
end

local function canlaugh_paint_thinner_wild(card)
    return card
        and SMODS
        and type(SMODS.has_enhancement) == "function"
        and SMODS.has_enhancement(card, "m_wild")
end

local function canlaugh_paint_thinner_adjacent_ranks(card)
    local rank = card and card.base and card.base.id
    if type(rank) ~= "number" then
        return {}
    end

    local lower_rank = rank == 2 and 14 or rank - 1
    local higher_rank = rank == 14 and 2 or rank + 1
    return {
        lower_rank,
        higher_rank,
    }
end

local function canlaugh_paint_thinner_hand_priority(cards)
    if not (evaluate_poker_hand and G and G.handlist) then
        return math.huge
    end

    local poker_hands = evaluate_poker_hand(cards)
    for priority, hand_name in ipairs(G.handlist) do
        if poker_hands[hand_name] and next(poker_hands[hand_name]) then
            return priority
        end
    end

    return math.huge
end

local function canlaugh_paint_thinner_cache_key(cards)
    local parts = {}

    for index, card in ipairs(cards) do
        local base = card and card.base or {}
        local ability = card and card.ability or {}
        parts[index] = table.concat({
            tostring(card and (card.sort_id or card.unique_val or card) or ""),
            tostring(base.id or ""),
            tostring(base.suit or ""),
            tostring(ability.name or ""),
            tostring(ability.effect or ""),
            tostring(card and card.debuff or false),
        }, ":")
    end

    return table.concat(parts, "|")
end

local function canlaugh_paint_thinner_store_assignments(cache_key, assignments)
    CL.paint_thinner_assignment_cache = CL.paint_thinner_assignment_cache or {}
    CL.paint_thinner_assignment_cache_order = CL.paint_thinner_assignment_cache_order or {}

    if CL.paint_thinner_assignment_cache[cache_key] then
        return
    end

    if #CL.paint_thinner_assignment_cache_order >= 64 then
        local oldest_key = table.remove(CL.paint_thinner_assignment_cache_order, 1)
        CL.paint_thinner_assignment_cache[oldest_key] = nil
    end

    CL.paint_thinner_assignment_cache[cache_key] = assignments
    CL.paint_thinner_assignment_cache_order[#CL.paint_thinner_assignment_cache_order + 1] = cache_key
end

local function canlaugh_paint_thinner_assign_ranks(cards)
    if not canlaugh_paint_thinner_active() or not cards or #cards == 0 then
        return
    end

    local wild_cards = {}
    for index, card in ipairs(cards) do
        if canlaugh_paint_thinner_wild(card) then
            wild_cards[#wild_cards + 1] = {
                card = card,
                index = index,
            }
        end
    end

    if #wild_cards == 0 then
        return
    end

    for _, wild_card in ipairs(wild_cards) do
        wild_card.card.ability.canlaugh_paint_thinner_rank = nil
    end

    local cache_key = canlaugh_paint_thinner_cache_key(cards)
    local cached = CL.paint_thinner_assignment_cache and CL.paint_thinner_assignment_cache[cache_key]
    if cached then
        for index, card_index in ipairs(cached.indices) do
            local card = cards[card_index]
            if card and card.ability then
                card.ability.canlaugh_paint_thinner_rank = cached.ranks[index]
            end
        end
        return
    end

    local assignments = {}
    local best_assignments = {}
    local best_priority = math.huge

    local function choose_assignment(index)
        if best_priority == 1 then
            return
        end

        if index > #wild_cards then
            for assignment_index, wild_card in ipairs(wild_cards) do
                wild_card.card.ability.canlaugh_paint_thinner_rank = assignments[assignment_index]
            end

            local priority = canlaugh_paint_thinner_hand_priority(cards)
            if priority < best_priority then
                best_priority = priority
                for assignment_index, rank in ipairs(assignments) do
                    best_assignments[assignment_index] = rank
                end
            end

            return
        end

        for _, rank in ipairs(canlaugh_paint_thinner_adjacent_ranks(wild_cards[index].card)) do
            assignments[index] = rank
            choose_assignment(index + 1)

            if best_priority == 1 then
                break
            end
        end
    end

    choose_assignment(1)

    local cached_assignments = {
        indices = {},
        ranks = {},
    }

    for index, wild_card in ipairs(wild_cards) do
        wild_card.card.ability.canlaugh_paint_thinner_rank = best_assignments[index]
        cached_assignments.indices[index] = wild_card.index
        cached_assignments.ranks[index] = best_assignments[index]
    end

    canlaugh_paint_thinner_store_assignments(cache_key, cached_assignments)
end

if Card and type(Card.get_id) == "function" and not CL.paint_thinner_rank_hook_installed then
    CL.paint_thinner_rank_hook_installed = true
    local get_id_ref = Card.get_id

    function Card:get_id(...)
        if canlaugh_paint_thinner_active() and canlaugh_paint_thinner_wild(self) then
            local rank = self.ability and self.ability.canlaugh_paint_thinner_rank
            if rank then
                return rank
            end
        end

        return get_id_ref(self, ...)
    end
end

if G and G.FUNCS and type(G.FUNCS.get_poker_hand_info) == "function" and not CL.paint_thinner_hand_hook_installed then
    CL.paint_thinner_hand_hook_installed = true
    local get_poker_hand_info_ref = G.FUNCS.get_poker_hand_info

    G.FUNCS.get_poker_hand_info = function(cards, ...)
        if CL.paint_thinner_assigning_ranks then
            return get_poker_hand_info_ref(cards, ...)
        end

        CL.paint_thinner_assigning_ranks = true
        local results = { pcall(canlaugh_paint_thinner_assign_ranks, cards) }
        CL.paint_thinner_assigning_ranks = nil
        if not results[1] then
            error(results[2])
        end

        return get_poker_hand_info_ref(cards, ...)
    end
end

SMODS.Atlas({
    key = "paint_thinner",
    path = "paint_thinner.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "paint_thinner",
    name = "Paint Thinner",
    atlas = "paint_thinner",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_txt = {
        name = "Paint Thinner",
        text = {
            "{C:attention}Wild Cards{} count as either",
            "adjacent {C:attention}rank{}",
        },
    },
})
