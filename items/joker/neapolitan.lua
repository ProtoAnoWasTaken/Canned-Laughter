local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_number_value(value)
    if type(value) == "number" then
        return value
    end

    if type(to_number) == "function" then
        local success, number = pcall(to_number, value)
        if success and type(number) == "number" then
            return number
        end
    end

    return 0
end

local function canlaugh_neapolitan_hand_key()
    local round = G and G.GAME and G.GAME.current_round

    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

local function canlaugh_neapolitan_winning_hand()
    local game = G and G.GAME
    local blind = game and game.blind
    if not (game and blind and blind.chips and SMODS and type(SMODS.calculate_round_score) == "function") then
        return false
    end

    local remaining_score = blind.chips - (game.chips or 0)
    return SMODS.calculate_round_score() >= math.max(0, remaining_score)
end

local function canlaugh_neapolitan_current_mult()
    local parameter = SMODS and SMODS.Scoring_Parameters and SMODS.Scoring_Parameters.mult
    return canlaugh_number_value(parameter and parameter.current)
end

local function canlaugh_neapolitan_round_down(value)
    return math.floor(value * 100 + 0.5) / 100
end

local function canlaugh_ice_cream_consumed(card)
    local center = card and card.config and card.config.center
    local extra = card and card.ability and card.ability.extra

    return center
        and center.key == "j_ice_cream"
        and type(extra) == "table"
        and (extra.chips or 0) <= 0
end

SMODS.Atlas({
    key = "neapolitan",
    path = "neapolitan.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "neapolitan",
    name = "Neapolitan",
    atlas = "neapolitan",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    yes_pool_flag = "canlaugh_ice_cream_consumed",
    config = {
        extra = {
            mult = 0,
            store_rate = 0.5,
            decay_rate = 0.05,
            last_stored_hand = nil,
        },
    },
    loc_txt = {
        name = "Neapolitan",
        text = {
            "Store {C:mult}#1#%{} of the last",
            "winning hand's {C:mult}Mult{}",
            "{C:mult}-#2#%{} stored at end",
            "of every round",
            "{C:inactive}(Currently {C:mult}#3#%{C:inactive} stored){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.store_rate * 100,
                extra.decay_rate * 100,
                extra.store_rate * 100,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    pools = {
        Food = true,
    },
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.joker_main and extra.mult > 0 then
            return {
                mult = extra.mult,
            }
        end

        if context.final_scoring_step
            and not context.blueprint
            and not context.retrigger_joker
        then
            local hand_key = canlaugh_neapolitan_hand_key()
            if extra.last_stored_hand ~= hand_key and canlaugh_neapolitan_winning_hand() then
                extra.last_stored_hand = hand_key
                extra.mult = canlaugh_neapolitan_round_down(
                    canlaugh_neapolitan_current_mult() * extra.store_rate
                )
                card:juice_up(0.3, 0.5)
                return {
                    message = "Stored!",
                    colour = G.C.MULT,
                }
            end
        end

        if context.end_of_round
            and not context.individual
            and not context.repetition
            and not context.blueprint
            and extra.store_rate > 0
        then
            extra.store_rate = math.max(0, canlaugh_neapolitan_round_down(extra.store_rate - extra.decay_rate))
            if extra.store_rate <= 0 then
                SMODS.destroy_cards(card, nil, nil, true)
                return {
                    message = localize("k_melted_ex"),
                    colour = G.C.MULT,
                }
            end

            card:juice_up(0.3, 0.5)
            return {
                message = "-" .. tostring(extra.decay_rate * 100) .. "%",
                colour = G.C.MULT,
            }
        end
    end,
})

if SMODS and type(SMODS.destroy_cards) == "function" and not CL.neapolitan_ice_cream_hook_installed then
    CL.neapolitan_ice_cream_hook_installed = true
    local destroy_cards_ref = SMODS.destroy_cards

    function SMODS.destroy_cards(cards, ...)
        local destroyed_cards = cards and cards.config and { cards } or cards

        for _, card in ipairs(destroyed_cards or {}) do
            if canlaugh_ice_cream_consumed(card) and G and G.GAME and G.GAME.pool_flags then
                G.GAME.pool_flags.canlaugh_ice_cream_consumed = true
            end
        end

        return destroy_cards_ref(cards, ...)
    end
end
