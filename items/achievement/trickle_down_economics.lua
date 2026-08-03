SMODS.Achievement({
    key = "trickle_down_economics",
    loc_txt = {
        name = "Trickle-Down Economics",
        description = {
            "Survey says all CEOs do this",
            "to their employees",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_trickle_down_economics"
    end,
})
