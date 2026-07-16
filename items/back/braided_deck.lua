local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "braided_deck",
    path = "braided_deck.png",
    px = 69,
    py = 93,
})

local function canlaugh_profile()
    if not (G and G.PROFILES and G.SETTINGS) then
        return nil
    end

    return G.PROFILES[G.SETTINGS.profile]
end

local function canlaugh_hand_usage_value(source, hand_key)
    local value = source and source[hand_key]

    if type(value) == "number" then
        return value
    end

    if type(value) == "table" then
        return value.count
            or value.tally
            or value.played
            or value.amount
            or 0
    end

    return 0
end

local function canlaugh_lifetime_hand_plays(hand_key)
    local profile = canlaugh_profile()
    local career_stats = profile and profile.career_stats

    return canlaugh_hand_usage_value(profile and profile.hand_usage, hand_key)
        + canlaugh_hand_usage_value(career_stats and career_stats.hand_usage, hand_key)
        + canlaugh_hand_usage_value(career_stats and career_stats.hands, hand_key)
        + canlaugh_hand_usage_value(career_stats and career_stats.poker_hands, hand_key)
        + canlaugh_hand_usage_value(career_stats, "hand_" .. hand_key)
        + canlaugh_hand_usage_value(career_stats, hand_key)
end

local function canlaugh_most_used_hand_ever()
    local best_hand = "High Card"
    local best_plays = -1

    for _, hand_key in ipairs(G.handlist or {}) do
        local plays = canlaugh_lifetime_hand_plays(hand_key)

        if plays > best_plays then
            best_hand = hand_key
            best_plays = plays
        end
    end

    if best_plays > 0 then
        return best_hand
    end

    for _, hand_key in ipairs(G.handlist or {}) do
        local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_key]
        local plays = hand and hand.played or 0

        if plays > best_plays then
            best_hand = hand_key
            best_plays = plays
        end
    end

    return best_hand
end

local function canlaugh_braided_start_level()
    local stake = G and G.GAME and G.GAME.stake or 1

    if type(stake) ~= "number" then
        stake = 1
    end

    return 3 + math.floor(stake / 2)
end

local function canlaugh_set_hand_level(hand_key, target_level)
    local hand = G and G.GAME and G.GAME.hands and G.GAME.hands[hand_key]

    if not hand then
        return
    end

    local delta = target_level - (hand.level or 1)

    if delta <= 0 then
        return
    end

    if type(level_up_hand) == "function" then
        level_up_hand(nil, hand_key, true, delta)
    else
        hand.level = target_level
    end
end

SMODS.Back({
    key = "braided_deck",
    name = "Braided Deck",
    atlas = "braided_deck",
    pos = { x = 0, y = 0 },
    unlocked = false,
    order = 21,
    config = {},
    loc_txt = {
        name = "Braided Deck",
        text = {
            "Your most used {C:attention}poker hand{}",
            "starts at {C:attention}level 3{}",
            "{C:attention}+1{} level for every {C:attention}2{} stakes",
        },
        unlock = {
            "Discover at least",
            "{C:attention}120{} items from",
            "your {C:attention}Collection{}",
        },
    },
    check_for_unlock = function(self, args)
        return args
            and args.type == "discover_amount"
            and (args.amount or 0) >= 120
    end,
    apply = function(self, back)
        canlaugh_set_hand_level(canlaugh_most_used_hand_ever(), canlaugh_braided_start_level())
    end,
})
