SMODS.Challenge({
    key = "spirited_away",
    loc_txt = {
        name = "Spirited Away",
    },
    rules = {
        custom = {},
        modifiers = {
            { id = "hands", value = 3 },
        },
    },
    jokers = {
        { id = "j_canlaugh_spirit_world", eternal = true, edition = "negative" },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
    },
    restrictions = {
        banned_cards = CannedLaughter.spirited_away_banned_cards(),
        banned_tags = {},
        banned_other = {},
    },
    apply = function(self)
        CannedLaughter.apply_spirited_away_bans()
    end,
})
