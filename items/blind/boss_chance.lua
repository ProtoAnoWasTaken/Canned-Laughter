local CL = CannedLaughter
SMODS.Atlas({ key = "boss_chance", path = "blind_chance.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "chance",
    atlas = "boss_chance",
    art = "chance",
    boss_colour = HEX("1A8DB0"),
    mult = 2,
    loc_txt = { name = "The Chance", text = { "Cards with random effects", "are debuffed" } },
    recalc_debuff = function(self, card)
        return CL.card_has_probability_effect and CL.card_has_probability_effect(card)
    end,
})
