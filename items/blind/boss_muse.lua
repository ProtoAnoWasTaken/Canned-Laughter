local CL = CannedLaughter
SMODS.Atlas({ key = "boss_muse", path = "blind_muse.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "muse",
    atlas = "boss_muse",
    boss_colour = HEX("684228"),
    mult = 2,
    loc_txt = { name = "The Muse", text = { "Poker hands you haven't", "played do not score" } },
    debuff_hand = function(self, cards, hand, handname)
        local triggered = (G.GAME.hands[handname].played or 0) == 0
        if G and G.GAME and G.GAME.blind then G.GAME.blind.triggered = triggered end
        return triggered
    end,
})
