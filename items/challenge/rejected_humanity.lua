SMODS.Challenge({
    key = "rejected_humanity",
    loc_txt = {
        name = "Rejected Humanity",
    },
    rules = {
        custom = {
            { id = "canlaugh_rejected_humanity_scaling" },
            { id = "canlaugh_rejected_humanity_boss" },
        },
        modifiers = {},
    },
    jokers = {
        { id = "j_vampire", eternal = true },
        { id = "j_midas_mask", eternal = true },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {},
    },
    apply = function(self)
        G.GAME.modifiers.scaling = 3
    end,
})
