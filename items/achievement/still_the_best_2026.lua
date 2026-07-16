SMODS.Achievement({
    key = "still_the_best_2026",
    loc_txt = {
        name = "STILL THE BEST 2026",
        description = {
            "Conquer the Earthsea Borealis",
        },
    },
    unlock_condition = function(self, args)
        return args
            and (
                args.type == "canlaugh_earthsea_borealis_defeated"
                or args.type == "canlaugh_author_avatar_added"
            )
    end,
})
