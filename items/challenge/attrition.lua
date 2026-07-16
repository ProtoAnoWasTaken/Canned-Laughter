SMODS.Challenge({
    key = "attrition",
    loc_txt = {
        name = "Attrition",
    },
    rules = {
        custom = {
            { id = "canlaugh_attrition_after_ante_four" },
            { id = "canlaugh_attrition_big_boss" },
            { id = "canlaugh_attrition_boss_showdown" },
        },
        modifiers = {},
    },
    jokers = {},
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
        CannedLaughter.set_attrition_blind_choices()
    end,
})
