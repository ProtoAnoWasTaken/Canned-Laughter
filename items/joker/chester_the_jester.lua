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

local function canlaugh_chester_hand_key()
    local round = G and G.GAME and G.GAME.current_round

    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

local function canlaugh_chester_choose(card)
    local extra = card.ability.extra
    local candidates = {}
    local fallback_candidates = {}
    local seen = {}

    for _, playing_card in ipairs((G and G.playing_cards) or {}) do
        local base = playing_card and playing_card.base
        local rank = base and base.id
        local suit = base and base.suit
        local key = tostring(rank or "") .. ":" .. tostring(suit or "")

        if not playing_card.removed
            and not playing_card.destroyed
            and RANK_LABELS[rank]
            and suit
            and not seen[key]
        then
            seen[key] = true
            local target = {
                rank = rank,
                rank_label = RANK_LABELS[rank],
                suit = suit,
            }

            fallback_candidates[#fallback_candidates + 1] = target
            if rank ~= extra.rank or suit ~= extra.suit then
                candidates[#candidates + 1] = target
            end
        end
    end

    if #candidates == 0 then
        candidates = fallback_candidates
    end

    if #candidates == 0 then
        return
    end

    local target = pseudorandom_element(candidates, pseudoseed(table.concat({
        "canlaugh_chester",
        tostring(card.sort_id or ""),
        tostring(G and G.GAME and G.GAME.round or ""),
    }, "_")))

    extra.rank = target.rank
    extra.rank_label = target.rank_label
    extra.suit = target.suit
end

local function canlaugh_chester_unplayed_targets(card)
    local extra = card.ability.extra
    local count = 0

    for _, playing_card in ipairs((G and G.hand and G.hand.cards) or {}) do
        if playing_card:is_suit(extra.suit) and playing_card:get_id() == extra.rank then
            count = count + 1
        end
    end

    return count
end

SMODS.Atlas({
    key = "chester_the_jester",
    path = "chester_the_jester.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "chester_the_jester",
    name = "Chester the Jester",
    atlas = "chester_the_jester",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            x_mult = 1,
            x_mult_gain = 0.1,
            rank = 8,
            rank_label = "8",
            suit = "Spades",
            last_hand = nil,
        },
    },
    loc_txt = {
        name = "Chester the Jester",
        text = {
            "Gains {X:mult,C:white}X#1#{} Mult for each",
            "{C:attention}#2# of #3#{} left unplayed",
            "in your hand",
            "{C:inactive}(Changes every round; currently {X:mult,C:white}X#4#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.x_mult_gain,
                extra.rank_label,
                extra.suit,
                extra.x_mult,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.setting_blind and not context.blueprint then
            canlaugh_chester_choose(card)
            extra.last_hand = nil
        end

        if context.before and not context.blueprint then
            local hand_key = canlaugh_chester_hand_key()
            local unplayed_targets = canlaugh_chester_unplayed_targets(card)
            if unplayed_targets > 0 and extra.last_hand ~= hand_key then
                local gain = unplayed_targets * extra.x_mult_gain
                extra.last_hand = hand_key
                extra.x_mult = extra.x_mult + gain
                card:juice_up(0.3, 0.5)
                return {
                    message = "X" .. tostring(gain) .. " Mult",
                    colour = G.C.MULT,
                }
            end
        end

        if context.joker_main then
            return {
                x_mult = extra.x_mult,
            }
        end
    end,
})
