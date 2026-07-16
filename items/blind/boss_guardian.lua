local CL = CannedLaughter
SMODS.Atlas({ key = "boss_guardian", path = "blind_guardian.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "guardian",
    atlas = "boss_guardian",
    art = "guardian",
    boss_colour = HEX("CCCCA0"),
    mult = 2,
    loc_txt = { name = "The Guardian", text = { "Played hands must contain", "at least 1 face card" } },
    debuff_hand = function(self, cards)
        for _, card in ipairs(cards or {}) do
            if card.is_face and card:is_face() then return false end
        end
        return true
    end,
})
