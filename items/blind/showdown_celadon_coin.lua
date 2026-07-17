local CL = CannedLaughter
SMODS.Atlas({ key = "showdown_celadon_coin", path = "showdown_celadoncoin.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_showdown_boss({
    key = "celadon_coin",
    atlas = "showdown_celadon_coin",
    boss_colour = HEX("97E171"),
    mult = 1.5,
    loc_txt = { name = "Celadon Coin", text = { "$1 earned this run adds", "200 to the goal" } },
    set_blind = function()
        if type(CL.apply_fortune_goal_bonus) == "function" then
            CL.apply_fortune_goal_bonus("celadon_coin", 2)
        end
    end,
})
