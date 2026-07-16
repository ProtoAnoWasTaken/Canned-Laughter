local CL = CannedLaughter
SMODS.Atlas({ key = "boss_torch", path = "blind_torch.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "torch",
    atlas = "boss_torch",
    art = "torch",
    boss_colour = HEX("DF9256"),
    mult = 2,
    loc_txt = { name = "The Torch", text = { "All number cards are", "drawn face down" } },
    stay_flipped = function(self, area, card)
        local id = card and card.get_id and card:get_id()
        return area == G.hand and id and id >= 2 and id <= 10
    end,
})
