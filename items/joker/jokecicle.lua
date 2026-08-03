local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_jokecicle_frozen_cards()
    local count = 0

    for _, playing_card in ipairs(G and G.playing_cards or {}) do
        if not playing_card.removed
            and type(CL.is_frozen) == "function"
            and CL.is_frozen(playing_card)
        then
            count = count + 1
        end
    end

    return count
end

local function canlaugh_jokecicle_chips(extra)
    return canlaugh_jokecicle_frozen_cards() * extra.chips_per_frozen
end

local function canlaugh_jokecicle_odds(extra)
    local mult_steps = math.floor((extra.mult or 0) / extra.power_step)
    local chip_steps = math.floor(canlaugh_jokecicle_chips(extra) / extra.power_step)
    return math.max(1, extra.odds - mult_steps - chip_steps)
end

SMODS.Atlas({
    key = "jokecicle",
    path = "jokecicle.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "jokecicle",
    name = "Jokecicle",
    atlas = "jokecicle",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            mult = 0,
            mult_gain = 5,
            chips_per_frozen = 15,
            odds = 10,
            power_step = 25,
        },
    },
    loc_txt = {
        name = "Jokecicle",
        text = {
            "Gains {C:mult}+#1#{} Mult whenever",
            "the score {C:attention}catches fire{}",
            "{C:chips}+#2#{} Chips per {C:canlaugh_frozen,T:e_canlaugh_frozen}Frozen{} Card",
            "{C:green}#3# in #4#{} chance to expire",
            "at end of round",
            "{C:inactive}(Expiration chance rises with power){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        local odds = canlaugh_jokecicle_odds(extra)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, odds, "canlaugh_jokecicle")

        CL.add_unique_tooltip(info_queue, G.P_CENTERS.e_canlaugh_frozen, card)
        return {
            vars = {
                extra.mult_gain,
                extra.chips_per_frozen,
                numerator,
                denominator,
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

        if context.joker_main then
            return {
                chips = canlaugh_jokecicle_chips(extra),
                mult = extra.mult,
            }
        end

        if context.final_scoring_step and not context.blueprint and not context.retrigger_joker then
            G.E_MANAGER:add_event(Event({
                func = function()
                    local helpers = CL.playing_card_jokers
                    if helpers and helpers.score_caught_fire(G.ARGS and G.ARGS.score_intensity) then
                        extra.mult = extra.mult + extra.mult_gain
                        card_eval_status_text(card, "extra", nil, nil, nil, {
                            message = "+" .. tostring(extra.mult_gain) .. " Mult",
                            colour = G.C.MULT,
                        })
                    end
                    return true
                end,
            }))
        end

        if context.end_of_round
            and not context.individual
            and not context.repetition
            and not context.blueprint
        then
            local odds = canlaugh_jokecicle_odds(extra)
            if SMODS.pseudorandom_probability(card, "canlaugh_jokecicle", 1, odds) then
                SMODS.destroy_cards(card, nil, nil, true)
                return {
                    message = localize("k_extinct_ex"),
                }
            end

            return {
                message = localize("k_safe_ex"),
            }
        end
    end,
})
