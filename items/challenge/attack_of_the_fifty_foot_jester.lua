local CL = CannedLaughter

SMODS.Challenge({
    key = "attack_of_the_fifty_foot_jester",
    loc_txt = {
        name = "Attack of the Fifty-Foot Jester!!",
    },
    rules = {
        custom = {
            { id = "canlaugh_attack_start" },
            { id = "canlaugh_attack_scaling" },
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
        G.GAME.round_resets.ante = 0
        G.GAME.round_resets.blind_ante = 0
        G.GAME.modifiers.scaling = 3
        G.GAME.win_ante = 8
        G.GAME.perscribed_bosses = G.GAME.perscribed_bosses or {}
        G.GAME.perscribed_bosses[8] = "bl_canlaugh_earthsea_borealis"
        CL.force_challenge_boss(get_new_boss())
    end,
})
