SMODS.Achievement({
    key = "stay_in_character",
    loc_txt = {
        name = "Stay In Character!",
        description = {
            "Have a Confused Joker",
            "mimic Still Life",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_stay_in_character"
    end,
})
