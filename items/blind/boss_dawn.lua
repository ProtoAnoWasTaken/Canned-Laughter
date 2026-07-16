local CL = CannedLaughter
SMODS.Atlas({ key = "boss_dawn", path = "blind_dawn.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "dawn",
    atlas = "boss_dawn",
    boss_colour = HEX("D37119"),
    mult = 2,
    loc_txt = { name = "The Dawn", text = { "Chips and Mult", "are reversed" } },
    modify_hand = function(self, cards, poker_hands, handname, mult, chips)
        return chips, mult, true
    end,
})
