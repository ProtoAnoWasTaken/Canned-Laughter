local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "marshmallows",
    path = "marshmallows.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "marshmallows",
    name = "Marshmallows",
    atlas = "marshmallows",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            x_mult = 1,
            x_mult_gain = 0.25,
            burn_x_mult = 4,
        },
    },
    loc_txt = {
        name = "Marshmallows",
        text = {
            "Gain {X:mult,C:white}X#2#{} Mult whenever",
            "the score {C:attention}catches fire{}",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult){}",
            "Burns up at {X:mult,C:white}X#3#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.x_mult,
                extra.x_mult_gain,
                extra.burn_x_mult,
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
                x_mult = extra.x_mult,
            }
        end

        if context.final_scoring_step and not context.blueprint and not context.retrigger_joker then
            G.E_MANAGER:add_event(Event({
                func = function()
                    local helpers = CL.playing_card_jokers
                    if not (helpers and helpers.score_caught_fire(G.ARGS and G.ARGS.score_intensity)) then
                        return true
                    end

                    extra.x_mult = extra.x_mult + extra.x_mult_gain
                    if extra.x_mult >= extra.burn_x_mult then
                        SMODS.destroy_cards(card, nil, nil, true)
                        return true
                    end

                    card_eval_status_text(card, "extra", nil, nil, nil, {
                        message = "X" .. tostring(extra.x_mult) .. " Mult",
                        colour = G.C.MULT,
                    })
                    return true
                end,
            }))
        end
    end,
})
