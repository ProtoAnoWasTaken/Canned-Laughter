local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_serpent_hand_key()
    local round = G and G.GAME and G.GAME.current_round
    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

local function canlaugh_serpent_hand_result(cards)
    local poker_hands = evaluate_poker_hand(cards)
    for priority, hand_name in ipairs(G.handlist or {}) do
        if poker_hands[hand_name] and next(poker_hands[hand_name]) then
            return priority, hand_name
        end
    end

    return math.huge, "High Card"
end

local function canlaugh_serpent_non_club_values(cards)
    local ranks = {}
    local suits = {}

    for _, playing_card in ipairs(cards or {}) do
        if not playing_card:is_suit("Clubs") then
            ranks[playing_card.base.value] = true
            suits[playing_card.base.suit] = true
        end
    end

    return ranks, suits
end

local function canlaugh_serpent_candidate_hand(cards, target, suit, rank)
    local base = target.base
    local rank_data = SMODS.Ranks[rank]
    local suit_data = SMODS.Suits[suit]
    if not (base and rank_data and suit_data) then
        return math.huge, "High Card"
    end

    local candidate_base = {}
    for key, value in pairs(base) do
        candidate_base[key] = value
    end

    candidate_base.suit = suit
    candidate_base.value = rank
    candidate_base.id = rank_data.id
    candidate_base.nominal = rank_data.nominal or 0
    candidate_base.face_nominal = rank_data.face_nominal or 0
    candidate_base.suit_nominal = suit_data.suit_nominal or 0
    candidate_base.suit_nominal_original = suit_data.suit_nominal or 0

    target.base = candidate_base
    local results = { pcall(canlaugh_serpent_hand_result, cards) }
    target.base = base

    if not results[1] then
        return math.huge, "High Card"
    end

    return results[2], results[3]
end

local function canlaugh_serpent_candidates(cards)
    local ranks, suits = canlaugh_serpent_non_club_values(cards)
    local candidates = {}
    local seen = {}

    for _, target in ipairs(cards or {}) do
        if target:is_suit("Clubs") then
            for rank in pairs(ranks) do
                if rank ~= target.base.value then
                    local priority, hand_name = canlaugh_serpent_candidate_hand(cards, target, target.base.suit, rank)
                    local key = tostring(target.sort_id or target.unique_val or target) .. ":rank:" .. tostring(rank)
                    if hand_name ~= "High Card" and not seen[key] then
                        seen[key] = true
                        candidates[#candidates + 1] = {
                            card = target,
                            suit = target.base.suit,
                            rank = rank,
                            priority = priority,
                        }
                    end
                end
            end

            for suit in pairs(suits) do
                if suit ~= target.base.suit then
                    local priority, hand_name = canlaugh_serpent_candidate_hand(cards, target, suit, target.base.value)
                    local key = tostring(target.sort_id or target.unique_val or target) .. ":suit:" .. tostring(suit)
                    if hand_name ~= "High Card" and not seen[key] then
                        seen[key] = true
                        candidates[#candidates + 1] = {
                            card = target,
                            suit = suit,
                            rank = target.base.value,
                            priority = priority,
                        }
                    end
                end
            end
        end
    end

    return candidates
end

local function canlaugh_serpent_staves()
    local staves = {}

    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center
        if center
            and center.key == "j_canlaugh_serpent_stave"
            and not joker.debuff
            and not joker.removed
            and not joker.getting_sliced
        then
            staves[#staves + 1] = joker
        end
    end

    return staves
end

local function canlaugh_serpent_prepare_play(card, cards)
    local extra = card.ability and card.ability.extra
    local hand_key = canlaugh_serpent_hand_key()
    if not (extra and cards and #cards > 0) or extra.last_hand == hand_key then
        return
    end

    extra.last_hand = hand_key
    local old_priority = canlaugh_serpent_hand_result(cards)
    local candidates = canlaugh_serpent_candidates(cards)
    local candidate = pseudorandom_element(candidates, pseudoseed("canlaugh_serpent_stave_" .. hand_key))

    if candidate and SMODS.change_base(candidate.card, candidate.suit, candidate.rank, true) then
        candidate.card:juice_up(0.3, 0.5)
        if candidate.priority < old_priority then
            extra.mult = extra.mult + extra.mult_gain
            card:juice_up(0.3, 0.5)
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "+" .. tostring(extra.mult_gain) .. " Mult",
                colour = G.C.MULT,
            })
        else
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = "Changed!",
                colour = G.C.CLUBS,
            })
        end
    end
end

if CL.register_suit_showdown_unlock then
    CL.register_suit_showdown_unlock(
        "j_canlaugh_serpent_stave",
        "bl_canlaugh_cinnabar_saber",
        "Clubs",
        "canlaugh_serpent_stave"
    )
end

if CL.barter then
    CL.barter.register_rep_modifier("serpent_stave", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_serpent_stave") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Arcana" then
            local center = G.P_CENTERS and G.P_CENTERS.c_moon
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_serpent_stave") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Arcana")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "serpent_stave",
    path = "serpent_stave.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "serpent_stave",
    name = "Serpent Stave",
    atlas = "serpent_stave",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            mult = 0,
            mult_gain = 4,
            last_hand = nil,
        },
    },
    loc_txt = {
        name = "Serpent Stave",
        text = {
            "Before scoring, {C:clubs}Club{} cards may change",
            "to a feasible rank or suit",
            "Gains {C:mult}+#1#{} Mult if the new",
            "poker hand is stronger",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
        unlock = {
            "Defeat the {C:attention}Cinnabar Saber{}",
            "with only scored {C:clubs}Clubs{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.mult_gain,
                extra.mult,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_serpent_stave"
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.joker_main and extra.mult > 0 then
            return {
                mult = extra.mult,
            }
        end
    end,
})

if G and G.FUNCS and type(G.FUNCS.evaluate_play) == "function" and not CL.serpent_stave_evaluate_hook_installed then
    CL.serpent_stave_evaluate_hook_installed = true
    local evaluate_play_ref = G.FUNCS.evaluate_play

    G.FUNCS.evaluate_play = function(...)
        if not CL.serpent_stave_preparing_play then
            CL.serpent_stave_preparing_play = true
            local results = { pcall(function()
                for _, stave in ipairs(canlaugh_serpent_staves()) do
                    canlaugh_serpent_prepare_play(stave, G and G.play and G.play.cards)
                end
            end) }
            CL.serpent_stave_preparing_play = nil

            if not results[1] then
                error(results[2])
            end
        end

        return evaluate_play_ref(...)
    end
end
