local CL = CannedLaughter
SMODS.Atlas({ key = "boss_revel", path = "blind_revel.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "revel",
    atlas = "boss_revel",
    art = "revel",
    boss_colour = HEX("E089CB"),
    mult = 2.5,
    loc_txt = { name = "The Revel", text = { "Must play #1#" } },
    loc_vars = function(self)
        local hand = G and G.GAME and G.GAME.current_round and G.GAME.current_round.most_played_poker_hand
            or CL.boss_most_played(G and G.GAME and G.GAME.hands)
            or "High Card"
        return { vars = { localize(hand, "poker_hands") } }
    end,
    collection_loc_vars = function(self)
        return { vars = { "your most frequent poker hand this run" } }
    end,
    debuff_hand = function(self, cards, hand, handname)
        local required = G and G.GAME and G.GAME.current_round and G.GAME.current_round.most_played_poker_hand
            or CL.boss_most_played(G and G.GAME and G.GAME.hands)
        local played = G.FUNCS.get_poker_hand_info(cards)
        return required and played ~= required
    end,
})
