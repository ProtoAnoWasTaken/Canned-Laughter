local CL = CannedLaughter
SMODS.Atlas({ key = "showdown_celadon_coin", path = "showdown_celadoncoin.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_showdown_boss({
    key = "celadon_coin",
    atlas = "showdown_celadon_coin",
    boss_colour = HEX("97E171"),
    mult = 1.5,
    loc_txt = { name = "Celadon Coin", text = { "Money gained this run adds twice", "to score" } },
    calculate = function(self, blind, context)
        if context and context.before and type(CL.apply_fortune_score_bonus) == "function" then
            CL.apply_fortune_score_bonus(2)
        end
    end,
})
