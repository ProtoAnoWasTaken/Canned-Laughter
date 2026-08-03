SMODS.Achievement({
    key = "photo_finish",
    loc_txt = {
        name = "Photo Finish",
        description = {
            "PLACE YOUR BETS",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_photo_finish"
    end,
})
