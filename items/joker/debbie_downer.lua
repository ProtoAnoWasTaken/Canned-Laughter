local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "debbie_downer",
    path = "debbie_downer.png",
    px = 69,
    py = 93,
})

local function canlaugh_debbie_number(value)
    local helpers = CL.playing_card_jokers
    if helpers and type(helpers.number_value) == "function" then
        return helpers.number_value(value)
    end

    return type(value) == "number" and value or 0
end

local function canlaugh_debbie_hand_score()
    if SMODS and type(SMODS.calculate_round_score) == "function" then
        return canlaugh_debbie_number(SMODS.calculate_round_score())
    end

    local hand = G and G.GAME and G.GAME.current_round and G.GAME.current_round.current_hand
    if not hand then
        return 0
    end

    return canlaugh_debbie_number(hand.chip_total)
end

local function canlaugh_debbie_required_score()
    local blind = G and G.GAME and G.GAME.blind
    return canlaugh_debbie_number(blind and blind.chips)
end

local function canlaugh_debbie_hand_key()
    local round = G and G.GAME and G.GAME.current_round

    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

SMODS.Joker({
    key = "debbie_downer",
    name = "Debbie Downer",
    atlas = "debbie_downer",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            chips = 0,
            chips_gain = 25,
            last_hand = nil,
        },
    },
    loc_txt = {
        name = "Debbie Downer",
        text = {
            "Gains {C:chips}+#1#{} Chips if a played hand",
            "scores below {C:attention}25%{} of the Blind's requirement",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips; resets at end of Ante){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.chips_gain,
                extra.chips,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.after
            and not context.blueprint
            and not context.retrigger_joker
        then
            local hand_key = canlaugh_debbie_hand_key()
            local required_score = canlaugh_debbie_required_score()
            local hand_score = canlaugh_debbie_hand_score()

            if extra.last_hand ~= hand_key and required_score > 0 and hand_score < required_score * 0.25 then
                extra.last_hand = hand_key
                extra.chips = extra.chips + extra.chips_gain
                return {
                    message = "+" .. tostring(extra.chips_gain) .. " Chips",
                    colour = G.C.CHIPS,
                }
            end
        end

        if context.end_of_round
            and context.beat_boss
            and not context.blueprint
            and not (CL.rules_card_active and CL.rules_card_active())
        then
            extra.chips = 0
            extra.last_hand = nil
        end

        if context.joker_main and extra.chips > 0 then
            return {
                chips = extra.chips,
            }
        end
    end,
})
