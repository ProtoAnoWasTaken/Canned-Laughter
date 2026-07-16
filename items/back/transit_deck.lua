SMODS.Atlas({
    key = "transit_deck",
    path = "transit_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "transit_deck",
    name = "Transit Deck",
    atlas = "transit_deck",
    pos = { x = 0, y = 0 },
    unlocked = false,
    order = 20,
    config = {},
    unlock_condition = {
        type = "win_deck",
        deck = "b_plasma",
    },
    loc_txt = {
        name = "Transit Deck",
        text = {
            "{C:chips}Chips{} and {C:mult}Mult{}",
            "are {C:attention}reversed{}",
        },
    },
    calculate = function(self, back, context)
        if context.context == "final_scoring_step" then
            local reversed_chips = context.mult
            local reversed_mult = context.chips

            update_hand_text({ delay = 0 }, {
                chips = reversed_chips,
                mult = reversed_mult,
            })

            G.E_MANAGER:add_event(Event({
                func = function()
                    play_sound("highlight2", 0.685, 0.2)
                    ease_colour(G.C.UI_CHIPS, G.C.ORANGE)
                    ease_colour(G.C.UI_MULT, G.C.ORANGE)
                    attention_text({
                        scale = 1.4,
                        text = "Reversed!",
                        hold = 2,
                        align = "cm",
                        offset = { x = 0, y = -2.7 },
                        major = G.play,
                    })
                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        blockable = false,
                        blocking = false,
                        delay = 4.3,
                        func = function()
                            ease_colour(G.C.UI_CHIPS, G.C.BLUE, 2)
                            ease_colour(G.C.UI_MULT, G.C.RED, 2)
                            return true
                        end,
                    }))
                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        blockable = false,
                        blocking = false,
                        no_delete = true,
                        delay = 6.3,
                        func = function()
                            G.C.UI_CHIPS[1], G.C.UI_CHIPS[2], G.C.UI_CHIPS[3], G.C.UI_CHIPS[4] = G.C.BLUE[1], G.C.BLUE[2], G.C.BLUE[3], G.C.BLUE[4]
                            G.C.UI_MULT[1], G.C.UI_MULT[2], G.C.UI_MULT[3], G.C.UI_MULT[4] = G.C.RED[1], G.C.RED[2], G.C.RED[3], G.C.RED[4]
                            return true
                        end,
                    }))
                    return true
                end,
            }))

            delay(0.6)
            return reversed_chips, reversed_mult
        end
    end,
})
