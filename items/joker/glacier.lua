local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_glacier_cards()
    local cards = {}

    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center
        if center
            and center.key == "j_canlaugh_glacier"
            and not joker.debuff
            and not joker.removed
            and not joker.getting_sliced
        then
            cards[#cards + 1] = joker
        end
    end

    return cards
end

local function canlaugh_glacier_hand_key()
    local round = G and G.GAME and G.GAME.current_round

    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

local function canlaugh_glacier_is_scoring_hand()
    return G
        and G.STATES
        and G.STATE == G.STATES.HAND_PLAYED
end

local function canlaugh_glacier_scored_chips(flames)
    local chips = SMODS.get_scoring_parameter("chips", flames)
    local hand_key = canlaugh_glacier_hand_key()

    for _, card in ipairs(canlaugh_glacier_cards()) do
        local extra = card.ability and card.ability.extra
        if extra and extra.played_hand == hand_key then
            chips = chips - (extra.chips or 0)
        end
    end

    if chips < 0 then
        return 0
    end

    return chips
end

local function canlaugh_glacier_cap_score(score, flames)
    if not canlaugh_glacier_is_scoring_hand() then
        return score
    end

    if #canlaugh_glacier_cards() == 0 then
        return score
    end

    local game = G and G.GAME
    local blind = game and game.blind
    if not (game and blind and blind.chips) then
        return score
    end

    local round = game.current_round
    local hand_key = canlaugh_glacier_hand_key()
    if round and round.canlaugh_glacier_capped_hand == hand_key then
        return round.canlaugh_glacier_capped_score
    end

    local remaining_score = blind.chips - (game.chips or 0)
    if remaining_score < 0 then
        remaining_score = 0
    end

    if score > remaining_score then
        local capped_score = math.floor(score / 2)
        local chips_gain = math.floor(canlaugh_glacier_scored_chips(flames) / 2)

        if round then
            round.canlaugh_glacier_capped_hand = hand_key
            round.canlaugh_glacier_capped_score = capped_score
        end

        for _, card in ipairs(canlaugh_glacier_cards()) do
            local extra = card.ability and card.ability.extra
            if extra then
                extra.chips = chips_gain
                extra.stored_hand = hand_key
                card:juice_up(0.3, 0.5)
                card_eval_status_text(card, "extra", nil, nil, nil, {
                    message = "+" .. tostring(chips_gain) .. " Chips",
                    colour = G.C.CHIPS,
                })
            end
        end

        return capped_score
    end

    return score
end

SMODS.Atlas({
    key = "glacier",
    path = "glacier.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "glacier",
    name = "Glacier",
    atlas = "glacier",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 5,
    config = {
        extra = {
            chips = 0,
            played_hand = nil,
            stored_hand = nil,
        },
    },
    loc_txt = {
        name = "Glacier",
        text = {
            "If the score would {C:attention}catch fire{},",
            "cap it at {C:attention}50%{} and store",
            "{C:attention}50%{} of scored {C:chips}Chips{}",
            "for the next played hand",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                extra.chips,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        local hand_key = canlaugh_glacier_hand_key()

        if context.joker_main and extra.chips > 0 then
            extra.played_hand = hand_key
            return {
                chips = extra.chips,
            }
        end

        if context.after and (extra.played_hand == hand_key or extra.stored_hand == hand_key) then
            if extra.played_hand == hand_key and extra.stored_hand ~= hand_key then
                extra.chips = 0
            end

            extra.played_hand = nil
            extra.stored_hand = nil
        end
    end,
})

if SMODS and type(SMODS.calculate_round_score) == "function" and not CL.glacier_score_hook_installed then
    CL.glacier_score_hook_installed = true
    local calculate_round_score_ref = SMODS.calculate_round_score

    function SMODS.calculate_round_score(flames)
        local score = calculate_round_score_ref(flames)
        return canlaugh_glacier_cap_score(score, flames)
    end
end
