local CL = CannedLaughter
SMODS.Atlas({ key = "boss_fortune", path = "blind_fortune.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "fortune",
    atlas = "boss_fortune",
    art = "fortune",
    boss_colour = HEX("EFDF72"),
    mult = 1.5,
    loc_txt = { name = "The Fortune", text = { "$1 earned this run adds", "100 to the goal" } },
    set_blind = function()
        if type(CL.apply_fortune_goal_bonus) == "function" then
            CL.apply_fortune_goal_bonus("fortune", 1)
        end
    end,
})
