SMODS.Atlas({
    key = "joker_mold",
    path = "joker_mold.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "joker_mold",
    name = "Joker Mold",
    atlas = "joker_mold",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Joker Mold",
        text = {
            "If the score {C:attention}catches fire{},",
            "give one random playing card",
            "in the last hand {C:canlaugh_plastic,T:e_canlaugh_plastic}Plastic{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        if G and G.P_CENTERS and G.P_CENTERS.e_canlaugh_plastic then
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.e_canlaugh_plastic, card)
        end
        return { vars = {} }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.final_scoring_step and not context.blueprint and not context.retrigger_joker then
            G.E_MANAGER:add_event(Event({
                func = function()
                    local PCJ = CannedLaughter.playing_card_jokers
                    local JPE = CannedLaughter.joker_plastic_edition
                    if PCJ.score_caught_fire(G.ARGS and G.ARGS.score_intensity) then
                        local target = PCJ.random_last_hand_card()
                        if target and JPE then
                            JPE.apply_after(target, card)
                        end
                    end
                    return true
                end,
            }))
        end
    end,
})
