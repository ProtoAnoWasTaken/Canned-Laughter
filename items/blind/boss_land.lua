local CL = CannedLaughter
SMODS.Atlas({ key = "boss_land", path = "blind_land.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "land",
    atlas = "boss_land",
    boss_colour = HEX("4577A0"),
    mult = 2,
    loc_txt = { name = "The Land", text = { "All cards debuffed until", "2 discards used" } },
    recalc_debuff = function(self, card)
        return card and card.playing_card and G.GAME.current_round.discards_used < 2
    end,
    drawn_to_hand = function(self)
        if G.GAME.current_round.discards_used < 2 then return end
        for _, card in ipairs(G.playing_cards) do
            G.GAME.blind:debuff_card(card)
        end
    end,
})
