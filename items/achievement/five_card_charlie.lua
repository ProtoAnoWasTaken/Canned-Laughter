SMODS.Achievement({
    key = "five_card_charlie",
    loc_txt = {
        name = "Five-Card Charlie",
        description = {
            "Fill a hand and trigger",
            "the Knave",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_five_card_charlie"
    end,
})
