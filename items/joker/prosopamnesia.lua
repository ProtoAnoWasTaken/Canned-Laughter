local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "prosopamnesia",
    path = "prosopamnesia.png",
    px = 69,
    py = 93,
})

local FACE_IDS = {
    11,
    12,
    13,
}

local PAREIDOLIA_FACE_ID = 10

local function pareidolia_acquisitions()
    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    if not profile then
        return 0
    end

    return profile.canlaugh_pareidolia_acquisitions or 0
end

local function record_pareidolia_acquisition(card, from_debuff)
    local center = card and card.config and card.config.center
    if from_debuff or not center or center.key ~= "j_pareidolia" or card.canlaugh_pareidolia_recorded then
        return
    end

    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    if not profile then
        return
    end

    card.canlaugh_pareidolia_recorded = true
    profile.canlaugh_pareidolia_acquisitions = pareidolia_acquisitions() + 1

    if save_settings then
        save_settings()
    end

    if profile.canlaugh_pareidolia_acquisitions >= 7 and check_for_unlock then
        check_for_unlock({ type = "canlaugh_prosopamnesia" })
    end
end

local function prosopamnesia_active()
    for _, joker in ipairs(SMODS.find_card("j_canlaugh_prosopamnesia") or {}) do
        if not joker.debuff then
            return true
        end
    end

    return false
end

local function pareidolia_active()
    for _, joker in ipairs(SMODS.find_card("j_pareidolia") or {}) do
        if not joker.debuff then
            return true
        end
    end

    return false
end

local function substitutable_face_id(card)
    local id = card and card.base and card.base.id
    if id == 11 or id == 12 or id == 13 then
        return id
    end

    if id == PAREIDOLIA_FACE_ID and pareidolia_active() then
        return id
    end
end

local function substitutable_face_ranks()
    local ranks = {}

    if pareidolia_active() then
        ranks[#ranks + 1] = PAREIDOLIA_FACE_ID
    end

    for _, id in ipairs(FACE_IDS) do
        ranks[#ranks + 1] = id
    end

    return ranks
end

local function alternate_face_ids(card)
    local candidates = {}

    for _, id in ipairs(substitutable_face_ranks()) do
        candidates[#candidates + 1] = id
    end

    return candidates
end

local function hand_priority(cards)
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

local function assign_best_face_substitutions(cards)
    if not prosopamnesia_active() or not cards or #cards == 0 then
        return
    end

    local face_cards = {}

    for _, card in ipairs(cards) do
        if substitutable_face_id(card) then
            face_cards[#face_cards + 1] = card
        end
    end

    if #face_cards == 0 then
        return
    end

    local assignments = {}
    local best_assignments = {}
    local best_priority = math.huge

    local function choose_assignment(index)
        if index > #face_cards then
            for assignment_index, face_card in ipairs(face_cards) do
                face_card.ability.canlaugh_prosopamnesia_rank = assignments[assignment_index]
            end

            local priority = hand_priority(cards)
            if priority < best_priority then
                best_priority = priority

                for assignment_index, value in ipairs(assignments) do
                    best_assignments[assignment_index] = value
                end
            end

            return
        end

        for _, rank in ipairs(alternate_face_ids(face_cards[index])) do
            assignments[index] = rank
            choose_assignment(index + 1)
        end
    end

    choose_assignment(1)

    for index, face_card in ipairs(face_cards) do
        face_card.ability.canlaugh_prosopamnesia_rank = best_assignments[index]
    end
end

if Card and type(Card.get_id) == "function" and not CL.prosopamnesia_rank_hook_installed then
    CL.prosopamnesia_rank_hook_installed = true
    local get_id_ref = Card.get_id

    function Card:get_id(...)
        if prosopamnesia_active() and substitutable_face_id(self) then
            local rank = self.ability and self.ability.canlaugh_prosopamnesia_rank
            if rank then
                return rank
            end
        end

        return get_id_ref(self, ...)
    end
end

if G and G.FUNCS and type(G.FUNCS.get_poker_hand_info) == "function" and not CL.prosopamnesia_hand_hook_installed then
    CL.prosopamnesia_hand_hook_installed = true
    local get_poker_hand_info_ref = G.FUNCS.get_poker_hand_info

    G.FUNCS.get_poker_hand_info = function(cards, ...)
        if CL.prosopamnesia_assigning_substitutions then
            return get_poker_hand_info_ref(cards, ...)
        end

        CL.prosopamnesia_assigning_substitutions = true
        assign_best_face_substitutions(cards)
        CL.prosopamnesia_assigning_substitutions = nil
        return get_poker_hand_info_ref(cards, ...)
    end
end

if Card and type(Card.add_to_deck) == "function" and not CL.prosopamnesia_unlock_hook_installed then
    CL.prosopamnesia_unlock_hook_installed = true
    local add_to_deck_ref = Card.add_to_deck

    function Card:add_to_deck(from_debuff, ...)
        local results = { add_to_deck_ref(self, from_debuff, ...) }
        record_pareidolia_acquisition(self, from_debuff)
        return unpack(results)
    end
end

SMODS.Joker({
    key = "prosopamnesia",
    name = "Prosopamnesia",
    atlas = "prosopamnesia",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    unlocked = false,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_txt = {
        name = "Prosopamnesia",
        text = {
            "Face cards may be considered",
            "any other {C:attention}face card{}",
        },
        unlock = {
            "Acquire {C:attention}Pareidolia{} 7 times",
            "{C:inactive}(#1# times){}",
        },
    },
    check_for_unlock = function(self, args)
        return args
            and args.type == "canlaugh_prosopamnesia"
            and pareidolia_acquisitions() >= 7
    end,
    locked_loc_vars = function(self, info_queue, card)
        return { vars = { pareidolia_acquisitions() } }
    end,
})
