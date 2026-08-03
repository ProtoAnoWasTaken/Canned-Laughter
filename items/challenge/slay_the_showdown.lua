SMODS.Challenge({
    key = "slay_the_showdown",
    loc_txt = {
        name = "Slay the Showdown",
    },
    rules = {
        custom = {
            { id = "canlaugh_slay_the_showdown_strength" },
        },
        modifiers = {
            { id = "hands", value = 5 },
            { id = "discards", value = 0 },
        },
    },
    jokers = {
        { id = "j_canlaugh_dream_catcher" },
        { id = "j_canlaugh_pantograph" },
        { id = "j_ice_cream" },
        { id = "j_canlaugh_masked_joker" },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
    },
    restrictions = {
        banned_cards = CannedLaughter.challenge_banned_cards({ "j_luchador", "j_chicot" }),
        banned_tags = {},
        banned_other = {},
    },
    apply = function(self)
        G.GAME.banned_keys = G.GAME.banned_keys or {}
        G.GAME.banned_keys.j_luchador = true
        G.GAME.banned_keys.j_chicot = true
    end,
})
