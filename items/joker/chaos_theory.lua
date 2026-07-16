SMODS.Atlas({
    key = "chaos_theory",
    path = "chaostheory.png",
    px = 69,
    py = 93,
})

if CannedLaughter.barter then
    CannedLaughter.barter.register_rep_modifier("chaos_theory", function(phase, context)
        if phase == "availability" and context.booster_kind == "Celestial" then context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_chaos_theory") or {}); return end
        if phase == "hand" and context.booster_kind == "Celestial" then
            local center = G.P_CENTERS and G.P_CENTERS.c_black_hole
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_chaos_theory") or {}) do
                CannedLaughter.barter.add_collection_rep(center, "Celestial", joker)
            end
        end
    end)
end

local RARE_HAND_JOKERS = {
    "j_duo",
    "j_trio",
    "j_family",
    "j_order",
    "j_tribe",
}

local function canlaugh_standard_rare_hand_jokers_discovered()
    if not (G and G.P_CENTERS) then
        return false
    end

    for _, joker_key in ipairs(RARE_HAND_JOKERS) do
        if not (G.P_CENTERS[joker_key] and G.P_CENTERS[joker_key].discovered) then
            return false
        end
    end

    return true
end

local function canlaugh_playable_poker_hands()
    local hands = {}

    for _, hand_key in ipairs(G.handlist or {}) do
        local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_key]

        if hand and (not SMODS.is_poker_hand_visible or SMODS.is_poker_hand_visible(hand_key)) then
            hands[#hands + 1] = hand_key
        end
    end

    return hands
end

local function canlaugh_pick_chaos_hand(card, avoid_hand)
    local hands = canlaugh_playable_poker_hands()

    if #hands == 0 then
        return nil
    end

    if avoid_hand and #hands > 1 then
        for i = #hands, 1, -1 do
            if hands[i] == avoid_hand then
                table.remove(hands, i)
            end
        end
    end

    local extra = card and card.ability and card.ability.extra
    local roll = extra and extra.roll or 0

    return pseudorandom_element(hands, pseudoseed(table.concat({
        "canlaugh_chaos_theory",
        tostring(card and card.sort_id or ""),
        tostring(roll),
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(G and G.GAME and G.GAME.hands_played or ""),
    }, "_")))
end

local function canlaugh_set_chaos_hand(card, avoid_hand)
    if not (card and card.ability and card.ability.extra) then
        return
    end

    card.ability.extra.roll = (card.ability.extra.roll or 0) + 1
    card.ability.extra.target_hand = canlaugh_pick_chaos_hand(card, avoid_hand)
end

local function canlaugh_context_matches_hand(context, hand_key)
    if not (context and hand_key) then
        return false
    end

    if context.scoring_name == hand_key then
        return true
    end

    local poker_hands = context.poker_hands
    local scored_hand = poker_hands and poker_hands[hand_key]

    return type(scored_hand) == "table" and #scored_hand > 0
end

SMODS.Joker({
    key = "chaos_theory",
    name = "Chaos Theory",
    atlas = "chaos_theory",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            x_mult = 1,
            x_mult_gain = 2,
            target_hand = nil,
            roll = 0,
        },
    },
    loc_txt = {
        name = "Chaos Theory",
        text = {
            "At start of round, picks",
            "a random {C:attention}poker hand{}",
            "Gains {X:mult,C:white}X#1#{} Mult if correct,",
            "then switches {C:attention}poker hand{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
        unlock = {
            "Discover every standard",
            "{C:attention}Rare Hand Joker{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        CannedLaughter.add_unique_tooltip(info_queue, {
            key = "canlaugh_card_artist",
            set = "Other",
            vars = { "LumpyTouch" },
        }, card)

        return {
            vars = {
                extra and extra.x_mult_gain or self.config.extra.x_mult_gain,
                extra and extra.x_mult or self.config.extra.x_mult,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return canlaugh_standard_rare_hand_jokers_discovered()
    end,
    locked_loc_vars = function(self, info_queue, card)
        for _, joker_key in ipairs(RARE_HAND_JOKERS) do
            if G and G.P_CENTERS and G.P_CENTERS[joker_key] then
                CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS[joker_key], card)
            end
        end

        return { vars = {} }
    end,
    calculate = function(self, card, context)
        if card and card.ability and card.ability.extra then
            card.ability.extra.x_mult = math.max(card.ability.extra.x_mult or 1, 1)
        end

        if context.setting_blind and not context.blueprint then
            canlaugh_set_chaos_hand(card)
            return
        end

        if context.joker_main then
            local target_hand = card.ability.extra.target_hand

            if canlaugh_context_matches_hand(context, target_hand) then
                if not context.blueprint then
                    card.ability.extra.x_mult = (card.ability.extra.x_mult or 1) + card.ability.extra.x_mult_gain
                    canlaugh_set_chaos_hand(card, target_hand)
                end

                return {
                    x_mult = card.ability.extra.x_mult,
                }
            end
        end
    end,
})
