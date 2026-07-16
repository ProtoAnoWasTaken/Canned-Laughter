SMODS.Challenge({
    key = "scorched_earth",
    loc_txt = {
        name = "Scorched Earth",
    },
    rules = {
        custom = {},
        modifiers = {
            { id = "joker_slots", value = 4 },
        },
    },
    jokers = {
        { id = "j_canlaugh_pack_rat", eternal = true },
        { id = "j_canlaugh_goldbeard", eternal = true },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
    },
    restrictions = {
        banned_cards = {
            { id = "j_canlaugh_mad_groove" },
        },
        banned_tags = {},
        banned_other = {},
    },
})
