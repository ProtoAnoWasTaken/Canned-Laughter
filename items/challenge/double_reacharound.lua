SMODS.Challenge({
    key = "double_reacharound",
    loc_txt = {
        name = "Double Reacharound",
    },
    rules = {
        custom = {
            { id = "canlaugh_double_reacharound_loop" },
        },
        modifiers = {},
    },
    jokers = {
        { id = "j_canlaugh_felt_joker" },
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
        G.GAME.win_ante = 1000
    end,
})
