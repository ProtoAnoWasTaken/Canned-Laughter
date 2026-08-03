SMODS.Achievement({
    key = "already_here",
    loc_txt = {
        name = "Already Here",
        description = {
            "Return to the past with",
            "the Felt Joker",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_already_here"
    end,
})
