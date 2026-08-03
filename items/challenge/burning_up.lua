local BANNED_CARDS = {
    "c_magician",
    "c_empress",
    "c_hierophant",
    "c_lovers",
    "c_chariot",
    "c_justice",
    "c_devil",
    "c_tower",
    "c_familiar",
    "c_grim",
    "c_incantation",
    "j_blackboard",
    "j_canlaugh_alchemist",
    "j_canlaugh_blackcollar",
    "j_canlaugh_death_card",
    "j_canlaugh_antique_ace",
    "j_marble",
    "j_certificate",
}

SMODS.Challenge({
    key = "burning_up",
    loc_txt = {
        name = "Burning Up",
    },
    rules = {
        custom = {
            { id = "canlaugh_burning_up_catalyze" },
        },
        modifiers = {},
    },
    jokers = {
        { id = "j_burnt", eternal = true },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
        enhancement = "m_canlaugh_blazing",
    },
    restrictions = {
        banned_cards = CannedLaughter.challenge_banned_cards(BANNED_CARDS),
        banned_tags = {},
        banned_other = {},
    },
    apply = function(self)
        G.GAME.banned_keys = G.GAME.banned_keys or {}
        for _, key in ipairs(BANNED_CARDS) do
            G.GAME.banned_keys[key] = true
        end
    end,
})
