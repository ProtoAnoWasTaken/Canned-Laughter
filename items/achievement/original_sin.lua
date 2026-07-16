SMODS.Achievement({
    key = "original_sin",
    loc_txt = {
        name = "Original Sin",
        description = {
            "Fudge out on Joker slots",
            "with Invisible Joker",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_invisible_joker_over_limit"
    end,
})
