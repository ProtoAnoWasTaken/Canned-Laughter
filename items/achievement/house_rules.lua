SMODS.Achievement({
    key = "house_rules",
    loc_txt = {
        name = "House Rules",
        description = {
            "Change the rules of",
            "a game cherished by time",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_house_rules"
    end,
})
