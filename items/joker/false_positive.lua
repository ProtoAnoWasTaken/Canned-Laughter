local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_false_positive_cards()
    local cards = {}

    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center
        if center
            and center.key == "j_canlaugh_false_positive"
            and not joker.debuff
            and not joker.removed
            and not joker.getting_sliced
        then
            cards[#cards + 1] = joker
        end
    end

    return cards
end

local function canlaugh_false_positive_hand_key()
    local round = G and G.GAME and G.GAME.current_round

    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

local function canlaugh_false_positive_is_scoring_hand()
    return G
        and G.STATES
        and G.STATE == G.STATES.HAND_PLAYED
end

local function canlaugh_false_positive_gain(hand_key)
    for _, card in ipairs(canlaugh_false_positive_cards()) do
        local extra = card.ability and card.ability.extra
        if extra and extra.last_capped_hand ~= hand_key then
            extra.last_capped_hand = hand_key
            extra.x_mult = (extra.x_mult or 1) + (extra.x_mult_gain or 0.25)
            card:juice_up(0.3, 0.5)
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "X" .. tostring(extra.x_mult) .. " Mult",
                colour = G.C.MULT,
            })
        end
    end
end

local function canlaugh_false_positive_cap_score(score)
    if not canlaugh_false_positive_is_scoring_hand() then
        return score
    end

    if #canlaugh_false_positive_cards() == 0 then
        return score
    end

    local game = G and G.GAME
    local blind = game and game.blind
    if not (game and blind and blind.chips) then
        return score
    end

    local round = game.current_round
    local hand_key = canlaugh_false_positive_hand_key()
    if round and round.canlaugh_false_positive_capped_hand == hand_key then
        return round.canlaugh_false_positive_cap_score
    end

    local remaining_score = blind.chips - (game.chips or 0)
    if remaining_score < 0 then
        remaining_score = 0
    end

    if score > remaining_score then
        if round then
            round.canlaugh_false_positive_capped_hand = hand_key
            round.canlaugh_false_positive_cap_score = remaining_score
        end

        canlaugh_false_positive_gain(hand_key)

        return remaining_score
    end

    return score
end

local function canlaugh_false_positive_random_rep(card)
    local barter = CL.barter
    local candidates = {}

    for _, rep in ipairs((barter and barter.buffoon_reps) or {}) do
        if G and G.P_CENTERS and G.P_CENTERS[rep.key] then
            candidates[#candidates + 1] = rep
        end
    end

    if #candidates == 0 then
        return nil
    end

    local template = pseudorandom_element(candidates, pseudoseed(
        "canlaugh_false_positive_buffoon_" .. tostring(card and card.sort_id or "")
    ))

    if not template then
        return nil
    end

    return {
        key = template.key,
        set = "Joker",
        kind = "joker",
        rarity = template.rarity,
        output = template.output,
        scaling = template.scaling,
        loc = template.loc,
    }
end

SMODS.Atlas({
    key = "false_positive_back",
    path = "falsepositive_back.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "false_positive_front",
    path = "falsepositive_joker.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "false_positive",
    name = "False Positive",
    atlas = "false_positive_back",
    soul_atlas = "false_positive_front",
    pos = { x = 0, y = 0 },
    soul_pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    config = {
        extra = {
            x_mult = 1,
            x_mult_gain = 0.25,
            last_capped_hand = nil,
        },
    },
    loc_txt = {
        name = "False Positive",
        text = {
            "If a scored hand would",
            "{C:attention}catch fire{}, cap its score and",
            "gain {X:mult,C:white}X#1#{} Mult",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.x_mult_gain,
                extra.x_mult,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.joker_main then
            return {
                x_mult = extra.x_mult,
            }
        end

    end,
})

if SMODS and type(SMODS.calculate_round_score) == "function" and not CL.false_positive_score_hook_installed then
    CL.false_positive_score_hook_installed = true
    local calculate_round_score_ref = SMODS.calculate_round_score

    function SMODS.calculate_round_score(flames)
        local score = calculate_round_score_ref(flames)
        return canlaugh_false_positive_cap_score(score)
    end
end

if CL.barter then
    CL.barter.register_rep_modifier("false_positive", function(phase, context)
        if phase == "availability" and context.booster_kind == "Buffoon" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_false_positive") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Buffoon" then
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_false_positive") or {}) do
                local rep = canlaugh_false_positive_random_rep(joker)
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end
