local BANNED_CARDS = {
    "c_magician",
    "c_empress",
    "c_hierophant",
    "c_lovers",
    "c_justice",
    "c_devil",
    "c_tower",
    "c_canlaugh_spend_a_lifetime",
    "c_familiar",
    "c_grim",
    "c_incantation",
    "j_blackboard",
    "j_canlaugh_alchemist",
    "j_canlaugh_blackcollar",
    "j_canlaugh_death_card",
    "j_canlaugh_antique_ace",
    "j_canlaugh_fire_striker",
    "j_vampire",
    "j_marble",
    "j_certificate",
}

SMODS.Challenge({
    key = "shiny_metal_joker",
    loc_txt = {
        name = "Shiny Metal Joker",
    },
    rules = {
        custom = {},
        modifiers = {},
    },
    jokers = {
        { id = "j_canlaugh_power_armor", eternal = true },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
        enhancement = "m_steel",
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
