local BANNED_CARDS = {
    "c_aura",
    "c_canlaugh_vibe",
    "c_familiar",
    "c_grim",
    "c_incantation",
    "j_canlaugh_death_card",
    "j_canlaugh_antique_ace",
    "j_marble",
    "j_certificate",
}

SMODS.Challenge({
    key = "jens_mod",
    loc_txt = {
        name = "Jen's Mod",
    },
    rules = {
        custom = {
            { id = "canlaugh_jens_mod_barter" },
        },
        modifiers = {},
    },
    jokers = {},
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
        edition = "canlaugh_plastic",
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
        G.GAME.perscribed_bosses = G.GAME.perscribed_bosses or {}
        G.GAME.perscribed_bosses[2] = pseudorandom_element({
            "bl_canlaugh_frozen",
            "bl_tooth",
        }, pseudoseed("canlaugh_jens_mod_ante_2"))
        G.GAME.perscribed_bosses[4] = pseudorandom_element({
            "bl_hook",
            "bl_canlaugh_line",
            "bl_canlaugh_sinker",
        }, pseudoseed("canlaugh_jens_mod_ante_4"))
        G.GAME.perscribed_bosses[6] = "bl_canlaugh_fortune"
        G.GAME.perscribed_bosses[8] = "bl_final_vessel"
    end,
})
