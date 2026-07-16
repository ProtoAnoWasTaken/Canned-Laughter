local CL = CannedLaughter
SMODS.Atlas({ key = "boss_need", path = "blind_need.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "need",
    atlas = "boss_need",
    art = "need",
    boss_colour = HEX("4F2D38"),
    mult = 2,
    loc_txt = { name = "The Need", text = { "Hands must contain your", "full hand size" } },
    set_blind = function(self)
        local extra = math.max(0, CL.boss_hand_size() - 5) * .25
        G.GAME.blind.chips = G.GAME.blind.chips * (1 + extra)
    end,
    debuff_hand = function(self, cards)
        return #(cards or {}) < CL.boss_hand_size()
    end,
})
