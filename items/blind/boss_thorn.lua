local CL = CannedLaughter
SMODS.Atlas({ key = "boss_thorn", path = "blind_thorn.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "thorn",
    atlas = "boss_thorn",
    art = "thorn",
    boss_colour = HEX("E9A2CB"),
    mult = 2,
    loc_txt = { name = "The Thorn", text = { "No base Chips" } },
    modify_hand = function(self, cards, poker_hands, text, mult)
        return mult, 0, true
    end,
})
