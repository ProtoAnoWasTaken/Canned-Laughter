local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local RANK_LABELS = {
    [2] = "2",
    [3] = "3",
    [4] = "4",
    [5] = "5",
    [6] = "6",
    [7] = "7",
    [8] = "8",
    [9] = "9",
    [10] = "10",
    [11] = "Jack",
    [12] = "Queen",
    [13] = "King",
    [14] = "Ace",
}

local function canlaugh_businessman_card()
    for _, card in ipairs(SMODS.find_card("j_canlaugh_businessman") or {}) do
        if not card.debuff and not card.getting_sliced then
            return card
        end
    end
end

local function canlaugh_businessman_priority(cards)
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

local function canlaugh_businessman_assignment(cards)
    local businessman = canlaugh_businessman_card()
    local extra = businessman and businessman.ability and businessman.ability.extra
    if not (extra and extra.source_rank and extra.target_rank and cards and #cards > 0) then
        return
    end

    local eligible = {}
    for _, playing_card in ipairs(cards) do
        if playing_card.ability then
            playing_card.ability.canlaugh_businessman_rank = nil
        end
        if playing_card.base and playing_card.base.id == extra.source_rank then
            eligible[#eligible + 1] = playing_card
        end
    end

    if #eligible == 0 then
        return
    end

    local choices = { extra.source_rank, extra.target_rank }
    if extra.promoted_rank then
        choices[#choices + 1] = extra.promoted_rank
    end

    local assignments = {}
    local best_assignments = {}
    local best_priority = math.huge

    local function choose_assignment(index)
        if index > #eligible then
            for assignment_index, playing_card in ipairs(eligible) do
                playing_card.ability.canlaugh_businessman_rank = assignments[assignment_index]
            end

            local priority = canlaugh_businessman_priority(cards)
            if priority < best_priority then
                best_priority = priority
                for assignment_index, rank in ipairs(assignments) do
                    best_assignments[assignment_index] = rank
                end
            end
            return
        end

        for _, rank in ipairs(choices) do
            assignments[index] = rank
            choose_assignment(index + 1)
            if best_priority == 1 then
                return
            end
        end
    end

    choose_assignment(1)

    for index, playing_card in ipairs(eligible) do
        playing_card.ability.canlaugh_businessman_rank = best_assignments[index] or extra.source_rank
    end
end

local function canlaugh_businessman_pair_key(source_rank, target_rank)
    return tostring(source_rank) .. ":" .. tostring(target_rank)
end

local function canlaugh_businessman_choose(card)
    local extra = card.ability.extra
    extra.seen_pairs = extra.seen_pairs or {}
    local pairs = {}
    local all_pairs = {}

    for source_rank = 2, 14 do
        for target_rank = 2, 14 do
            if source_rank ~= target_rank then
                local key = canlaugh_businessman_pair_key(source_rank, target_rank)
                local pair = {
                    source_rank = source_rank,
                    target_rank = target_rank,
                    key = key,
                }
                all_pairs[#all_pairs + 1] = pair
                if not extra.seen_pairs[key] then
                    pairs[#pairs + 1] = pair
                end
            end
        end
    end

    if #pairs == 0 then
        return
    end

    local attempted_pair = pseudorandom_element(
        all_pairs,
        pseudoseed("canlaugh_businessman_attempt")
    )
    if attempted_pair and extra.seen_pairs[attempted_pair.key] then
        if not extra.found_dupes and type(check_for_unlock) == "function" then
            extra.found_dupes = true
            check_for_unlock({ type = "canlaugh_snake_eyes" })
        end
    end

    local choice = pseudorandom_element(pairs, pseudoseed("canlaugh_businessman_pair"))
    extra.source_rank = choice.source_rank
    extra.target_rank = choice.target_rank
    extra.seen_pairs[choice.key] = true
end

function CL.businessman_consume_whitecollar()
    local businessman = canlaugh_businessman_card()
    local extra = businessman and businessman.ability and businessman.ability.extra
    if not (businessman and extra and not extra.promoted) then
        return false
    end

    local choices = {}
    for rank = 2, 14 do
        if rank ~= extra.source_rank and rank ~= extra.target_rank then
            choices[#choices + 1] = rank
        end
    end

    if #choices == 0 then
        return false
    end

    extra.promoted = true
    extra.promoted_rank = pseudorandom_element(choices, pseudoseed("canlaugh_businessman_promotion"))
    if type(check_for_unlock) == "function" then
        check_for_unlock({ type = "canlaugh_trickle_down_economics" })
    end
    return true
end

if Card and type(Card.get_id) == "function" and not CL.businessman_rank_hook_installed then
    CL.businessman_rank_hook_installed = true
    local get_id_ref = Card.get_id

    function Card:get_id(...)
        local businessman = canlaugh_businessman_card()
        local rank = self.ability and self.ability.canlaugh_businessman_rank
        if businessman and rank then
            return rank
        end

        return get_id_ref(self, ...)
    end
end

if G and G.FUNCS and type(G.FUNCS.get_poker_hand_info) == "function" and not CL.businessman_hand_hook_installed then
    CL.businessman_hand_hook_installed = true
    local get_poker_hand_info_ref = G.FUNCS.get_poker_hand_info

    G.FUNCS.get_poker_hand_info = function(cards, ...)
        if CL.businessman_assigning then
            return get_poker_hand_info_ref(cards, ...)
        end

        CL.businessman_assigning = true
        local results = { pcall(canlaugh_businessman_assignment, cards) }
        CL.businessman_assigning = nil
        if not results[1] then
            error(results[2])
        end
        return get_poker_hand_info_ref(cards, ...)
    end
end

SMODS.Atlas({
    key = "businessman",
    path = "businessman.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "businessman",
    name = "Businessman",
    atlas = "businessman",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            source_rank = 2,
            target_rank = 3,
            promoted_rank = nil,
            promoted = false,
            found_dupes = false,
            seen_pairs = {},
        },
    },
    loc_txt = {
        name = "Businessman",
        text = {
            "Any {C:attention}#1#{} may also be considered",
            "a {C:attention}#2#{} for scoring",
            "Ranks change every round",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            key = extra.promoted_rank and "j_canlaugh_businessman_promoted" or nil,
            vars = {
                RANK_LABELS[extra.source_rank],
                RANK_LABELS[extra.target_rank],
                RANK_LABELS[extra.promoted_rank],
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint and not context.canlaugh_spyware then
            canlaugh_businessman_choose(card)
        end
    end,
})
