SMODS.Challenge({
    key = "total_war",
    loc_txt = {
        name = "Total War",
    },
    rules = {
        custom = {},
        modifiers = {
            { id = "hand_size", value = 4 },
            { id = "joker_slots", value = 7 },
            { id = "discards", value = 6 },
        },
    },
    jokers = {
        { id = "j_canlaugh_warlord", eternal = true },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
    },
    restrictions = {
        banned_cards = {
            { id = "j_juggler" },
            { id = "j_troubadour" },
            { id = "j_turtle_bean" },
        },
        banned_tags = {},
        banned_other = {},
    },
})
