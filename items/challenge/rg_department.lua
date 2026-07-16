SMODS.Challenge({
    key = "rg_department",
    loc_txt = {
        name = "R&G Department",
    },
    rules = {
        custom = {
            { id = "canlaugh_rg_department_win_condition" },
        },
        modifiers = {},
    },
    jokers = {
        { id = "j_canlaugh_resourceful_joker", eternal = true },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
    },
    restrictions = {
        banned_cards = {
            { id = "v_hieroglyph" },
        },
        banned_tags = {},
        banned_other = {},
    },
})
