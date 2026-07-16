SMODS.Challenge({
    key = "glitter_glue",
    loc_txt = {
        name = "Glitter Glue",
    },
    rules = {
        custom = {
            { id = "canlaugh_glitter_glue_start" },
            { id = "canlaugh_glitter_glue_boosters" },
        },
        modifiers = {},
    },
    jokers = {},
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
        edition = "canlaugh_glitter",
    },
    restrictions = {
        banned_cards = {
            { id = "c_aura" },
            { id = "c_canlaugh_daguerreotype" },
            { id = "c_canlaugh_vibe" },
            { id = "j_canlaugh_antique_ace" },
            { id = "j_canlaugh_oil_chamber" },
        },
        banned_tags = {},
        banned_other = {},
    },
})
