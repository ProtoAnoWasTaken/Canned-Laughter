local CL = CannedLaughter
SMODS.Atlas({ key = "boss_steel", path = "blind_steel.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "steel",
    atlas = "boss_steel",
    art = "steel",
    boss_colour = HEX("1A95D0"),
    mult = 2,
    loc_txt = { name = "The Steel", text = { "Poker hands use their", "first-level Chips and Mult" } },
    modify_hand = function(self, cards, poker_hands, text, mult, chips)
        local handname = next(poker_hands or {})
        local hand = handname and G.GAME.hands[handname]
        if not hand then return mult, chips, false end
        return hand.s_mult + hand.l_mult, hand.s_chips + hand.l_chips, true
    end,
})
